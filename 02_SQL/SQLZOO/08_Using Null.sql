

01.学科がNULL値の教員をリストにする。
SELECT name FROM teacher
WHERE dept IS NULL

02.内部結合 INNER JOIN では学科に所属しない教員と教員のいない学科をリストにする。
SELECT teacher.name, dept.name
 FROM teacher INNER JOIN dept
           ON (teacher.dept=dept.id)

03.別の JOIN を使って全教員をリストにする。
SELECT teacher.name, dept.name
 FROM teacher LEFT JOIN dept
           ON (teacher.dept=dept.id)

04.別の JOIN を使って全学科をリストにする。
SELECT teacher.name, dept.name
 FROM teacher RIGHT JOIN dept
           ON (teacher.dept=dept.id)

05.COALESCE関数で携帯番号を出力する。番号が無い場合は'07986 444 2266'を代わりに使う。 
    教員teacherの名前nameと携帯番号mobileがNULLの場合は代わりに'07986 444 2266'出力する。
SELECT name, COALESCE(mobile, '07986 444 2266') FROM teacher

06. COALESCE関数とLEFT JOINで教員teacherの名前nameと学科名を出力する。 学科が無い時は'None'を代わりに使う。
SELECT teacher.name, COALESCE(dept.name, 'None') FROM teacher LEFT JOIN dept ON (teacher.dept = dept.id)

07.COUNTで教員数と携帯の数を数える。
SELECT COUNT(teacher.name), COUNT(mobile) FROM teacher

08.COUNTとGROUP BY dept.name で各学科ごとのスタッフ数を表示する。 RIGHT JOIN で工学科Engineeringをちゃんとリストに記載すること。
SELECT dept.name, COUNT(teacher.name) FROM teacher RIGHT JOIN dept ON teacher.dept = dept.id GROUP BY dept.name

09. CASEで各教員のnameの後ろに（訳者注 次のフィールドに）学科deptが1か2なら'Sci'それ以外なら'Art'を続ける。
SELECT name,
CASE WHEN dept = 1 THEN 'Sci'
         WHEN dept = 2 THEN 'Sci'
         ELSE 'Art'
END
FROM teacher

10. CASEで各教員のnameの後ろに（訳者注 次のフィールドに）学科deptが1か2なら'Sci'、3なら'Art'、それ以外は'None'を続ける。
SELECT name, 
CASE WHEN dept =1 OR dept = 2 THEN 'Sci'
        WHEN dept =3 THEN 'Art' 
ELSE 'None'
END
FROM teacher
