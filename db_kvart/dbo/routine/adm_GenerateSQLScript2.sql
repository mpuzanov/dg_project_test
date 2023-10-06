CREATE   PROCEDURE [dbo].[adm_GenerateSQLScript2]
(
	@DirStr	 VARCHAR(70) = 'c:' -- без слеша
   ,@noname	 VARCHAR(30) = 'rep%' -- искючить из обработки
   ,@noname2 VARCHAR(30) = ''  -- искючить из обработки
)
AS
	/* 
	
	adm_GenerateSQLScript2 'E:\'
	
	------ складывает скрипты 
	-- bcp.exe и bcp.rll
	-- надо скопировать в SYSTEM32
	
	*/
	SET NOCOUNT ON

	DECLARE @SPName		  VARCHAR(255)
		   ,@PString	  VARCHAR(4000)
		   ,@Ptr		  BINARY(16)
		   ,@Return		  VARCHAR(2)
		   ,@Query		  VARCHAR(255)
		   ,@user1		  VARCHAR(15)
		   ,@pswd1		  VARCHAR(15)
		   ,@server_name1 VARCHAR(15)
		   ,@type1		  CHAR(2)

	SET @Query = CONCAT('\SP2_' , CONVERT(VARCHAR(10), current_timestamp, 126) , '.sql') ;

	SET @Return = '' --CHAR(13)+CHAR(10)

	DROP TABLE IF EXISTS #systable;
	CREATE TABLE #systable
	(
		name_obj  VARCHAR(100) COLLATE database_default
	   ,name_obj2 VARCHAR(100) COLLATE database_default
	   ,type	  CHAR(2)
	   ,uid		  SMALLINT
	)

	INSERT INTO #systable
		SELECT
			concat(s2.name , '.' , s1.name) AS tablename
		   ,s1.name
		   ,s1.type
		   ,s1.uid
		FROM sysobjects AS s1
			JOIN sysusers AS s2 
				ON s1.uid = s2.uid		

	--select * from #systable

	IF OBJECT_ID('SP_Script') IS NULL
		CREATE TABLE SP_Script
		(
			IDRow INT IDENTITY PRIMARY KEY CLUSTERED
		   ,_Text VARCHAR(512) COLLATE database_default
		)

	GRANT SELECT ON SP_Script TO PUBLIC

	DELETE FROM SP_Script

	DECLARE Run CURSOR FOR
		SELECT
			name_obj2
		   ,type
		FROM #systable
		WHERE ((type = 'P')
			OR (type = 'FN'))
			AND name_obj2 NOT LIKE @noname --'rep%'
			AND name_obj2 NOT LIKE @noname2 --'b_%'
		ORDER BY name_obj2

	INSERT INTO SP_Script
	(_Text)
	VALUES ('/**************************************************')
	INSERT INTO SP_Script
	(_Text)
	VALUES ('')
	INSERT INTO SP_Script
	(_Text)
	VALUES ('Сгенерированный скипт хранимых процедур и функций')
	INSERT INTO SP_Script
	(_Text)
	VALUES ('')
	INSERT INTO SP_Script
	(_Text)
	VALUES ('***************************************************/')
	INSERT INTO SP_Script
	(_Text)
	VALUES ('')

	OPEN Run
	FETCH NEXT FROM Run INTO @SPName, @type1
	WHILE @@fetch_status = 0
	BEGIN


		INSERT INTO SP_Script
		(_Text)
		VALUES ('SET QUOTED_IDENTIFIER OFF SET ANSI_NULLS ON ' + @Return)
		INSERT INTO SP_Script
		(_Text)
		VALUES ('GO' + @Return)
		INSERT INTO SP_Script
		(_Text)
		VALUES ('SET QUOTED_IDENTIFIER OFF SET ANSI_NULLS ON ' + @Return)
		INSERT INTO SP_Script
		(_Text)
		VALUES ('GO' + @Return)

		IF @type1 = 'P'
			INSERT INTO SP_Script
			(_Text)
			VALUES ('DROP PROCEDURE ' + @SPName + @Return)
		IF @type1 = 'FN'
			INSERT INTO SP_Script
			(_Text)
			VALUES ('DROP FUNCTION ' + @SPName + @Return)

		INSERT INTO SP_Script
		(_Text)
		VALUES ('GO' + @Return)

		INSERT INTO SP_Script
		EXEC sp_helptext @SPName

		INSERT INTO SP_Script
		(_Text)
		VALUES ('GO')

		FETCH NEXT FROM Run INTO @SPName, @type1
	END

	CLOSE Run
	DEALLOCATE Run

	UPDATE SP_Script
	SET _Text = REPLACE(_Text, CHAR(10), '')
	UPDATE SP_Script
	SET _Text = REPLACE(_Text, CHAR(13), '')


	SELECT TOP 1
		@user1 = u.login
	   ,@pswd1 = u.pswd
	FROM dbo.Users AS u
		JOIN Group_membership AS g
			ON u.id = g.user_id
	WHERE 1=1
	AND g.group_id = 'адмн'
	AND u.pswd <> ''

	--SELECT _Text FROM dbo.SP_Script ORDER BY IDRow 

	SET @Query = 'bcp.exe "SELECT _Text FROM dbo.SP_Script ORDER BY IDRow" queryout ' + @DirStr + @Query

	SET @Query = @Query + ' -c -CRAW -T -S' + @@servername
	SET @Query = @Query + ' -d' + UPPER(DB_NAME())
	PRINT @Query

	EXEC master.dbo.xp_cmdshell @Query --, no_output

	DROP TABLE IF EXISTS SP_Script;
go

