CREATE   PROCEDURE [dbo].[adm_del_source]
(
	@source_id1 INT
)
AS

	SET NOCOUNT ON

BEGIN TRY

	IF (NOT EXISTS (SELECT
				*
			FROM dbo.CONSMODES_LIST 
			WHERE source_id = @source_id1)
		)
		AND (NOT EXISTS (SELECT
				*
			FROM dbo.CONSMODES_HISTORY 
			WHERE source_id = @source_id1)
		)
	BEGIN	
		BEGIN TRAN
		
		DELETE FROM dbo.BUILD_SOURCE
		WHERE source_id = @source_id1

		DELETE FROM dbo.SUPPLIERS
		WHERE id = @source_id1

		COMMIT TRAN
	END
	ELSE
		RAISERROR ('Этот поставщик используется! Его удалить нельзя!', 16, 10)

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
END CATCH;
go

