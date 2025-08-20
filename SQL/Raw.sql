/* =======================================================================================================================================================
  This is the SQL query for how to Extract and Transform data for futher Analysis
=========================================================================================================================================================*/


SELECT * FROM INFORMATION_SCHEMA.COLUMNS

SELECT @@SERVERNAME AS InstanceName;

SELECT * FROM dbo.fact_customer_reviews


SELECT * FROM customers
SELECT * FROM geography
SELECT * FROM products
SELECT * FROM customer_journey
SELECT * FROM customer_reviews
SELECT * FROM engagement_data

/* =================================== Products =========================================================*/

-- Query the categorize products based on their price:

SELECT 
	ProductID,
	ProductName,
	Category,
	CASE WHEN Price < 50 THEN 'LOW'
		 WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
		 ELSE 'HIGH'
	END AS Price_category
From products
Order by 4

/* ================================= Customers ============================================================*/

-- Join the customer and geography table to enrich the customer data with geographical data:

SELECT 
	c.CustomerId,
	c.CustomerName,
	c.Email,
	c.Gender,
	c.AGE,
	CASE WHEN g.Country = 'UK' THEN 'United Kingdom'
		 Else g.Country
	END AS County,
	g.City,
	COUNT(Country) OVER (PARTITION BY Country) as custmers_count -- How many customers each country
FROM customers AS c
RIGHT JOIN geography AS g
ON c.geographyID = g.GeographyID

/* ============================= Customer_reviews =========================================================*/


-- Query to clean space issues in the review text example:

SELECT
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	REPLACE(LTRIM(RTRIM(ReviewText)),'  ',' ') AS ReviewText
FROM customer_reviews

/* ==================================== Engagement_data ==================================================*/


-- Query to cleab and normalize the engagemnt_data table:

SELECT
	EngagementID,
	ContentID,
	UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS ContentType,
	Likes,
	CampaignID,
	ProductID,
	SUBSTRING(ViewsClicksCombined, 1, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,
	SUBSTRING(ViewsClicksCombined,CHARINDEX('-', ViewsClicksCombined) + 1, LEN(ViewsClicksCombined)) AS Clicks,
	FORMAT(EngagementDate, 'dd.MM.yyyy') AS EngagementDate
FROM engagement_data
WHERE ContentType <> 'NEWSLETTER';

SELECT * FROM engagement_data

/* ========================================== Customer_journey ==================================================*/


-- Identify the tag duplicate records from the customer_journey

WITH DuplicateRecords AS (
SELECT
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	UPPER(Stage) AS Stage,
	Action,
	COALESCE(Duration, COALESCE(Duration, AVG(Duration) OVER (PARTITION BY VisitDate))) as Duration,
	ROW_NUMBER () OVER(PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action ORDER BY JourneyID) AS row_num
FROM customer_journey
)
SELECT 
	JourneyID,
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    Action,
    Duration
FROM DuplicateRecords
Where row_num = 1
ORDER BY JourneyID;

-- Query outer select final cleared and standardize data:

SELECT 
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	Stage,
	Action,
	COALESCE(Duration, Avg_Duration) AS Duration -- replace missing values with average duration for the corresponding values.
FROM
	(
		SELECT
			JourneyID,
			CustomerID,
			ProductID,
			VisitDate,
			UPPER(Stage) AS Stage,
			Action,
			Duration,
			AVG(Duration) OVER (PARTITION BY VisitDate) as Avg_Duration,
			ROW_NUMBER () OVER(PARTITION BY CustomerID, ProductID, VisitDate,UPPER(Stage), Action ORDER BY JourneyID) AS row_num
		FROM customer_journey
	) AS subquery
WHERE row_num = 1
ORDER BY JourneyID; -- keeps only th efirst occurrence of each duplixate group identified in the subquery.



SELECT COALESCE(Duration, AVG(Duration) OVER (PARTITION BY VisitDate)) as Duration FROM customer_journey



/* ==================================== Sentiment Analysis Using python =======================================================*/

--Query to clean whitespace issues in the reviewtext column:

SELECT 
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	REPLACE(TRIM(ReviewText), '  ',' ') AS ReviewText
FROM customer_reviews

SELECT * FROM customer_reviews
