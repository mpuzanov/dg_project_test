CREATE   PROCEDURE [dbo].[adm_mail_send]
(
	@fin_id SMALLINT = NULL
   ,@tip_id SMALLINT
)
AS
	--
	--  Рассылаем информацию по почте заинтересованным людям
	--
	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE @str_db_name VARCHAR(10)

	SELECT
		@str_db_name = DB_NAME()

	IF @fin_id IS NULL
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DECLARE @str_email NVARCHAR(4000)
	SET @str_email = ''

	SELECT
		@str_email = @str_email + u.email + ';'
	FROM dbo.USERS AS u
	JOIN dbo.GROUP_MEMBERSHIP AS g
		ON u.Id = g.user_id
	WHERE g.group_id = 'адмн'
	AND u.email <> ''
	IF LEN(@str_email) <> 0
		SET @str_email = SUBSTRING(@str_email, 1, LEN(@str_email) - 1)
	--select @str_email

	DECLARE @tableHTML NVARCHAR(MAX);

	DECLARE @t1 TABLE
		(
			P1 VARCHAR(20)
		   ,P2 VARCHAR(20)
		   ,P3 VARCHAR(50)
		)

	INSERT @t1
	EXECUTE dbo.adm_info_show @fin_id1 = @fin_id
							 ,@tip_id1 = @tip_id

	SET @tableHTML =
	N'<H3>Сводная информация по базе: ' + @str_db_name + '</H3>' +
	N'<table border="1">' +
	N'<tr><th>Описание</th><th>Значение</th></tr>' +
	CAST((SELECT
			td = P3
		   ,''
		   ,td = P2
		   ,''
		FROM @t1
		FOR XML PATH ('tr'), TYPE)
	AS NVARCHAR(MAX)) +
	N'</table>';

	SET @tableHTML = @tableHTML + N'Дата: ' + CONVERT(CHAR(14), current_timestamp, 106) + '<br>'

	--select @tableHTML

	EXEC msdb.dbo.sp_send_dbmail @recipients = @str_email
								, --'admin@gzu.idz.ru', 
								 @subject = 'Сводная информация по базе'
								,@body = @tableHTML
								,@body_format = 'HTML';
go

