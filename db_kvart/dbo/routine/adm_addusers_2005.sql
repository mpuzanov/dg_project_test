-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 12.12.06
-- Description:	
-- =============================================
CREATE         PROCEDURE [dbo].[adm_addusers_2005]
(
	@login1		  SYSNAME
   ,@pswd1		  SYSNAME
   ,@last_name1	  VARCHAR(30)
   ,@first_name1  VARCHAR(30)
   ,@second_name1 VARCHAR(30)
   ,@comments1	  VARCHAR(50) = NULL
   ,@email1		  VARCHAR(50) = NULL
   ,@user_id	  SMALLINT	  = NULL OUTPUT  --  код пользавателя в бд
)
AS
	/*
	Добавление пользователя в базу

	exec dbo.adm_addusers_2005 @login1='test',@pswd1='123456',@last_name1='Тестовая',@first_name1='служебная',@second_name1='запись'
	exec dbo.adm_addusers_2005 @login1='repview',@pswd1='654321',@last_name1='Служебный',@first_name1='пользователь',@second_name1='для отчетов'
	
	*/
	SET NOCOUNT ON

	DECLARE @er INT
	DECLARE @exec_stmt NVARCHAR(4000)

	SELECT
		@login1 = RTRIM(LTRIM(@login1))
	SELECT
		@pswd1 = RTRIM(LTRIM(@pswd1))
	IF (@login1 = '')
		OR (@pswd1 = '')
	BEGIN
		RAISERROR ('Имя входа или пароль не могут быть пустыми', 16, 1)
		RETURN 1
	END

	SELECT
		@last_name1 = RTRIM(LTRIM(@last_name1))
	   ,@first_name1 = RTRIM(LTRIM(@first_name1))
	   ,@second_name1 = RTRIM(LTRIM(@second_name1))

	IF (@last_name1 = '')
		OR (@first_name1 = '')
		OR (@second_name1 = '')
	BEGIN
		RAISERROR ('Ф.И.О.  не могут быть пустыми', 16, 1)
		RETURN 1
	END

	DECLARE @db_name SYSNAME = DB_NAME(DB_ID())

	-- Проверяем есть ли такой логин на сервере 
	-- если нет создаем
	IF NOT EXISTS (SELECT
				*
			FROM sys.server_principals
			WHERE name = @login1)
	BEGIN
		-- print 'Добавляем Login'
		--EXEC @er=sp_addlogin @login1, @pswd1, @db_name

		SET @exec_stmt = 'create login ' + QUOTENAME(@login1) +
		' with password = ' + QUOTENAME(@pswd1, '''') +
		', default_database = ' + QUOTENAME(@db_name) +
		', CHECK_POLICY = OFF'
		--print @exec_stmt

		EXEC (@exec_stmt)

		IF @@error <> 0
		BEGIN
			RAISERROR ('Ошибка добавления Login - <%s>!', 16, 1, @login1)
			RETURN 1
		END

	END

	-- Проверяем есть ли такой пользователь в базе данных
	-- если нет создаем
	IF NOT EXISTS (SELECT
				*
			FROM sys.database_principals
			WHERE name = @login1)
	BEGIN
		EXEC @er = sp_grantdbaccess @login1
		IF @er != 0
		BEGIN
			RAISERROR ('Ошибка добавления User <%s>!', 16, 1, @login1)
			RETURN 1
		END
	END

	EXEC @er = sp_addrolemember 'oper', @login1
	IF @er != 0
	BEGIN
		RAISERROR ('Ошибка добавления User <%s> в группу!', 16, 1, @login1)
		RETURN 1
	END

	SELECT
		@user_id = id
	FROM dbo.Users
	WHERE login = @login1;

	IF @user_id IS NULL -- Пользователя нет в базе
	BEGIN

		DECLARE @key NVARCHAR(4000) = 'Пузанов Михаил Анатольевич'
		DECLARE @pswd_encrypt VARBINARY(128)
		SET @pswd_encrypt = ENCRYPTBYPASSPHRASE(@key, @pswd1)

		INSERT INTO dbo.Users
			(last_name
			,first_name
			,second_name
			,login
			,pswd
			,comments
			,email
			,pswd_encrypt
			,date_edit
			,user_edit)
		VALUES (@last_name1
			   ,@first_name1
			   ,@second_name1
			   ,@login1
			   ,@pswd1
			   ,@comments1
			   ,@email1
			   ,@pswd_encrypt
			   ,current_timestamp
			   ,(SELECT
						u.Initials
					FROM dbo.Users u
					WHERE u.login = system_user))
		IF @@error != 0
		BEGIN
			RAISERROR ('Ошибка добавления пользователя!', 16, 1)
			RETURN 1
		END
		SELECT
			@user_id = SCOPE_IDENTITY()

	END
go

