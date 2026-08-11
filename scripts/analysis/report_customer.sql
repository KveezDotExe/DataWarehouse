CREATE VIEW gold.report_customer AS 
WITH base_query AS (
SELECT
	t.order_number,
	t.product_key,
	t.order_date,
	t.sales_amount,
	t.quantity,
	dc.customer_key,
	dc.customer_number,
	CONCAT(dc.first_name, ' ', dc.last_name) AS customer_name,
	EXTRACT(YEAR FROM AGE(current_date, dc.birthdate)) AS customer_age
FROM gold.fact_sales t
LEFT JOIN gold.dim_customers dc ON dc.customer_key = t.customer_key
WHERE t.order_date IS NOT NULL
), customer_aggregation AS(

SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) total_products,
	MAX(order_date) last_order_date,
	EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date)))*12+
	EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
FROM base_query
GROUP BY customer_key,
	customer_number,
	customer_name,
	customer_age
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	CASE		
		WHEN customer_age < 20 THEN 'Under 20'
		WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
		WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
		WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
		ELSE '50 and above'
	END AS age_group,
	CASE
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <=5000 THEN 'Regular'
		ELSE 'New'
	END AS status_segment,
	total_orders, 
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	AGE(current_date, last_order_date) AS recency,
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_orders,
	CASE 
		WHEN lifespan = 0 THEN total_sales
		ELSE (total_sales / lifespan)::int
	END AS avg_monthly_spend
FROM customer_aggregation;
