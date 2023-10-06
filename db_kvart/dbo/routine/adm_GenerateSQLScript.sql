CREATE   PROCEDURE [dbo].[adm_GenerateSQLScript]
(
	@DirStr		VARCHAR(100)	= 'c:' -- без слеша
	,@FileName	VARCHAR(50)		= NULL
)
AS
/*
adm_GenerateSQLScript 'd:\','sqript_day'

	------ складывает скрипты 
	-- bcp.exe и bcp.rll
	-- надо скопировать в SYSTEM32
*/
	SET NOCOUNT ON

	DECLARE	@SPName			VARCHAR(255)
			,@PString		VARCHAR(4000)
			,@Ptr			BINARY(16)
			,@Return		VARCHAR(2)
			,@D_Day			VARCHAR(2)
			,@D_Month		VARCHAR(2)
			,@D_Year		VARCHAR(4)
			,@Query			VARCHAR(255)
			,@user1			VARCHAR(15)
			,@pswd1			VARCHAR(15)
			,@server_name1	VARCHAR(15)
			,@type1			CHAR(2)
			,@Db_Name VARCHAR(20) = UPPER(DB_NAME())

	IF @FileName IS NULL
		SET @Query = CONCAT('\SP1_' , CONVERT(VARCHAR(10), current_timestamp, 126) , '.sql')	
	ELSE
		SET @Query = CONCAT('\' , LTRIM(RTRIM(@FileName)) , '.sql')

	SET @Return = CHAR(13)+CHAR(10)


	DROP TABLE IF EXISTS #systable;
	CREATE TABLE #systable
	(
		name_obj	VARCHAR(100) COLLATE database_default
		,name_obj2	VARCHAR(100) COLLATE database_default
		,type		CHAR(2)
		,uid		SMALLINT
	)

	INSERT INTO #systable
			SELECT
				CONCAT(s2.name , '.' , s1.name) AS tablename
				,s1.name
				,s1.type
				,s1.uid
			FROM sysobjects AS s1
			JOIN sysusers AS s2 ON s1.uid = s2.uid			

	--select * from #systable
	--RETURN

	DROP TABLE IF EXISTS SP_Script;
	CREATE TABLE SP_Script
	(
		IDRow	INT	IDENTITY PRIMARY KEY CLUSTERED
		,_Text	NVARCHAR(1024) COLLATE database_default
	);

	GRANT SELECT ON SP_Script TO PUBLIC;
	DELETE FROM SP_Script;

	DECLARE Run CURSOR FOR
		SELECT
			name_obj2
			,[type]
		FROM #systable
		WHERE [type] in ('P','FN')   -- V-View, TR-triger, 'TT'
		ORDER BY uid DESC, name_obj2

	INSERT INTO SP_Script(_Text)
	VALUES ('/************************************************')
	--INSERT INTO SP_Script(_Text)VALUES ('')
	
	INSERT INTO SP_Script(_Text)
	VALUES ('Сгенерированный скипт хранимых процедур и функций')
	--INSERT INTO SP_Script(_Text)VALUES ('')
	
	INSERT INTO SP_Script(_Text)
	VALUES ('**************************************************/')
	--INSERT INTO SP_Script(_Text)VALUES ('')

	OPEN Run
	FETCH NEXT FROM Run INTO @SPName, @type1
	WHILE @@fetch_status = 0
	BEGIN

		INSERT INTO SP_Script(_Text) VALUES ('SET ANSI_NULLS ON ' + @Return)		
		INSERT INTO SP_Script(_Text) VALUES ('GO' + @Return)
		INSERT INTO SP_Script(_Text) VALUES ('SET QUOTED_IDENTIFIER ON ' + @Return)
		INSERT INTO SP_Script(_Text) VALUES ('GO' + @Return)		

		IF @type1 = 'P'
			INSERT INTO SP_Script
			(_Text)
			VALUES ('DROP PROCEDURE IF EXISTS ' + @SPName + @Return)
		IF @type1 = 'FN'
			INSERT INTO SP_Script
			(_Text)
			VALUES ('DROP FUNCTION IF EXISTS ' + @SPName + @Return)

		INSERT INTO SP_Script(_Text)
		VALUES ('GO' + @Return)

		INSERT INTO SP_Script
		EXEC sp_helptext @SPName
		
		--select definition from sys.sql_modules where object_id=object_id('kr1.dbo.AccessGisOper')
		
		-- REPLACE ASCII "NUL" character (0x0) -> ""

		INSERT INTO SP_Script
		(_Text)
		VALUES ('GO'+ @Return)

		PRINT @SPName

		FETCH NEXT FROM Run INTO @SPName, @type1
	END

	CLOSE Run
	DEALLOCATE Run

	UPDATE SP_Script SET _Text = REPLACE(_Text, CHAR(10), '')
	UPDATE SP_Script SET _Text = REPLACE(_Text, CHAR(13), '')
	UPDATE SP_Script SET _Text = REPLACE(_Text, CHAR(0), '')

	SELECT TOP (1)
		@user1 = u.login
		,@pswd1 = u.pswd
	FROM dbo.Users AS u
	JOIN dbo.Group_membership AS g
		ON u.id = g.user_id
	WHERE g.group_id = 'адмн'
	AND u.pswd <> '';

	--SELECT _Text FROM dbo.SP_Script ORDER BY IDRow

	--SET @Query = 'bcp.exe "SELECT _Text FROM dbo.SP_Script ORDER BY IDRow" queryout ' + @DirStr + @Query + ' -k -c -C65001 -T -S' + @@servername
	SET @Query = 'bcp.exe "SELECT _Text FROM dbo.SP_Script ORDER BY IDRow" queryout ' + @DirStr + @Query + ' -k -c -C1251 -T -S' + @@servername
	SET @Query = @Query + ' -d' + @Db_Name

	--SET @Query = @Query + ' -S ' + @server_name1 + ' -U ' + @user1 + ' -P ' + @pswd1 -C1251

	RAISERROR (@Query, 10, 1) WITH NOWAIT;

	EXEC master..xp_cmdshell @Query
								
	--EXEC master.dbo.xp_cmdshell	@Query, no_output

	DROP TABLE IF EXISTS SP_Script;
go

