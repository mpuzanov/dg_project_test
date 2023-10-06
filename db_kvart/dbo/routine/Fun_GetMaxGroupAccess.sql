-- =============================================
-- Author:		Пузанов Михаил
-- Create date: 12.12.2013
-- Description:	Находим группу пользователя с максимальными привелегиями
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetMaxGroupAccess]
(
	@user_id INT
)
RETURNS VARCHAR(10) -- максимальная группа доступа
AS
/*
 select dbo.Fun_GetMaxGroupAccess(9)
 select dbo.Fun_GetMaxGroupAccess(5)
 */
BEGIN

	RETURN COALESCE((SELECT TOP (1)
			ug.group_id
		FROM dbo.GROUP_MEMBERSHIP AS gm 
		JOIN dbo.USER_GROUPS AS ug 
			ON ug.group_id = gm.group_id
		WHERE user_id = @user_id
		ORDER BY ug.group_no)
	, 'опер')

END
go

