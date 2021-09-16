--QUESTION-1

--Create above table (transactions) with “with” clause,

WITH transactions AS
(
		SELECT * 
		FROM
			(
				VALUES
				(5, 2, 10, CAST('2-12-20' AS date)),
				(1, 3, 15, CAST('2-13-20' AS date)),
				(2, 1, 20, CAST('2-13-20' AS date)),
				(2, 3, 25, CAST('2-14-20' AS date)),
				(3, 1, 20, CAST('2-15-20' AS date)),
				(3, 2, 15, CAST('2-15-20' AS date)),				
				(1, 4, 5, CAST('2-16-20' AS date))	
			) AS Table_1 ([Sender], [Receiver], [Amount], [Transaction_date])
),

--Sum amounts for each sender (debits) and receiver (credits),

debits AS (
SELECT [Sender], SUM ([Amount]) AS debited
FROM transactions
GROUP BY [Sender]
),

credits AS (
SELECT [Receiver], SUM([Amount]) AS credited
FROM transactions
GROUP BY [Receiver]
)

-- Full (outer) join debits and credits tables on user id, taking net change as difference between credits and debits, coercing nulls to zeros with coalesce()

SELECT COALESCE(sender, receiver) AS [User], 
COALESCE(credited, 0) - COALESCE(debited, 0) AS [Net_Change] 
FROM debits D
FULL JOIN credits C
ON D.sender = C.receiver
ORDER BY net_change DESC


--QUESTION-2

--Create above tables (attendance, students) with “with” clause,

WITH attendance AS
(
		SELECT * 
		FROM
			(
				VALUES
				(1, CAST('4-3-20' AS date), 0),
				(2, CAST('4-3-20' AS date), 1),
				(3, CAST('4-3-20' AS date), 1), 
				(1, CAST('4-4-20' AS date), 1), 
				(2, CAST('4-4-20' AS date), 1), 
				(3, CAST('4-4-20' AS date), 1), 
				(1, CAST('4-5-20' AS date), 0), 
				(2, CAST('4-5-20' AS date), 1), 
				(3, CAST('4-5-20' AS date), 1), 
				(4, CAST('4-5-20' AS date), 1)
			) AS Table_1 (student_id, school_date, attendance)
),
students AS
		(
		SELECT * 
		FROM	
				(
				VALUES
				(1, 2, 5, CAST('4-3-12' AS date)),
				(2, 1, 4, CAST('4-4-13' AS date)),
				(3, 1, 3, CAST('4-5-14' AS date)), 
				(4, 2, 4, CAST('4-3-13' AS date))
				) AS Table_2 (student_id, school_id, grade_level, date_of_birth)
)

--Join attendance and students table on student ID, and day and month of school day = day and month of birthday, 
--summing ones in attendance column, dividing by total number of entries, and rounding

SELECT CAST(1.0*SUM(attendance)/COUNT(*) AS NUMERIC (3,2)) AS Birthday_attendance
FROM attendance A, students B
WHERE  A.student_id = B.student_id 
AND MONTH (A.school_date) = MONTH (B.date_of_birth)
AND DAY (A.school_date) = DAY (B.date_of_birth)