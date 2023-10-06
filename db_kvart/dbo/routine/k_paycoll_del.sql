CREATE   PROCEDURE [dbo].[k_paycoll_del]
(
	@id1 INT
)
AS
/*
	Удаление вида платежа по банку
	k_paycoll_del @id1=3445
*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF 	EXISTS (SELECT	1
				FROM dbo.Paydoc_packs 
				WHERE source_id = @id1)
	BEGIN
		RAISERROR ('Удалить нельзя! Так как вид платежа используется', 16, 1)
		RETURN -1
	END
	ELSE
		DELETE FROM dbo.PAYCOLL_ORGS
		WHERE id = @id1
go

