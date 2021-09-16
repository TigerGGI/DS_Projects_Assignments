

--DAwSQL Session -8 

--E-Commerce Data and Customer Retention Analysis with SQL

/*
Introduction

-	You can benefit from the ERD diagram given to you during your work.
-	You have to create a database and import into the given csv files. 
-	During the import process, you will need to adjust the date columns. You need to carefully observe the data types and how they should be.In our database, a star model will be created with one fact table and four dimention tables.
-	The data are not very clean and fully normalized. However, they don't prevent you from performing the given tasks. In some cases you may need to use the string, window, system or date functions.
-	There may be situations where you need to update the tables.
-	Manually verify the accuracy of your analysis.

Analyze the data by finding the answers to the questions below:

1.	Join all the tables and create a new table with all of the columns, called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
2.	Find the top 3 customers who have the maximum count of orders.
3.	Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
4.	Find the customer whose order took the maximum time to get delivered.
5.	Retrieve total sales made by each product from the data (use Window function)
6.	Retrieve total profit made from each product from the data (use windows function)
7.	Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
8.	Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID
9.	Write a query that returns customers who purchased both product 11 and product 14, 
	as well as the ratio of these products to the total number of products purchased by the customer.

*/

--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

SELECT *
INTO
combined_table
FROM
(
SELECT 
cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, 
mf.Ord_id, mf.Prod_id, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Profit, mf.Shipping_Cost, mf.Product_Base_Margin,
od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category,
sd.Ship_id, sd.Ship_Mode, sd.Ship_Date
FROM market_fact mf
INNER JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
INNER JOIN orders_dimen od ON od.Ord_id = mf.Ord_id
INNER JOIN prod_dimen pd ON pd.Prod_id = mf.Prod_id
INNER JOIN shipping_dimen sd ON sd.Ship_id = mf.Ship_id
) A;

SELECT	*
FROM combined_table

--///////////////////////

--2. Find the top 3 customers who have the maximum count of orders.

SELECT	TOP 3 Cust_id, Customer_name, COUNT(Ord_id) COUNT_ORD
FROM	combined_table
GROUP BY
		Cust_id, Customer_name
ORDER BY 3 DESC

--/////////////////////////////////

--3.3.	Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

ALTER TABLE combined_table
ADD	DaysTakenForDelivery INT;

UPDATE combined_table
SET	DaysTakenForDelivery= DATEDIFF(DAY, Order_Date, Ship_Date)

SELECT TOP 100 *
FROM combined_table

--////////////////////////////////////

--4. Find the customer whose order took the maximum time to get delivered.

SELECT	Cust_id, Customer_name, Order_Date, Ship_Date, DaysTakenForDelivery
FROM	combined_table
WHERE	DaysTakenForDelivery = (
								SELECT MAX(DaysTakenForDelivery)
								FROM	combined_table
								)

SELECT TOP(1) Customer_name, Ord_id, DaysTakenForDelivery
FROM	[dbo].[combined_table]
ORDER BY DaysTakenForDelivery DESC

--//////////////////////////////

--5. Retrieve total sales made by each product from the data (use Window function)

--compare with the total QUANTITY price made by each product

SELECT DISTINCT Prod_id, SUM(Sales) OVER (PARTITION BY Prod_id) SUM_SALES
FROM
combined_table
ORDER BY SUM_SALES

SELECT * FROM
combined_table

--////////////////////////////////////

--6. Retrieve total profit made from each product from the data (use windows function)

SELECT	DISTINCT Prod_id, SUM(Profit) OVER (PARTITION BY Prod_id) SUM_PROFIT
FROM	combined_table
ORDER BY SUM_PROFIT DESC;

--////////////////////////////////

--7. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

SELECT	COUNT (DISTINCT Cust_id) AS Unique_Customers
FROM	combined_table
WHERE	YEAR (Order_Date) = 2011
AND		MONTH(Order_Date) = 01;

SELECT	MONTH(Order_Date) [Month],
		COUNT (DISTINCT cust_id) count_customers
FROM
combined_table A
WHERE
EXISTS
		(
			SELECT	cust_id
			FROM	combined_table B
			WHERE	A.Cust_id = B.Cust_id
			AND		YEAR (Order_Date) = 2011
			AND		MONTH(Order_Date) = 01
		)
AND	YEAR (Order_Date) = 2011
GROUP BY 
		MONTH(Order_Date)

--////////////////////////////////////////////

--8. write a query to return for each user the time elapsed between the first purchasing and the third purchasing, 
--in ascending order by Customer ID

SELECT	Cust_id, MIN (Order_Date) first_purchase
FROM	combined_table
GROUP BY 
Cust_id

SELECT	DISTINCT 
		Cust_id,
		Order_Date as third_purchase,
		DENSE_DATE,
		first_purchase,
		DATEDIFF(DAY, first_purchase, Order_Date) DAY_ELAPSED
FROM
		(
			SELECT	Cust_id,
					Order_Date,
					Ord_id,
					MIN (Order_Date) OVER (PARTITION BY Cust_id) first_purchase, 
					DENSE_RANK() OVER (PARTITION BY cust_id ORDER BY Order_Date) DENSE_DATE
			FROM	combined_table
		) A
WHERE
DENSE_DATE = 3

SELECT *
FROM combined_table
WHERE	Cust_id = 'Cust_100'
ORDER BY order_date 

SELECT * ,
		DATEDIFF(DAY, (FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date)), 
		(LEAD(Order_Date,2) OVER(PARTITION BY Cust_id ORDER BY Order_Date))) AS first_third_diff
FROM [dbo].[combined_table]
ORDER BY Cust_id ASC

SELECT Cust_id, Ord_id, Order_date, Prod_id,
		FIRST_VALUE (Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) FIST_PUR,
		LEAD(Order_Date,2) OVER(PARTITION BY Cust_id ORDER BY Order_Date) THIRD_PUR
FROM
[combined_table]
WHERE
Cust_id = 'Cust_1000'

--//////////////////////////////////////

--9. Write a query that returns customers who purchased both product 11 and product 14, 
--as well as the ratio of these products to the total number of products purchased by the customer.

WITH T1 AS 
(
	SELECT	Cust_id,
			SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1 ELSE 0 END) AS P11,
			SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1 ELSE 0 END) AS P14,
			COUNT (Prod_id) TOTAL_PROD
	FROM	combined_table
	GROUP BY
			Cust_id
	HAVING
			SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1 ELSE 0 END) >=1 AND
			SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1 ELSE 0 END) >=1
)
SELECT	Cust_id, P11, P14, TOTAL_PROD,
		CAST (1.0*P11/TOTAL_PROD AS NUMERIC (3,2)) AS RATIO_P11,
		CAST (1.0*P14/TOTAL_PROD AS NUMERIC (3,2)) AS RATIO_P14
FROM T1

--/////////////////

--CUSTOMER RETENTION ANALYSIS

/*
Find month-by-month customer retention rate  since the start of the business (using views).

1.	Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple years since whenever business started operations.
2.	Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
3.	Calculate the time gaps between visits.
4.	Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.
5.	Calculate the retention month wise
*/

--1. Create a view where each user’s visits are logged by month, 
--	allowing for the possibility that these will have occurred over multiple years since whenever business started operations.

CREATE VIEW CUSTOMER_LOGS AS
SELECT	Cust_id,
		YEAR (Order_Date) [Year],
		MONTH(Order_Date) [Month],
		COUNT (*) total_visit,
		DENSE_RANK() OVER (ORDER BY YEAR (Order_Date), MONTH(Order_Date)) AS DENSE_MONTH
FROM	combined_table
GROUP BY	
		Cust_id, MONTH(Order_Date), YEAR (Order_Date)

--//////////////////////////////////

--2. Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.

CREATE VIEW NEXT_VISIT_VW AS
SELECT	*,
		LEAD (DENSE_MONTH) OVER (PARTITION BY cust_id ORDER BY DENSE_MONTH) NEXT_VISIT_MONTH
FROM	CUSTOMER_LOGS

--/////////////////////////////////

--3. Calculate the time gaps between visits.

CREATE VIEW TIME_GAPS_VW AS 
SELECT	*, NEXT_VISIT_MONTH - DENSE_MONTH AS TIME_GAPS
FROM	NEXT_VISIT_VW

--/////////////////////////////////////////

--4. Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

SELECT cust_id, AVG_TIME_GAP,
		CASE 
			WHEN AVG_TIME_GAP = 1 THEN 'retained'
			WHEN AVG_TIME_GAP >1 THEN 'irregular'
			WHEN AVG_TIME_GAP IS NULL THEN 'churned'
		ELSE 'UNKNOWN DATA' END CUST_CLASS
FROM
		(
		SELECT	cust_id, AVG (TIME_GAPS) AVG_TIME_GAP
		FROM	TIME_GAPS_VW
		GROUP BY 
				cust_id
		) A

--/////////////////////////////////////

--5. Calculate the retention month wise.

SELECT  DISTINCT
		NEXT_VISIT_MONTH as retention_month,
		COUNT (cust_id) OVER (PARTITION BY NEXT_VISIT_MONTH ) RETENTION_SUM_MONTHLY
FROM 
TIME_GAPS_VW
WHERE
TIME_GAPS = 1
ORDER BY
		1 