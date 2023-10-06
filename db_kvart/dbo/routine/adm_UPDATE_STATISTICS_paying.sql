CREATE   PROCEDURE [dbo].[adm_UPDATE_STATISTICS_paying]
AS
	/*
	exec adm_UPDATE_STATISTICS_paying
	*/
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @DateNow DATETIME
	SELECT
		@DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, current_timestamp))

	DECLARE cur CURSOR LOCAL READ_ONLY FORWARD_ONLY FOR
		SELECT
			'UPDATE STATISTICS [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] [' + s.name + '] ' +
			--'UPDATE STATISTICS [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] [' + s.name + '] WITH FULLSCAN' +
				CASE
					WHEN s.no_recompute = 1 THEN 'WITH NORECOMPUTE'
					ELSE ''
				END + ';'
		FROM sys.stats s 
		JOIN sys.objects o 
			ON s.[object_id] = o.[object_id]
		WHERE o.[type] IN ('U', 'V')
		AND o.is_ms_shipped = 0
		--AND coalesce(STATS_DATE(s.[object_id], s.stats_id), current_timestamp) <= @DateNow
		AND o.name in ('PAYINGS','BANK_DBF','PAYING_SERV','PAYDOC_PACKS')
	OPEN cur

	FETCH NEXT FROM cur INTO @SQL

	WHILE @@fetch_status = 0
	BEGIN
		RAISERROR (@SQL, 10, 1) WITH NOWAIT;

		EXEC sys.sp_executesql @SQL

		FETCH NEXT FROM cur INTO @SQL

	END

	CLOSE cur
	DEALLOCATE cur
go

