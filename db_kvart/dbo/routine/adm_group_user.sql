CREATE   PROCEDURE [dbo].[adm_group_user]
( 
	@group_id1 VARCHAR(10)
)
AS
/*
Показываем список пользователей по заданной группе
*/
SET NOCOUNT ON
 
SELECT u.*
FROM users as u
JOIN group_membership as g ON g.user_id=u.id
WHERE g.group_id=@group_id1
go

