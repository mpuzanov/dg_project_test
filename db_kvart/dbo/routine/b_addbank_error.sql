CREATE   PROCEDURE [dbo].[b_addbank_error]
(
	@error1 VARCHAR(200)
)
AS
	--
	--  Записываем ошибку
	--
	SET NOCOUNT ON

	INSERT INTO dbo.BANK_ERROR
	VALUES (current_timestamp
		   ,@error1)
go

