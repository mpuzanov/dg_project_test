CREATE   PROCEDURE [dbo].[k_dsc_active]
(
	@id1 INT  -- код льготы
)
AS
/*
	Делаем льготу активной
*/
	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	SET NOCOUNT ON

	DECLARE @LgotaActive SMALLINT
		   ,@owner_id1	 INT
	SELECT
		@owner_id1 = owner_id
	   ,@LgotaActive = dscgroup_id
	FROM DSC_OWNERS 
	WHERE id = @id1

	IF @LgotaActive IS NULL
		UPDATE PEOPLE 
		SET lgota_id  = 0
		   ,lgota_kod = 0
		WHERE id = @owner_id1
		AND Del = 0

	IF EXISTS (SELECT
				1
			FROM dbo.Fun_SpisokLgotaActive(@owner_id1)
			WHERE id1 = @id1)
	BEGIN

		BEGIN TRAN

			UPDATE DSC_OWNERS 
			SET active = 0
			WHERE owner_id = @owner_id1
			UPDATE DSC_OWNERS 
			SET active = 1
			WHERE id = @id1

			UPDATE PEOPLE 
			SET lgota_id  = @LgotaActive
			   ,lgota_kod = @id1
			WHERE id = @owner_id1
			AND (lgota_id <> @LgotaActive
			OR lgota_kod <> @id1)

		COMMIT TRAN

	END
go

