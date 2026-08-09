CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS cusomer_id, 
	ci.cst_key AS customer_number, 
	ci.cst_firstname AS first_name, 
	ci.cst_lastname AS last_name,
	ela.cntry AS counrty,
	ci.cst_marital_status AS marital_status, 
	CASE
		WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
		ELSE COALESCE(eca.gen, 'N/A')
	END AS gender,
	eca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 eca ON eca.cid = ci.cst_key
LEFT JOIN silver.erp_loc_a101 ela ON ela.cid = ci.cst_key;

CREATE VIEW gold.dim_products AS 
SELECT
	ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
	pi.prd_id AS product_id,
	pi.prd_key AS product_number,
	pi.prd_nm AS product_name,
	pi.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pi.prd_cost AS cost,
	pi.prd_line AS product_line,
	pi.prd_start_dt AS start_date
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pc.id = pi.cat_id 
WHERE pi.prd_end_dt IS NULL;

CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sales_ord_num AS order_number,
	dp.product_key,
	dc.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products dp ON dp.product_number = sd.sls_prd_key
LEFT JOIN gold.dim_customers dc ON dc.cusomer_id = sd.sls_cust_id;
