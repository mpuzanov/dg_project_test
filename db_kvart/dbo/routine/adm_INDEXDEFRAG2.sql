CREATE   PROCEDURE [dbo].[adm_INDEXDEFRAG2]
AS
	/*
	exec adm_INDEXDEFRAG2
	*/
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX)

	DECLARE cur CURSOR LOCAL READ_ONLY FORWARD_ONLY FOR
		SELECT
			'ALTER INDEX [' + i.name + N'] ON [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] ' +
				CASE					
					WHEN s.avg_fragmentation_in_percent > 10 
						AND dbo.strpos('ColumnStore',i.name)>0 THEN 'REORGANIZE'
					WHEN s.avg_fragmentation_in_percent > 10 THEN 'REBUILD WITH (SORT_IN_TEMPDB = ON)'											
					ELSE 'REORGANIZE'
				END + ';'
		FROM (SELECT
				s.[object_id]
				,s.index_id
				,MAX(s.avg_fragmentation_in_percent) AS avg_fragmentation_in_percent
			FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) s
			WHERE s.page_count > 128 -- > 1 MB
			AND s.index_id > 0 -- <> HEAP
			AND s.avg_fragmentation_in_percent > 3
			GROUP BY	s.[object_id]
						,s.index_id) s
		JOIN sys.indexes i
			ON s.[object_id] = i.[object_id]
			AND s.index_id = i.index_id
		JOIN sys.objects o
			ON o.[object_id] = s.[object_id]
		ORDER BY o.name

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

