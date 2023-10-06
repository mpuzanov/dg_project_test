CREATE   VIEW [dbo].[accessGMPOper]
AS
SELECT
	A.area_id
	,A.group_id
FROM dbo.ALLOWED_AREAS AS A
INNER JOIN dbo.USERS AS U 
	ON A.user_id = U.id
INNER JOIN dbo.GROUP_MEMBERSHIP
	ON A.group_id = dbo.GROUP_MEMBERSHIP.group_id
	AND A.user_id = dbo.GROUP_MEMBERSHIP.user_id
WHERE (A.op_id = 'ггмп')
AND (U.login = system_user)
go

