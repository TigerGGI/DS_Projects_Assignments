


--DAwSQL Assignment - 1

--1. How to query the factorial of 6 recursively

WITH T1
AS
(
SELECT 1 AS NUM
),
T2 AS
(
SELECT NUM *5 RESULT
FROM T1
)
SELECT * FROM T2

----RECURSIVE CTE 

WITH T1
AS
(
SELECT 1 AS NUMBER
UNION ALL
SELECT NUMBER*2
FROM T1
WHERE NUMBER<20
)
SELECT * FROM T1


--

/*
0	1
1	1
2	2
3	6
4	24

*/


WITH T1 AS
(
SELECT 0 fact_number, 1 result
UNION ALL
SELECT fact_number+1, (fact_number+1) * result
FROM T1
WHERE fact_number < 6
)
SELECT  result
FROM T1
WHERE fact_number=6



--FUNCTION

CREATE FUNCTION FACTORIAL (@NUMBER INT)
RETURNS BIGINT
AS
BEGIN
	DECLARE @RESULT BIGINT;
		
		WITH T1 AS
		(
		SELECT 0 fact_number, 1 result
		UNION ALL
		SELECT fact_number+1, (fact_number+1) * result AS RESULT
		FROM T1
		WHERE fact_number < @NUMBER
		)
		SELECT  @RESULT = result
		FROM T1
		WHERE fact_number = @NUMBER

RETURN @RESULT
END;


SELECT dbo.FACTORIAL(10) as factorial_result

--------------///////////////////////////

--2. Cancelation rate & Publication rate

WITH Users AS
(
	SELECT * 
	FROM
		(
			VALUES
			(1,'start', CAST('01-01-20' AS date)),
			(1,'cancel', CAST('01-02-20' AS date)), 
			(2,'start', CAST('01-03-20' AS date)), 
			(2,'publish', CAST('01-04-20' AS date)), 
			(3,'start', CAST('01-05-20' AS date)), 
			(3,'cancel', CAST('01-06-20' AS date)), 
			(1,'start', CAST('01-07-20' AS date)), 
			(1,'publish', CAST('01-08-20' AS date))
		) AS Table_1 ([user_id], [action], [date])
	),
Table_2 AS
	(
	SELECT	[user_id],
			SUM(CASE WHEN [action] = 'cancel' THEN 1 ELSE 0 END) AS cnt_cancel,
			SUM(CASE WHEN [action] = 'start' THEN 1 ELSE 0 END) AS cnt_start,
			SUM(CASE WHEN [action] = 'publish' THEN 1 ELSE 0 END) AS cnt_publish
	FROM	Users
	GROUP BY [user_id]
	)
SELECT	[user_id],
		CAST((1.0*cnt_cancel/cnt_start) AS NUMERIC(3,1)) AS cancelation_rate,
		CAST((1.0*cnt_publish/cnt_start) AS NUMERIC (3,1)) AS publication_rate
FROM	Table_2

-----SECOND SOLUTION

WITH Users AS
(
		SELECT * 
		FROM
			(
				VALUES
				(1,'start', CAST('01-01-20' AS date)),
				(1,'cancel', CAST('01-02-20' AS date)), 
				(2,'start', CAST('01-03-20' AS date)), 
				(2,'publish', CAST('01-04-20' AS date)), 
				(3,'start', CAST('01-05-20' AS date)), 
				(3,'cancel', CAST('01-06-20' AS date)), 
				(1,'start', CAST('01-07-20' AS date)), 
				(1,'publish', CAST('01-08-20' AS date))
			) AS Table_1 ([user_id], [action], [date])
		),
Table_2 AS
(
SELECT *
FROM
    (
	SELECT [user_id], [action]
	FROM users
	) A
PIVOT
(
   COUNT([action])
   FOR [action] IN
   (
   [Start],
   [Publish],
   [Cancel])
   ) AS PIVOT_TABLE
)
SELECT	[user_id],
		CAST((1.0*[Cancel]/[Start]) AS NUMERIC(3,1)) as cancelation_rate,
		CAST((1.0*[Publish]/[Start])AS NUMERIC (3,1)) as publication_rate
FROM	Table_2
