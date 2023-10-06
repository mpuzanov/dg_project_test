CREATE   FUNCTION [dbo].[Fun_GetFIOLoginUser]
(
	@login1 VARCHAR(30)
)
RETURNS VARCHAR(35)
AS
/*
  Возвращаем инициалы пользователя
*/
BEGIN
	RETURN COALESCE((SELECT
			u.Initials
		FROM dbo.Users AS u
		WHERE u.login = @login1)
	, '')
END
go

exec sp_addextendedproperty 'MS_Description', N'Возвращаем инициалы пользователя по логину', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetFIOLoginUser'
go

