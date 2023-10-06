CREATE   PROCEDURE [dbo].[adm_bank_del]
(
	@id1 INT
)
AS
/*
	Удаление организации(банка) перечисляющие платежи
*/
SET NOCOUNT ON

IF EXISTS (SELECT
			1
		FROM PAYDOC_PACKS AS pd
			JOIN PAYCOLL_ORGS AS po ON pd.source_id = po.id
			JOIN BANK AS b ON po.BANK = b.id
		WHERE b.id = @id1)
BEGIN
	RAISERROR ('Удалить организацию нельзя! Используется в платежах.', 16, 1)
	RETURN 1
END

BEGIN TRY

	DELETE FROM dbo.Bank
	WHERE id = @id1

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

