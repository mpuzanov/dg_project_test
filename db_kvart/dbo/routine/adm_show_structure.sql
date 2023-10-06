CREATE   PROCEDURE [dbo].[adm_show_structure]
(
	@objname NVARCHAR(776)
)
AS
	--
	--  Выдает структуру запрашиваемой таблицы
	--
	SET NOCOUNT ON

	--declare @objname nvarchar(776) 
	DECLARE @objid INT
	DECLARE @sysobj_type CHAR(2)
	DECLARE @no	  VARCHAR(35)
		   ,@yes  VARCHAR(35)
		   ,@none VARCHAR(35)

	SET @no = 'Нет'
	SET @yes = 'Да'

	--set @objname='occupations'-- 'compensac'

	SELECT
		@objid = ID
	   ,@sysobj_type = xtype
	FROM sysobjects
	WHERE ID = OBJECT_ID(@objname)
	--select @objid, @sysobj_type

	-- DISPLAY COLUMN IF TABLE / VIEW
	IF @sysobj_type IN ('S ', 'U ', 'V ', 'TF', 'IF')
	BEGIN

		-- SET UP NUMERIC TYPES: THESE WILL HAVE NON-BLANK PREC/SCALE
		DECLARE @numtypes NVARCHAR(80)
		SELECT
			@numtypes = N'tinyint,smallint,decimal,int,real,money,float,numeric'

		CREATE TABLE #column1
		(
			p1 SYSNAME
		   ,p2 SYSNAME
		   ,p3 SYSNAME
		   ,p4 SQL_VARIANT
		)

		INSERT INTO #column1
			SELECT
				*
			FROM ::fn_listextendedproperty
			(NULL, 'user', 'dbo', 'table', @objname, 'column', NULL)

		-- INFO FOR EACH COLUMN
		SELECT
			NAME AS 'Column_name'
		   ,TYPE_NAME(xusertype) AS 'Type'
		   ,CASE
				WHEN iscomputed = 0 THEN @no
				ELSE @yes
			END AS 'Computed'
		   ,CONVERT(INT, Length) AS 'Length'
		   ,CASE
				WHEN dbo.strpos(TYPE_NAME(xtype), @numtypes) > 0 THEN CONVERT(CHAR(5), COLUMNPROPERTY(ID, NAME, 'precision'))
				ELSE '     '
			END AS 'Prec'
		   ,CASE
				WHEN dbo.strpos(TYPE_NAME(xtype), @numtypes) > 0 THEN CONVERT(CHAR(5), OdbcScale(xtype, xscale))
				ELSE '     '
			END AS 'Scale'
		   ,CASE
				WHEN isnullable = 0 THEN @no
				ELSE @yes
			END AS 'Nullable'
		   ,CASE COLUMNPROPERTY(@objid, NAME, 'UsesAnsiTrim')
				WHEN 1 THEN @no
				WHEN 0 THEN @yes
				ELSE '(n/a)'
			END AS 'TrimTrailingBlanks'
		   ,CASE
				WHEN TYPE_NAME(xtype) NOT IN ('varbinary', 'varchar', 'binary', 'char') THEN '(n/a)'
				WHEN STATUS & 0x20 = 0 THEN @no
				ELSE @yes
			END AS 'FixedLenNullInSource'
		   ,Collation AS 'Collation'
		   ,CASE
				WHEN colstat & 1 = 1 THEN 'Да'
				ELSE 'Нет'
			END AS 'Identity'
		   ,IDENT_SEED(@objname) AS 'Seed'
		   ,IDENT_INCR(@objname) AS 'Increment'
		   ,COLUMNPROPERTY(@objid, NAME, 'IsIDNotForRepl') AS 'Not For Replication'
		   ,col.p4 AS 'Descriptions'
		FROM syscolumns AS sc
		LEFT OUTER JOIN #column1 AS col
			ON sc.NAME = col.p2
		WHERE ID = @objid
		AND number = 0
		ORDER BY colid


	END
go

