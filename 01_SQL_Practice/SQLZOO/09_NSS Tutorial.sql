01. この例では以下の様に答えた人数を表示する:

問１ Q01 に
'Edinburgh Napier University'（エジンバラ・ネピア大学）で
'(8) Computer Science'を選考している
強く賛成 STRONGLY AGREE と答えたパーセント

訳者注　問１「スタッフは説明が上手ですか？」
SELECT A_STRONGLY_AGREE	
  FROM nss
 WHERE question='Q01'
   AND institution='Edinburgh Napier University'
   AND subject='(8) Computer Science'

02. 問15にスコアscoreが最低でも100ある教育機関と分野を表示する
    訳者注 問15「コースは組織的で円滑に運用されていますか？」スコアは 賛成％ ＋ 強く賛成％ の値
SELECT institution, subject
  FROM nss
 WHERE question='Q15'
  AND score >= 100

03. 計算機科学'(8) Computer Science'で問15'Q15'のスコアが50未満の学科とスコアを表示する。
SELECT institution,score
  FROM nss
 WHERE question='Q15'
   AND subject='(8) Computer Science'
  AND score < 50

04. 問22で各分野ごとに計算機科学'(8) Computer Science'とクリエイティブ・アートアンドデザイン'(H) Creative Arts and Design'と回答した学生の分野と合計を表示する。

訳者注　問22「全体的にコースの質に満足していますか？」
SELECT subject, SUM(response)
  FROM nss
 WHERE question='Q22'
   AND (subject='(8) Computer Science'  OR subject = '(H) Creative Arts and Design')
GROUP BY subject

05. 計算機科学'(8) Computer Science' とクリエイティブアートアンドデザイン '(H) Creative Arts and Design'の各分野ごとに問22に強く賛成 A_STRONGLY_AGREE と答えた学生の分野と総数を表示する。
SELECT subject, SUM(A_STRONGLY_AGREE*response/100)
  FROM nss
 WHERE question='Q22'
   AND (subject='(8) Computer Science'  OR subject = '(H) Creative Arts and Design')
GROUP BY subject

06. 計算機科学'(8) Computer Science' の分野で問22に強く賛成A_STRONGLY_AGREEした学生のパーセントを表示し、クリエイティブアートアンドデザイン '(H) Creative Arts and Design'についても同様の数を示す。
SELECT subject, ROUND(SUM(response * A_STRONGLY_AGREE) / SUM(response), 0)
  FROM nss
 WHERE question='Q22'
   AND subject IN ('(8) Computer Science', '(H) Creative Arts and Design')
GROUP BY subject
