--01. 各大陸の国を表示する:
SELECT continent, COUNT(name)
  FROM world
 GROUP BY continent

--02. 各大陸の総人口を表示する:
SELECT continent, SUM(population)
  FROM world
 GROUP BY continent

--03. WHERE は集計関数が働く前にレコードを取り除く。最低でも200000000人の人口の国の数を関連する大陸ごとに表示する。
SELECT continent, COUNT(name)
  FROM world
 WHERE population>200000000
 GROUP BY continent

--04.HAVING 節は GROUP BY の後でチェックされる。集計結果をHAVING 節でチェックできる。 . 総人口が500000000人より大きな大陸を総人口と共に表示する。 .
SELECT continent, SUM(population)
  FROM world
 GROUP BY continent
HAVING SUM(population)>500000000

