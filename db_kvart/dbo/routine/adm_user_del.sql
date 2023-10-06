CREATE   PROCEDURE [dbo].[adm_user_del]
(
	@user_id1 INT
)
AS
	SET NOCOUNT ON

BEGIN TRY

	DECLARE @er INT
	DECLARE @UserLogin VARCHAR(15)
	SELECT
		@UserLogin = login
	FROM USERS
	WHERE Id = @user_id1

	IF EXISTS (SELECT
				*
			FROM dbo.OP_LOG
			WHERE user_id = @user_id1)
	BEGIN
		RAISERROR ('Его удалять нельзя! Он есть в истории изменений', 16, 1)
		RETURN (1)
	END

	IF (@UserLogin = 'sa')
		OR (@UserLogin = 'dbo')
	BEGIN
		RAISERROR ('Его удалять нельзя!', 16, 1)
		RETURN (1)
	END

	IF @UserLogin IS NULL
	BEGIN
		RAISERROR ('Ошибка в Login пользователя', 16, 1)
		RETURN (1)
	END

	IF EXISTS (SELECT
				*
			FROM sys.database_principals
			WHERE name = @UserLogin)
	BEGIN
		EXEC @er = sp_dropuser @UserLogin
		IF @er != 0
		BEGIN
			RAISERROR ('Ошибка удаления User!', 16, 1)
			RETURN 1
		END
	END

	-- Ищем этого пользователя в других базах на сервере 
	-- если нет то удаляем
	DECLARE @UserExists		 BIT = 0
		   ,@db_name		 SYSNAME
		   ,@db_name_current SYSNAME
	SET @db_name_current = DB_NAME()

	DECLARE @cmd VARCHAR(2000)
	IF OBJECT_ID(N'#tbl', N'U') IS NOT NULL
		DROP TABLE #tbl;
	CREATE TABLE #tbl
	(
		name SYSNAME
	)

	DECLARE some_cur CURSOR LOCAL STATIC FOR
		SELECT
			name
		FROM (SELECT
				db.name
			 --  ,(SELECT
				--		HAS_PERMS_BY_NAME(db.name, 'database', 'ANY'))
				--AS access
			FROM sys.databases AS db
			WHERE name IN ('kr1', 'naim', 'komp', 'kvart')) AS t
		--WHERE t.access = 1
		ORDER BY t.name
	OPEN some_cur
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM some_cur INTO @db_name
		IF @@fetch_status <> 0
			BREAK

		SELECT
			@cmd = 'use [' + @db_name + '] select name from sys.database_principals where name=' + +QUOTENAME(@UserLogin, '''')
		INSERT INTO #tbl EXECUTE (@cmd)

		IF EXISTS (SELECT
					*
				FROM #tbl)
		BEGIN
			PRINT '  нашли в базе: ' + @db_name
			SET @UserExists = 1
			BREAK
		END

	END
	CLOSE some_cur
	DEALLOCATE some_cur

	IF @UserExists = 0
	BEGIN
		EXEC @er = sp_droplogin @UserLogin
		IF @er != 0
		BEGIN
			RAISERROR ('Ошибка удаления Login!', 16, 1)
			RETURN 1
		END
	END

	DELETE FROM USERS
	WHERE Id = @user_id1

	DELETE FROM GROUP_MEMBERSHIP
	WHERE user_id = @user_id1

END TRY

BEGIN CATCH
	
	THROW;

END CATCH
go

