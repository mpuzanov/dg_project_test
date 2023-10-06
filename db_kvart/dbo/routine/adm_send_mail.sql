CREATE   PROCEDURE [dbo].[adm_send_mail]
(
	@msg		  NVARCHAR(MAX)
   ,@profile_mail VARCHAR(20) = 'sql_mail'
   ,@debug		  BIT		  = 0
)
AS
	/*
	  Посылка почтовых сообщений группе  администраторов
	
	
	DECLARE @msg VARCHAR(MAX)
	SET @msg = 'База: ' + RTRIM(DB_NAME()) + ',Дата:' + CONVERT(CHAR(20), current_timestamp, 113) + CHAR(13) + CHAR(10)
	SELECT
		@msg = @msg + 'Тестирование отправки почты' + CHAR(13) + CHAR(10)
	
	print @msg
	EXEC dbo.adm_send_mail @msg=@msg, @debug=1
	
	*/

	SET NOCOUNT ON

	DECLARE @str_email NVARCHAR(4000) = ''
		   ,@subject1  VARCHAR(100) = 'SQL Server'
		   ,@POPServer VARCHAR(15)

	IF COALESCE(@profile_mail, '') = ''
		RAISERROR ('Профиль электронной почты не установлен!', 16, 10)

	SELECT TOP 1
		@POPServer = POPserver
	   ,@profile_mail = profile_mail
	FROM Global_values
	ORDER BY fin_id DESC -- последний период

	SELECT @str_email = STUFF((
		SELECT DISTINCT
			 CONCAT(';', u.email)
		FROM Users AS u
			JOIN Group_membership AS g
				ON u.id = g.user_id
		WHERE 
			g.group_id = 'адмн'
			AND u.email <> ''
			AND u.is_get_mail_service=1
			FOR XML PATH ('')
		), 1, 1, '')

	IF @debug = 1	
		PRINT concat('@profile_mail=', @profile_mail, ', @str_email=', @str_email, ', @subject1=', @subject1, ', @msg= ', @msg)	

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile_mail
								,@recipients = @str_email
								,@subject = @subject1
								,@body = @msg;
go

