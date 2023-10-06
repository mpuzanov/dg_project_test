CREATE   PROCEDURE [dbo].[adm_area_add]
(
	@user_id1  INT
   ,@group_id1 VARCHAR(10) = NULL
   ,@op_id1	   VARCHAR(10)
   ,@area_id1  INT
)
AS
/*
	Добавляем доступ пользователу к заданному участку по виду работ
*/
	SET NOCOUNT ON

	IF @group_id1 IS NULL
		-- Находим группу пользователя с максимальными привелегиями
		SELECT
			@group_id1 = dbo.Fun_GetMaxGroupAccess(@user_id1)

	BEGIN TRY
		INSERT INTO dbo.ALLOWED_AREAS
		VALUES (@user_id1
			   ,@group_id1
			   ,@op_id1
			   ,@area_id1)
	END TRY
	BEGIN CATCH	
		EXEC dbo.k_err_messages
	END CATCH
go

