CREATE   FUNCTION [dbo].[Fun_GetCurrentUserId] ()
RETURNS INT
AS
/*
  Возвращаем код текущего пользователя в базе
  SELECT @user_id=[dbo].[Fun_GetCurrentUserId]()
  SELECT [dbo].[Fun_GetCurrentUserId]()
*/
BEGIN
	DECLARE	@user_id1	INT	= CAST(SESSION_CONTEXT(N'User_ID') AS INT)

	IF @user_id1 IS NULL
		SELECT
			@user_id1 = id
		FROM dbo.USERS AS u
		WHERE login = system_user

	RETURN @user_id1
END
go

exec sp_addextendedproperty 'MS_Description', N'Возвращаем код текущего пользователя в базе', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetCurrentUserId'
go

