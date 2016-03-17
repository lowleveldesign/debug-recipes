MS SQL Server text collations
=============================

To see the available collations, you can run the query

    SELECT * FROM fn_helpcollations();

Two different types of collations supported by SQL Server are Windows collations and SQL Server collations.

The collation designator is followed by tokens that indicate the nature of the collation. The collation can be a binary collation, in which case the token is BIN or BIN2. For the other 16 collations, the tokens are CI/CS to indicate case sensitivity/insensitivity, AI/AS to indicate accent sensitivity/insensitivity, KS to indicate kanatype sensitivity, and WS to indicate width sensitivity.

To view the **code page for a collation**, you can use the collationproperty function, as in this example:

    SELECT collationproperty('Latin1_General_CS_AS', 'CodePage');

You can define a collation for a particular query, thus keep in mind that this involves transformation for each returned entity:

    SELECT COUNT(*) FROM tbl WHERE longcol COLLATE SQL_Latin1_General_CP_CI_AS LIKE '%abc%';


### Query collation information ###

To find **server** collation settings run:

    SELECT CONVERT (varchar, SERVERPROPERTY('collation'));

    or

    EXECUTE sp_helpsort;

To find **database** collation information run:

    SELECT name, collation_name FROM sys.databases;

    or

    SELECT CONVERT (varchar, DATABASEPROPERTYEX('database_name','collation'));

And column:

    SELECT name, collation_name FROM sys.columns WHERE name = N'<insert character data type column name>';

### Collation configuration ###

You can set collation setting for the entire server during installation - this will become a default collation for all the databases. Some collations are supported only on unicode types (nvarchar or nchar), others define how to treat ASCII chars while dealing with text.

You can also define a default collation on a database level:

    create database testdb collate SQL_Latin1_General_CP_CI_AS

Or on a column level:

    create table t1 (name varchar(100) collate SQL_Latin1_General_CP_CI_AS null)
