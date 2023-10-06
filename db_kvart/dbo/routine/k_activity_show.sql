CREATE   PROCEDURE [dbo].[k_activity_show]
AS
/*
  Показываем список пользователей в базе 
  (в течении последних 10 мин если прервалась связь)
  
  EXEC k_activity_show

  Ещё есть такой вариант (в Администраторе)
  EXEC adm_activity_user @DB_NAME=NULL
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @DataActivity DATETIME
	SET @DataActivity = DATEADD(MINUTE, -10, current_timestamp)

	SELECT
		u.id AS users_id
		,IPaddress
		,program
		,Initials AS FIO
		,CAST(u.login AS VARCHAR(30)) AS [login] 
		,u.comments
		,a.StrVer
		,a.comp
		,a.dir_program
	FROM dbo.ACTIVITY AS a 
	JOIN dbo.USERS AS u 
		ON a.SYSUSER = u.login
	WHERE a.DataActivity >= @DataActivity
	AND is_work = 1
	ORDER BY IPaddress

END
go

