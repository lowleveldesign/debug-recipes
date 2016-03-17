
MySql Databases
---------------

**SHOW DATABASES** lists all database names on the server. Additionally you may display a command that will create a database using **SHOW CREATE DATABASE dbname**, eg.:

    mysql> show create database diagnosticsdb\G;
    *************************** 1. row ***************************
           Database: diagnosticsdb
    Create Database: CREATE DATABASE `diagnosticsdb` /*!40100 DEFAULT CHARACTER SET latin1 */
    1 row in set (0.00 sec)

Database information can be also retrieved using **INFORMATION\_SCHEMA.SCHEMATA** table:

    mysql> select * from information_schema.schemata where schema_name like 'diagnosticsdb'\G;
    *************************** 1. row ***************************
                  CATALOG_NAME: def
                   SCHEMA_NAME: diagnosticsdb
    DEFAULT_CHARACTER_SET_NAME: latin1
        DEFAULT_COLLATION_NAME: latin1_swedish_ci
                      SQL_PATH: NULL
    1 row in set (0.00 sec)