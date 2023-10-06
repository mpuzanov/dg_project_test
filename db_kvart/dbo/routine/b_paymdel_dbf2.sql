CREATE   PROCEDURE [dbo].[b_paymdel_dbf2]
(
	@filedbf_id INT
)
AS
	--
	--  удаляем введенные платежи из заданного файла
	--
	SET NOCOUNT ON


	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF
			WHERE (filedbf_id = @filedbf_id)
			AND (pack_id IS NOT NULL))
	BEGIN
		RAISERROR ('Удалить нельзя! сформированы пачки из этих платежей!', 16, 1)
		RETURN 1
	END

	BEGIN TRAN

		DELETE FROM dbo.BANK_DBF
		WHERE (filedbf_id = @filedbf_id)
			AND (pack_id IS NULL)

		DELETE FROM dbo.BANK_TBL_SPISOK
		WHERE filedbf_id = @filedbf_id

	COMMIT TRAN
go

