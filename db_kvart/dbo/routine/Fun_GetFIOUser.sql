CREATE   FUNCTION [dbo].[Fun_GetFIOUser]
(
	@user_id1 SMALLINT
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
		WHERE id = @user_id1)
	, '')
END
go

