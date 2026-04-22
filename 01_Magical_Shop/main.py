from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Iterable, Sequence
from urllib.parse import quote_plus

import numpy as np
from dotenv import load_dotenv
from sqlalchemy import (
    DateTime,
    Integer,
    MetaData,
    Numeric,
    String,
    Table,
    Column,
    create_engine,
    text,
)
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class DBSettings:
    user: str
    password: str
    host: str
    port: int
    name: str


def _require_env(name: str) -> str:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        raise ValueError(f"Missing required environment variable: {name}")
    return value.strip()


def load_db_settings() -> DBSettings:
    load_dotenv(override=False)

    user = _require_env("DB_USER")
    password = _require_env("DB_PASSWORD")
    host = _require_env("DB_HOST")
    port_raw = _require_env("DB_PORT")
    name = _require_env("DB_NAME")

    try:
        port = int(port_raw)
    except ValueError as e:
        raise ValueError("DB_PORT must be an integer") from e

    return DBSettings(user=user, password=password, host=host, port=port, name=name)


def build_engine(settings: DBSettings) -> Engine:
    # Quote credentials to safely allow special characters.
    user = quote_plus(settings.user)
    password = quote_plus(settings.password)
    host = settings.host
    port = settings.port
    dbname = settings.name

    url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{dbname}"
    return create_engine(url, pool_pre_ping=True, future=True)


def define_table(metadata: MetaData) -> Table:
    return Table(
        "magical_shop_purchase_prices",
        metadata,
        Column("id", Integer, primary_key=True, autoincrement=True),
        Column("occupation", String(100), nullable=False, index=True),
        Column("purchase_price", Numeric(12, 2), nullable=False),
        Column(
            "created_at",
            DateTime(timezone=True),
            nullable=False,
            server_default=text("now()"),
        ),
    )


def ensure_table(engine: Engine, table: Table) -> None:
    table.metadata.create_all(engine, tables=[table])


def generate_purchase_prices(
    occupations: Sequence[str],
    rows_per_occupation: int,
    *,
    seed: int = 42,
) -> list[dict[str, object]]:
    if rows_per_occupation <= 0:
        raise ValueError("rows_per_occupation must be > 0")
    if not occupations:
        raise ValueError("occupations must not be empty")

    rng = np.random.default_rng(seed)
    now = datetime.now(timezone.utc)

    # Occupation-specific base prices (fictional).
    base_by_occupation: dict[str, float] = {
        "勇者": 1200.0,
        "魔法使い": 1800.0,
        "僧侶": 1100.0,
        "盗賊": 900.0,
        "鍛冶屋": 1600.0,
        "錬金術師": 2200.0,
        "商人": 1400.0,
        "吟遊詩人": 1000.0,
        "めたもん": 4500.0,
    }

    records: list[dict[str, object]] = []
    for occ in occupations:
        base = base_by_occupation.get(occ, 1300.0)
        # Target: std dev ≈ 15% of the base value.
        target_sd = max(1.0, base * 0.15)

        # "めたもん" only: use a normal distribution with fixed parameters
        # and clip to avoid too many outliers.
        if occ == "めたもん":
            mean = 5000.0
            sd = 750.0
            prices = rng.normal(loc=mean, scale=sd, size=rows_per_occupation)
            prices = np.clip(prices, mean - 3.0 * sd, mean + 3.0 * sd)
        else:
            noise = rng.normal(loc=0.0, scale=target_sd, size=rows_per_occupation)
            prices = base + noise

        # Keep minimum at 1 to avoid non-positive prices.
        prices = np.maximum(1.0, prices)
        for p in prices:
            records.append(
                {
                    "occupation": occ,
                    "purchase_price": round(float(p), 2),
                    # created_at is server_default, but we keep a client timestamp available for future use.
                    "created_at": now,
                }
            )
    return records


def insert_records(engine: Engine, table: Table, records: Iterable[dict[str, object]]) -> int:
    rows = list(records)
    if not rows:
        return 0

    with engine.begin() as conn:
        result = conn.execute(table.insert(), rows)
        # SQLAlchemy can return None depending on driver; normalize.
        return int(result.rowcount or 0)


def main() -> int:
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )

    try:
        settings = load_db_settings()
        engine = build_engine(settings)

        metadata = MetaData()
        table = define_table(metadata)
        ensure_table(engine, table)

        occupations = [
            "勇者",
            "魔法使い",
            "僧侶",
            "盗賊",
            "鍛冶屋",
            "錬金術師",
            "商人",
            "吟遊詩人",
            "めたもん",
        ]
        rows_per_occupation = int(os.getenv("ROWS_PER_OCCUPATION", "100"))

        logger.info("Generating data (occupations=%d, rows_per_occupation=%d)", len(occupations), rows_per_occupation)
        records = generate_purchase_prices(occupations, rows_per_occupation, seed=42)

        inserted = insert_records(engine, table, records)
        logger.info("Inserted %d rows into %s", inserted, table.name)
        return 0
    except (ValueError, SQLAlchemyError) as e:
        logger.exception("Failed: %s", e)
        return 1
    except Exception as e:
        logger.exception("Unexpected failure: %s", e)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

