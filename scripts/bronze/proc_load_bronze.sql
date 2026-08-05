/*
 * =====================================
 * HOW TO EXECUTE THIS PROCEDURE
 * =====================================
 * 
 * ----------------------------
 * CALL bronze.load_bronze();
 * 
 * OR
 * 
 * CALL load_bronze(); (if you have already connected to the bronze schema)
 * ----------------------------
 */


CREATE OR REPLACE PROCEDURE bronze.load_bronze ()
LANGUAGE plpgsql
AS $$
DECLARE
	start_time TIMESTAMP;
	end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
BEGIN
	
	RAISE NOTICE '===============================';
	RAISE NOTICE 'LOADING BRONZE LAYER';
	RAISE NOTICE '===============================';

	batch_start_time := NOW();
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.crm_cust_info';
	RAISE NOTICE '---------------------------------';
	
	start_time := NOW();

	TRUNCATE TABLE bronze.crm_cust_info;
	COPY bronze.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_date)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_crm\cust_info.csv'
	DELIMITER ','
	CSV HEADER;

	end_time := NOW();
	
	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.crm_prd_info';
	RAISE NOTICE '---------------------------------';
	
	start_time := NOW();

	TRUNCATE TABLE bronze.crm_prd_info;
	COPY bronze.crm_prd_info (prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_crm\prd_info.csv'
	DELIMITER ','
	CSV HEADER;

	end_time := NOW();

	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.crm_sales_details';
	RAISE NOTICE '---------------------------------';

	start_time := NOW();	

	TRUNCATE TABLE bronze.crm_sales_details;
	COPY bronze.crm_sales_details (sales_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_crm\sales_details.csv'
	DELIMITER ','
	CSV HEADER;

	end_time := NOW();

	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.erp_cust_az12';
	RAISE NOTICE '---------------------------------';

	start_time := NOW();
	
	TRUNCATE TABLE bronze.erp_cust_az12;
	COPY bronze.erp_cust_az12 (cid, bdate, gen)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_erp\cust_az12.csv'
	DELIMITER ','
	CSV HEADER;
	
	end_time := NOW();

	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.erp_loc_a101';
	RAISE NOTICE '---------------------------------';
	
	start_time := NOW();

	TRUNCATE TABLE bronze.erp_loc_a101;
	COPY bronze.erp_loc_a101 (cid, cntry)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_erp\loc_a101.csv'
	DELIMITER ','
	CSV HEADER;
	
	end_time := NOW();

	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Loading: bronze.erp_px_cat_g1v2';
	RAISE NOTICE '---------------------------------';
	
	start_time := NOW();

	TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	COPY bronze.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
	FROM 'D:\postgreSQL\data_warehouse\datasets\source_erp\px_cat_g1v2.csv'
	DELIMITER ','
	CSV HEADER;

	end_time := NOW();

	RAISE NOTICE '>> Load time: %', EXTRACT(EPOCH FROM (end_time - start_time))::VARCHAR;
	RAISE NOTICE ' ';
	batch_end_time := NOW();
	RAISE NOTICE '---------------------------------';
	RAISE NOTICE 'Batch loading time: %', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time))::VARCHAR;
	RAISE NOTICE '---------------------------------';

END;
$$;


