CREATE   PROCEDURE [dbo].[adm_area_del]
(
	@user_id1  INT
   ,@group_id1 VARCHAR(10) = NULL
   ,@op_id1	   VARCHAR(10)
   ,@area_id1  INT
)

AS
	SET NOCOUNT ON

	IF @group_id1 IS NULL
		-- Находим группу пользователя с максимальными привелегиями
		SELECT
			@group_id1 = dbo.Fun_GetMaxGroupAccess(@user_id1)


	DELETE FROM dbo.ALLOWED_AREAS
	WHERE user_id = @user_id1
		AND group_id = @group_id1
		AND op_id = @op_id1
		AND area_id = @area_id1
go

