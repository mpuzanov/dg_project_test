CREATE   PROCEDURE [dbo].[adm_sizeTables]
AS
	--
	--  Показываем размеры таблиц
	--
	SET NOCOUNT ON

	DECLARE @sizTable TABLE
		(
			table_name	 SYSNAME
		   ,rows		 BIGINT
		   ,reservedKB	 BIGINT
		   ,dataKB		 BIGINT
		   ,index_sizeKB BIGINT
		   ,unusedKB	 BIGINT
		   ,compression	 VARCHAR(10)
		   ,procIndex	 AS (CASE
				WHEN dataKB = 0 THEN 0
				ELSE index_sizeKB * 100 / (dataKB)
			END)
		)

	DECLARE @pagesizeKB BIGINT = 8
	--SELECT
	--	@pagesizeKB = sv.low / 1024
	--FROM [master].dbo.spt_values AS sv
	--WHERE sv.number = 1
	--AND sv.type = 'E'

	INSERT INTO @sizTable
		SELECT
			OBJECT_NAME(o.id) AS table_name
		   ,COALESCE(i1.rowcnt, 0) AS [rows]
		   ,reservedKB = (COALESCE(SUM(i1.reserved), 0) + COALESCE(SUM(i2.reserved), 0)) * @pagesizeKB
		   ,dataKB = (COALESCE(SUM(i1.dpages), 0) + COALESCE(SUM(i2.used), 0)) * @pagesizeKB
		   ,index_sizeKB = ((COALESCE(SUM(i1.used), 0) + COALESCE(SUM(i2.used), 0))
			- (COALESCE(SUM(i1.dpages), 0) + COALESCE(SUM(i2.used), 0))) * @pagesizeKB
		   ,unusedKB = ((COALESCE(SUM(i1.reserved), 0) + COALESCE(SUM(i2.reserved), 0))
			- (COALESCE(SUM(i1.used), 0) + COALESCE(SUM(i2.used), 0))) * @pagesizeKB
		   ,CASE
				WHEN p.data_compression = 1 THEN 'ROW'
				WHEN p.data_compression = 2 THEN 'PAGE'
				ELSE '-'
			END AS [compression]
		FROM [sys].[sysobjects] o
		LEFT OUTER JOIN [sys].[sysindexes] i1
			ON i1.id = o.id
			AND i1.indid < 2
		LEFT OUTER JOIN [sys].[sysindexes] i2
			ON i2.id = o.id
			AND i2.indid = 255
		LEFT JOIN [sys].[partitions] AS p
			ON o.id = p.object_id
			AND p.index_id = 1
		WHERE OBJECTPROPERTY(o.id, N'IsUserTable') = 1 --same as: o.xtype = %af_src_str_2
		OR (OBJECTPROPERTY(o.id, N'IsView') = 1
		AND OBJECTPROPERTY(o.id, N'IsIndexed') = 1)

		GROUP BY o.id
				,i1.rowcnt
				,p.data_compression

	SELECT
		*
	   ,SUM(dataKB) OVER () AS 'dataKB_itog'
	FROM @sizTable
	ORDER BY reservedKB DESC
go

