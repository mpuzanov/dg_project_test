CREATE   PROCEDURE [dbo].[adm_del_modes]
(
	@mode_id1 INT
)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

BEGIN TRY

	IF (NOT EXISTS (SELECT
				1
			FROM dbo.Consmodes_list
			WHERE mode_id = @mode_id1)
		)
		AND (NOT EXISTS (SELECT
				1
			FROM dbo.Consmodes_history 
			WHERE mode_id = @mode_id1)
		)
	BEGIN
		BEGIN TRAN

		DELETE FROM dbo.Build_mode
		WHERE mode_id = @mode_id1

		DELETE FROM dbo.Measurement_units
		WHERE mode_id = @mode_id1

		DELETE FROM dbo.Cons_modes
		WHERE id = @mode_id1

		COMMIT TRAN
	END
	ELSE
		RAISERROR ('Этот режим потребления используется! Его удалить нельзя!', 16, 10)

END TRY  
BEGIN CATCH  
    SELECT  
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage;  

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;

	THROW;
END CATCH
go

