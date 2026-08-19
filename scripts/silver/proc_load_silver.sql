CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    error_msg TEXT;
    error_state TEXT;
    error_context TEXT;
BEGIN
	TRUNCATE TABLE silver.crm_cust_info;
	INSERT INTO silver.crm_cust_info
	(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
	SELECT 
		t.cst_id,
		t.cst_key,
		TRIM(t.cst_firstname),
		TRIM(t.cst_lastname),
		CASE
			WHEN UPPER(TRIM(t.cst_marital_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(t.cst_marital_status)) = 'M' THEN 'Married'
			ELSE 'N/A'
		END AS cst_marital_status, 
		CASE
			WHEN UPPER(TRIM(t.cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(t.cst_gndr)) = 'M' THEN 'Male'
			ELSE 'N/A'
		END AS cst_gndr, 
		t.cst_create_date
	FROM
	( 
		SELECT 
			* ,
			ROW_NUMBER() OVER (PARTITION BY cci.cst_id ORDER BY cci.cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info cci
		
	)t WHERE t.flag_last = 1;
	
	TRUNCATE TABLE silver.crm_prd_info;
	INSERT INTO silver.crm_prd_info
	(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
	SELECT 
		cpi.prd_id,
		REPLACE(SUBSTRING(cpi.prd_key FOR 5), '-', '_') AS cat_id,
		SUBSTRING(cpi.prd_key FROM 7) AS prd_key,
		cpi.prd_nm,
		COALESCE(cpi.prd_cost, 0) AS prd_cost,
		CASE UPPER(TRIM(cpi.prd_line)) 
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
			 ELSE 'N/A'
		END AS prd_line,
		cpi.prd_start_dt::DATE, 
		(LEAD(cpi.prd_start_dt) OVER(PARTITION BY cpi.prd_key ORDER BY cpi.prd_start_dt ASC) - INTERVAL '1 DAY')::DATE AS prd_end_dt
	FROM bronze.crm_prd_info cpi;
	
	TRUNCATE TABLE silver.crm_sales_details;
	INSERT INTO silver.crm_sales_details
	(sales_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
	SELECT 
		sales_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE
			WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) !=8 THEN NULL
			ELSE TO_DATE(sls_order_dt::VARCHAR, 'YYYYMMDD')
		END AS sls_order_dt,
		CASE
			WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) !=8 THEN NULL
			ELSE TO_DATE(sls_ship_dt::VARCHAR, 'YYYYMMDD')
		END AS sls_ship_dt,
		CASE
			WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) !=8 THEN NULL
			ELSE TO_DATE(sls_due_dt::VARCHAR, 'YYYYMMDD')
		END AS sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE sls_price
		END AS sls_price
	FROM bronze.crm_sales_details;
	
	TRUNCATE TABLE silver.erp_cust_az12;
	INSERT INTO silver.erp_cust_az12
	(cid, bdate, gen)
	SELECT 
		CASE
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
			ELSE cid
		END AS cid,
		CASE
			WHEN bdate > NOW()::DATE THEN NULL
			ELSE bdate
		END AS bdate,
		CASE
			WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'N/A'
		END AS gen
	FROM bronze.erp_cust_az12;
	
	TRUNCATE TABLE silver.erp_loc_a101;
	INSERT INTO silver.erp_loc_a101
	(cid, cntry)
	SELECT 
	REPLACE(cid, '-', '') AS cid, 
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
		 ELSE TRIM(cntry)
	END AS cntry
	FROM bronze.erp_loc_a101;
	
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	INSERT INTO silver.erp_px_cat_g1v2
	(id, cat, subcat, maintenance)
	SELECT 
		id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;

	EXCEPTION
    WHEN OTHERS THEN 
        GET STACKED DIAGNOSTICS 
            error_msg = MESSAGE_TEXT,
            error_state = RETURNED_SQLSTATE,
            error_context = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE '=== ERROR INFORMATION ===';
        RAISE NOTICE 'Message: %', error_msg;
        RAISE NOTICE 'Code SQLSTATE: %', error_state;
        RAISE NOTICE 'Context: %', error_context;
        RAISE NOTICE '============================';
END;
$$;
