CREATE   PROCEDURE [dbo].[k_currentuser]
AS
	/*
		--  Выдаем параметры текущего пользователя
	*/
	SET NOCOUNT ON
	DECLARE @Rejim VARCHAR(10)

	SELECT
		@Rejim = dbo.Fun_GetRejim()

	IF @Rejim IS NULL
		SET @Rejim = 'стоп'

	SELECT
		Initials AS user_name
		,login
		,SUBSTRING(@@servername, 1, 10) AS ServerName
		,@Rejim AS RejimBasa
	FROM dbo.USERS 
	WHERE login = system_user
go

