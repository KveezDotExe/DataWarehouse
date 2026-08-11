CREATE VIEW gold.report_products AS
WITH product_base AS(
SELECT 
	t.order_number,
	d.product_id,
	d.product_name,
	d.category,
	d.subcategory,
	d."cost",
	t.quantity,
	t.sales_amount,
	t.order_date,
	t.customer_key
FROM gold.dim_products d
LEFT JOIN gold.fact_sales t ON d.product_key = t.product_key
WHERE t.order_date IS NOT NULL
), product_aggregation AS (
SELECT
	product_id,
	product_name,
	category,
	subcategory,
	"cost",
	SUM(quantity) AS total_quantity,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT order_number) AS total_orders,
	EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date)))*12 + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan,
	COUNT(DISTINCT customer_key) AS total_uniq_customers,
	MIN(order_date) AS start_order_date,
	MAX(order_date) AS last_order_date,
	ROUND(AVG(sales_amount::NUMERIC/NULLIF(quantity,0)), 1) AS avg_selling_price
FROM product_base
GROUP BY product_id, product_name, category, subcategory, "cost"
)
SELECT 
	product_id,
	product_name,
	category,
	subcategory,
	"cost",
	total_orders,
	total_sales,
	total_quantity,
	total_uniq_customers,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Perormer'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	avg_selling_price,
	EXTRACT(YEAR FROM AGE(current_date, last_order_date))*12 + EXTRACT(MONTH FROM AGE(current_date, last_order_date)) AS revency_in_month,
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders
	END AS avg_orders,
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan::INT
	END AS avg_monthly_revenue
FROM product_aggregation;
