CREATE   PROCEDURE [dbo].[adm_showusers]
(
	@group_id1 VARCHAR(10) = NULL
)
AS
	/*
	Выдаем список пользователей в базе
			
	exec adm_showusers
	exec adm_showusers 'адмн'
	exec adm_showusers 'опер'
	exec adm_showusers 'стрш'
	exec adm_showusers 'оптч'
		
	*/
	SET NOCOUNT ON

	SELECT
		u.id
		,u.last_name
		,u.first_name
		,u.second_name
		,CAST(u.[login] AS VARCHAR(30)) AS login
		,CASE
				WHEN system_user IN ('sa') THEN pswd
				ELSE 'Мечтать не вредно'
			END AS pswd
		,u.comments
		,u.email
		,u.foto
		,u.Initials
		,u.blocked
		,u.blocked_personal
		,u.SuperAdmin
		,CAST(COALESCE(s.sysadmin,0) AS BIT) AS sysadmin
		,u.Only_sup
		,u.blocked_export
		,u.blocked_print
		,u.last_connect
		,dbo.Fun_GetMaxGroupAccess(u.id) AS group_max -- максимальная группа доступа
		,u.date_edit
		,u.user_edit
		,u.is_developer
		,u.is_get_mail_service
	FROM dbo.Users u
		LEFT JOIN sys.syslogins s ON 
			u.login=s.loginname
	WHERE
		@group_id1 IS NULL
		OR EXISTS (SELECT
				1
			FROM dbo.Group_membership gm 
			WHERE gm.user_id = u.id
			AND gm.group_id = @group_id1)
	ORDER BY last_name
go

