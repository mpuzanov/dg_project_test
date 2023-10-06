CREATE   VIEW [dbo].[accessCessia]
AS
SELECT     a.area_id, group_id
FROM         dbo.ALLOWED_AREAS a INNER JOIN
                      dbo.USERS u ON a.user_id = u.id
WHERE     (a.op_id = 'цеся') AND (u.login = SYSTEM_USER)
go

