/*
 * ==========================
 * CREATE DATABASE AND CHEMAS
 * ==========================
 * 
 * !!!!WARNING!!!!
 * RUNNING THIS SCRIPT WILL DROP THE ENTIRE 'DataWarehouse' DATABASE IF IT EXISTS!!!!
 */
-- To delete this database, we need to connect to another database (for example, to the default database called "postgres")
-- because PostgreSQL does not allow us to delete a database with active connections.
-- If you are working in DBeaver, simply switch the database manually by clicking RMB on the "temporary" database and selecting the required option.
-- You can also do this using \c data_base_name in the psql terminal

SELECT 
	pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'datawarehouse';

DROP DATABASE IF EXISTS datawarehouse;

-- Creating database and schemas
CREATE DATABASE DataWareHouse;

-- Before creating schemas connect to datawarehouse 
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
