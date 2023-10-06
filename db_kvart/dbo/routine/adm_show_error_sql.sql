CREATE   PROCEDURE [dbo].[adm_show_error_sql]
(
	@day1 INT = 5 -- с начала дня (1-тек. день, 2-со вчерашнего дня)
)
AS
	/*
		
		Паказать ошибки за последние @day1 дней	
		берём из нескольких баз
		
		exec adm_show_error_sql 5
	*/

	SET NOCOUNT ON

	IF @day1 IS NULL
		SET @day1 = 1

	DECLARE DBNameCursor CURSOR LOCAL FOR
		SELECT
			name
		FROM (SELECT
				db.name
			FROM sys.databases AS db
			WHERE name IN ('kr1', 'naim', 'komp', 'kvart', 'komp_spdu')) AS t
		--WHERE t.access = 1
		ORDER BY t.name

	DECLARE @DBName NVARCHAR(128)
	DECLARE @cmd VARCHAR(4000)

	DROP TABLE IF EXISTS #TempResults;
	CREATE TABLE #TempResults
	(
		[ErrorDate]		 [DATETIME]		 NOT NULL
	   ,[Db_Name]		 [NVARCHAR](125) COLLATE database_default NULL
	   ,[Login]			 [VARCHAR](30)	 COLLATE database_default NULL
	   ,[ErrorProcedure] [VARCHAR](125)	 COLLATE database_default NULL
	   ,[Line]			 [INT]			 NULL
	   ,[Message]		 [VARCHAR](2048) COLLATE database_default NULL
	   ,[Number]		 [INT]			 NULL
	   ,[Severity]		 [INT]			 NULL
	   ,[State]			 [INT]			 NULL
	   ,[MessageUser]	 [VARCHAR](4000) COLLATE database_default NULL
	   ,
	)

	OPEN DBNameCursor;
	FETCH NEXT FROM DBNameCursor INTO @DBName
	WHILE @@fetch_status = 0
	BEGIN

		---------------------------------------------------- 
		--Print @DBName 

		SELECT
			@cmd = 'Use ' + @DBName + '; '
		SELECT
			@cmd = @cmd + ' Insert Into #TempResults 

	SELECT el.ErrorDate
	  ,el.Db_Name
	  ,el.Login
	  ,el.ErrorProcedure
	  ,el.Line
	  ,el.Message
	  ,el.Number
	  ,el.Severity
	  ,el.State
	  ,el.MessageUser
	FROM ERROR_LOG el
	WHERE el.ErrorDate BETWEEN DATEADD(DAY, -1*' + LTRIM(STR(@day1)) + '+1, CAST(current_timestamp AS date)) AND current_timestamp
'

		PRINT @cmd
		EXECUTE (@cmd)

		----------------------------------------------------- 

		FETCH NEXT FROM DBNameCursor INTO @DBName
	END
	CLOSE DBNameCursor;
	DEALLOCATE DBNameCursor;

	SELECT
		*
	FROM #TempResults
	ORDER BY ErrorDate DESC;

	DROP TABLE IF EXISTS tempdb..TempResults;
go

