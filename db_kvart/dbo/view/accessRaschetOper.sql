CREATE   VIEW [dbo].[accessRaschetOper]
AS
SELECT
	a.area_id
	,a.group_id
FROM dbo.ALLOWED_AREAS a 
INNER JOIN dbo.USERS u 
	ON a.user_id = u.id
WHERE (a.op_id = 'пере')
AND (u.login = system_user)
go

