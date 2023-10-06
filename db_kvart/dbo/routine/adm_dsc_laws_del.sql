CREATE   PROCEDURE [dbo].[adm_dsc_laws_del]
(
	@id1 INT
)
AS
	--
	-- Удаление закона по льготам
	--
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM DSC_GROUPS
			WHERE law_id = @id1)
	BEGIN
		DELETE FROM DSC_LAWS
		WHERE id = @id1
	END
	ELSE
		RAISERROR ('Ошибка! Удалить закон нельзя так как он используется!', 16, 1)
go

