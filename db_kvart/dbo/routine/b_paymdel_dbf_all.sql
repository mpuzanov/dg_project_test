CREATE   PROCEDURE [dbo].[b_paymdel_dbf_all]
AS
	--
	--  удаляем все введенные электронные платежи (для тестирования)
	--
	SET NOCOUNT ON


	BEGIN TRAN

		DELETE FROM dbo.BANK_DBF
		WHERE (pack_id IS NULL) -- не закрытые

		DELETE FROM dbo.BANK_TBL_SPISOK
		WHERE forwarded = 0 -- не закрытые

	COMMIT TRAN
go

