CREATE   PROCEDURE [dbo].[adm_show_error]
(
	@day1 INT = 1 -- с начала дня (1-тек. день, 2-со вчерашнего дня)
	,@debug BIT = 0
)
AS
/*
		
Показать ошибки пользователей за последние @day1 дней
берём из нескольких баз
		
exec adm_show_error 1

*/

	SET NOCOUNT ON

	IF @day1 IS NULL
		SET @day1 = 1

	DECLARE DBNameCursor CURSOR FOR
		SELECT
			[name]
		FROM (SELECT
				db.[name]
			 --  ,(SELECT
				--		HAS_PERMS_BY_NAME(db.name, 'database', 'ANY'))
				--AS access
			FROM sys.databases AS db
			WHERE [name] IN ('kr1', 'naim', 'komp', 'kvart', 'komp_spdu')) AS t
		--WHERE t.access = 1
		ORDER BY t.[name]

	DECLARE @DBName NVARCHAR(128)
	
	DECLARE @DateStart SMALLDATETIME = DATEADD(DAY, -1*@day1+1, CAST(current_timestamp AS date))
	DECLARE @DateEnd SMALLDATETIME = DATEADD(SECOND, -1, cast(floor(cast( current_timestamp as float)) + 1 as datetime))
	DECLARE @SQLString NVARCHAR(4000); 
	DECLARE @ParmDefinition NVARCHAR(500); 

	DROP TABLE IF EXISTS #TempResults;

	CREATE TABLE #TempResults
	(
		[Дата]			SMALLDATETIME
	   ,[Пользователь]  VARCHAR(50) COLLATE database_default
	   ,[Программа]		VARCHAR(30) COLLATE database_default
	   ,[Компьютер]		VARCHAR(30) COLLATE database_default
	   ,[Ошибка]		VARCHAR(400) COLLATE database_default
	   ,[Версия]		VARCHAR(15) COLLATE database_default
	   ,[IP адрес]		VARCHAR(15) COLLATE database_default
	   ,[Дополнительно] VARCHAR(400) COLLATE database_default
	   ,id				INT
	   ,file_error		VARBINARY(MAX)
	   ,file_error_true BIT
	   ,DBName			VARCHAR(30) COLLATE database_default
	   ,StackTrace		VARCHAR(8000) COLLATE database_default
	)

	OPEN DBNameCursor

	FETCH NEXT FROM DBNameCursor INTO @DBName
	WHILE @@fetch_status = 0
	BEGIN

		---------------------------------------------------- 
		--Print @DBName 

		SELECT
			@SQLString = 'Use ' + @DBName + '; '
		SELECT
			@SQLString = @SQLString + ' Insert Into #TempResults 
	SELECT
		er.data AS [Дата]
		,u.Initials AS [Пользователь]
		,SUBSTRING(RTRIM(er.APP), 1, 25) AS [Программа]
		,SUBSTRING(RTRIM(er.[host_name]), 1, 10) AS [Компьютер]
		,er.Descriptions AS [Ошибка]
		,er.versia AS [Версия]
		,er.ip AS [IP адрес]
		,er.OfficeInfo AS [Дополнительно]
		--,er.file_error
		,er.id
		,file_error= CAST(NULL AS VARBINARY(MAX))
		,file_error_true =
			CASE
				WHEN file_error IS NOT NULL THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END
		,DB_NAME() as DBName
		,StackTrace as StackTrace
	FROM dbo.ERRORS_CARD AS er 
	JOIN dbo.USERS AS u 
		ON er.user_id = u.id
	WHERE er.data BETWEEN @date1 AND @date2;
'

		IF @debug=1 PRINT @SQLString

		--EXECUTE (@SQLString)
		SET @ParmDefinition = N'@date1 SMALLDATETIME, @date2 SMALLDATETIME';

		EXECUTE sp_executesql @SQLString, @ParmDefinition, @date1 = @DateStart, @date2 = @DateEnd;

		----------------------------------------------------- 

		FETCH NEXT FROM DBNameCursor INTO @DBName
	END

	CLOSE DBNameCursor

	DEALLOCATE DBNameCursor

	SELECT
		*
	FROM #TempResults

	ORDER BY [Дата] DESC;

	DROP TABLE IF EXISTS tempdb..TempResults;
go

