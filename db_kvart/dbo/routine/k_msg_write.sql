-- =============================================
-- Author:		Пузанов
-- Create date: 26.05.2010
-- Description:	Посылка сообщения для пользователя
-- =============================================
CREATE   PROCEDURE [dbo].[k_msg_write]
(
	@to_login	  VARCHAR(30)
   ,@msg_text	  VARCHAR(500)
   ,@date_timeout SMALLDATETIME	 = NULL
   ,@to_ip		  VARCHAR(15)	 = NULL
   ,@from_ip	  VARCHAR(15)	 = NULL
   ,@to_developer BIT			 = 0
   ,@id_parent	  INT			 = NULL
   ,@FileName_msg VARCHAR(50)	 = NULL
   ,@file_msg	  VARBINARY(MAX) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @user_login VARCHAR(30) = system_user -- логин текущего пользователя
	DECLARE @app VARCHAR(30) = SUBSTRING(dbo.fn_app_name(), 1, 30)
	DECLARE @db_name VARCHAR(15) = SUBSTRING(DB_NAME(), 1, 15)

	IF @to_developer IS NULL
		SET @to_developer = 0

	IF @to_developer = 1
		SET @to_login = 'sa'

	INSERT INTO dbo.MESSAGES_USERS
	(to_login
	,date_msg
	,from_login
	,msg_text
	,receive
	,date_timeout
	,to_ip
	,from_ip
	,id_parent
	,FileName_msg
	,file_msg)
	VALUES (@to_login
		   ,current_timestamp
		   ,@user_login
		   ,@msg_text
		   ,NULL
		   ,@date_timeout
		   ,@to_ip
		   ,@from_ip
		   ,@id_parent
		   ,@FileName_msg
		   ,@file_msg)

	IF @to_developer = 1
	BEGIN
		-- Посылаем email разработчику
		DECLARE @msg	  VARCHAR(4000)
			   ,@Initials VARCHAR(50) = ''
		SELECT
			@Initials = Initials
		FROM dbo.USERS U
		WHERE login = @user_login
		SET @msg = @user_login + ', ' + COALESCE(@Initials, '') + ', ' + @app + ', ' + @from_ip + ', ' + @db_name + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @msg_text

		IF COALESCE(@FileName_msg, '') <> ''
			SET @msg = @msg + CHAR(13) + CHAR(10) + 'Есть вложенный файл(смотри в программе): ' + @FileName_msg

		EXEC dbo.k_send_email @recipients = 'puzanovma@yandex.ru'
							 ,@subject = 'Разработчику программы'
							 ,@body = @msg
	--msdb.dbo.sp_send_dbmail @recipients = 'puzanovma@yandex.ru', @subject = 'Разработчику программы', @importance = 'High', @body = @msg;
	END

END
go

