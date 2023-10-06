CREATE   FUNCTION [dbo].[Fun_User_readonly] ()
RETURNS BIT
AS
BEGIN
/*  
Возвращаем Истину если у пользователя права только на чтение
*/

	IF EXISTS (SELECT
				1
			FROM dbo.Group_membership AS GM
			JOIN dbo.Users AS U
				ON GM.user_id = U.id
			WHERE GM.group_id = 'оптч'
			AND U.login = system_user)
	BEGIN
		-- У пользователя права только на чтение
		RETURN cast(1 as bit)
	END

	RETURN cast(0 as bit)

END
go

