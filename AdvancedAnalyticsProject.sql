-- ADVANCED DATA ANALYTICS PROJECT USING SQL
-- Mason Hollis

-- STEP 1: CHANGE-OVER TIME TRENDS
--Trends by Year/Month
SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- Trends using TRUNC function
SELECT 
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month,order_date);


-- Trends using FORMAT
SELECT 
	FORMAT(order_date, 'yyyy-MMM') AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');


-- STEP 2: CUMULATIVE ANALYSIS 
-- Calculate the total sales per month 
-- and the running total of sales over time.
SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM
(
SELECT 
	DATETRUNC(month,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)) t;


-- Calculate the Moving Average price by month
SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_average_price
FROM
(
SELECT 
	DATETRUNC(month,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)) t;


-- STEP 3: Performance Analysis
-- Analyze the yearly performance of products by comparing
-- each product's sales to both its average sales performance and the previous year's sales.

WITH yearly_product_sales AS(
SELECT 
	YEAR(f.order_date) AS order_year,
	p.product_name,
	SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key=p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY 
	YEAR(f.order_date),
	p.product_name 
	)
SELECT 
	 order_year,
	 product_name,
	 current_sales,
	 AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
	 current_sales-AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
 CASE WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	  WHEN current_sales-AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	  ELSE 'Avg'
END AS avg_change,
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
	current_sales- LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS difference_previous_year,
 CASE WHEN current_sales-LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	  WHEN current_sales-LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	  ELSE 'No Change'
END AS previous_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year;


-- STEP 4: Part to Whole Analysis
-- Which categories contribute the most to overall sales?

WITH category_sales AS (
SELECT
	category,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key=p.product_key
GROUP BY category) 

SELECT
 category,
 total_sales,
 SUM(total_sales) OVER () overall_sales,
 CONCAT (ROUND(CAST(total_sales AS FLOAT)/SUM(total_sales) OVER () *100,2), '%') AS overall_sales
 FROM category_sales
 ORDER BY total_sales DESC;

 -- STEP 5: Data Segmentations

 /* Segment products into cost ranges and 
 count how mant products fall into each segment*/

 WITH product_segments AS (
 SELECT 
	product_key,
	product_name,
	cost,
CASE WHEN cost< 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END AS cost_range
 FROM gold.dim_products)

 SELECT 
 cost_range,
 COUNT(product_key) AS total_products
 FROM product_segments
 GROUP BY cost_range
 ORDER BY total_products DESC;


 /* Group customers into three segments based on their spending behavior
 VIP: at least 12 months of history and spening more than 5,000
 Regular: at least 12 months of history but spends less than 5,000
 New: lifespan less than 12 months
 And find the total number of customers by each group
 */

 WITH customer_spending AS(
 SELECT 
 c.customer_key,
 SUM(f.sales_amount) AS total_spending,
 MIN(order_date) AS first_order,
 MAX(order_date) AS last_order,
 DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
 FROM gold.fact_sales AS f
 LEFT JOIN gold.dim_customers AS c
 ON f.customer_key=c.customer_key
 GROUP BY c.customer_key)

 SELECT
 customer_segment,
 COUNT(customer_key) AS total_customers
 FROM( 
 SELECT customer_KEY,
 CASE WHEN lifespan> 12 AND total_spending> 5000 THEN 'VIP'
	  WHEN lifespan >=12 AND total_spending <=5000 THEN 'Regular'
	  ELSE 'New'
END customer_segment
 FROM customer_spending) t
 GROUP BY customer_segment
 ORDER BY total_customers DESC;


 -- STEP 6: BUILD CONSUMER REPORT
/* Purpose:
	-This repost consolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics
		-total orders
		-total sales
		-total quantity purchased
		-total products
		-lifespan (in months)
	4. Calculates valuable KPIs:
		-recency (months since last order)
		-average order value
		-average monthly spending.
*/

CREATE VIEW gold.report_customer AS 
WITH base_query AS(
-- 1. Base Query: Retrieves core columns from tables
SELECT 
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ' , c.last_name) AS customer_name,
	DATEDIFF (year, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key=f.customer_key
WHERE f.order_date IS NOT NULL)
, 
customer_aggregation AS(
-- 2. Customer Aggregations: Summarizes key metrics at the customer level
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAx(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date),MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,
	customer_number,
	customer_name,
	age)
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE 
		WHEN age<20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 29 THEN '20-29'
		WHEN age BETWEEN 30 AND 39 THEN '30-39'
		WHEN age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and above'
	END age_group,
	 CASE 
	  WHEN lifespan> 12 AND total_sales> 5000 THEN 'VIP'
	  WHEN lifespan >=12 AND total_sales <=5000 THEN 'Regular'
	  ELSE 'New'
END customer_segment,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	-- Compute average order value (AVO)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders 
		END AS avg_order_value,
	-- Compute average monthly spend
	CASE 
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
		END AS avg_monthly_spend
FROM customer_aggregation



SELECT * from gold.report_customer;

-- STEP 7: BUILD PRODUCT REPORT
/* Purpose:
	-This repost consolidates key product metrics and behaviors

Highlights:
	1. Gathers essential fields such as product name, category, subcategory and transaction details.
	2. Segments products into categories (High-Performers, Mid-Range or Low Performers).
	3. Aggregates product-level metrics
		-total orders
		-total sales
		-total quantity sold
		-total products
		-lifespan (in months)
	4. Calculates valuable KPIs:
		-recency (months since last sale)
		-average order revenue
		-average monthly spending.
*/

CREATE VIEW gold.report_product AS
WITH base_query AS (
--1. Base Query
SELECT 
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.dim_products AS p
INNER JOIN gold.fact_sales AS f
ON p.product_key=f.product_key
WHERE order_date IS NOT NULL
), 

product_aggregation AS 
(
SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
	MAX (order_date) AS last_sale,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query
GROUP BY	product_key,
	product_name,
	category,
	subcategory,
	cost  
	)

SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(month, last_sale, GETDATE()) AS recency_in_months,
	CASE 
		WHEN total_sales > 50000 THEN 'High Performer'
		WHEN total_sales>= 30000 THEN 'Mid-Range'
		ELSE 'Low Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan
	END AS avg_monthly_revenue

FROM product_aggregation;