CREATE   FUNCTION [dbo].[Fun_GetFIOCurrentUser] ()
RETURNS VARCHAR(35)
AS
/*
  Возвращаем инициалы пользователя
*/
BEGIN
	RETURN COALESCE((SELECT
			u.Initials
		FROM dbo.USERS AS u
		WHERE login = system_user)
	, '')
END
go

exec sp_addextendedproperty 'MS_Description', N'Возвращаем инициалы пользователя', 'SCHEMA', 'dbo', 'FUNCTION',
     'Fun_GetFIOCurrentUser'
go

