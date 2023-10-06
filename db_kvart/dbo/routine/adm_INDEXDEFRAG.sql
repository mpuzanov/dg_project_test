CREATE   PROCEDURE [dbo].[adm_INDEXDEFRAG]
AS
	/*
	Use DBCC SHOWCONTIG and DBCC INDEXDEFRAG to defragment the indexes in a database
	*/

	-- Ensure a USE <databasename> statement has been executed first.
	SET NOCOUNT ON;
			
	DECLARE @objectid INT;
	DECLARE @indexid INT;
	DECLARE @partitioncount BIGINT;
	DECLARE @schemaname NVARCHAR(130);
	DECLARE @objectname NVARCHAR(130);
	DECLARE @indexname NVARCHAR(130);
	DECLARE @partitionnum BIGINT;
	DECLARE @partitions BIGINT;
	DECLARE @frag FLOAT;
	DECLARE @command NVARCHAR(4000);
	DECLARE @msg NVARCHAR(4000);
	DECLARE @date1 DATETIME
	
	SELECT
		@date1 = current_timestamp
		,@msg = 'Начинаем в ' + CONVERT(VARCHAR(25), @date1, 108)
	RAISERROR (@msg, 10, 1) WITH NOWAIT;
	
	DECLARE partitions CURSOR FOR
		SELECT
			t.object_id AS objectid
			,t.index_id AS indexid
			,partition_number AS partitionnum
			,avg_fragmentation_in_percent AS frag
			,QUOTENAME(s.Name) AS schemaname
			,QUOTENAME(o.Name) AS objectname	
			,QUOTENAME(i.Name) AS indexname
		FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') as t
			JOIN sys.objects AS o ON o.object_id = t.object_id
			JOIN sys.schemas AS s ON s.schema_id = o.schema_id
			JOIN sys.indexes as i ON i.object_id = t.object_id AND t.index_id = i.index_id
		WHERE avg_fragmentation_in_percent > 10.0
		AND t.index_id > 0;

	-- Open the cursor.
	OPEN PARTITIONS;

	-- Loop through the partitions.
	WHILE (1 = 1)
	BEGIN;
		FETCH NEXT
		FROM PARTITIONS
		INTO @objectid, @indexid, @partitionnum, @frag, @schemaname, @objectname, @indexname;
		IF @@fetch_status < 0
			BREAK;
								
		SELECT
			@partitioncount = COUNT(*)
		FROM sys.partitions as p
		WHERE p.object_id = @objectid
		AND index_id = @indexid;

		 --30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
		IF @frag < 30.0
			SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
		IF @frag >= 30.0
			SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
		IF @partitioncount > 1
			SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS NVARCHAR(10));		

		SET @command='SET QUOTED_IDENTIFIER ON '+CHAR(13)+CHAR(10)+@command
		SET @msg=N'Executed: ' + @command;
		RAISERROR (@msg, 10, 1) WITH NOWAIT;	
		EXEC (@command);
		
		-- Если процедура выполняется более 1 часа прерываем
		IF DATEDIFF(HOUR, @date1, current_timestamp) > 1
		BEGIN
			BREAK
		END
		
	END;

	-- Close and deallocate the cursor.
	CLOSE PARTITIONS;
	DEALLOCATE PARTITIONS;
go

