CREATE   PROCEDURE [dbo].[adm_bank_add]
(
	@short_name1 VARCHAR(30)
   ,@bank_id_out INT = 0 OUTPUT
)
AS
/*	
	 Добавляем банк или организацию которые перечисляют нам платежи
*/	
	SET NOCOUNT ON

	DECLARE @id1 INT

	IF EXISTS (SELECT
				*
			FROM dbo.BANK)
		SELECT
			@id1 = MAX(id) + 1
		FROM dbo.BANK
	ELSE
		SET @id1 = 1

	BEGIN TRY
		INSERT INTO dbo.Bank
		(id
		,short_name
		,bank_uid)
		VALUES (@id1
			   ,@short_name1
			   ,dbo.fn_newid()
			   )

		SELECT
			@bank_id_out = @id1

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

