-- =============================================
-- Author:		Пузанов
-- Create date: 21.09.09
-- Description:	Процедура вывода ошибки
/*
 BEGIN TRY
	-- текст процедуры
 END TRY
 BEGIN CATCH
   EXEC dbo.k_err_messages
 END CATCH
 */
-- =============================================
CREATE     PROCEDURE [dbo].[k_err_messages]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @strerror VARCHAR(1000);

	SELECT
		@strerror = CONCAT('Ошибка: Сообщение=<', ERROR_MESSAGE(),'>, База: ', DB_NAME(),', Процедура:', ERROR_PROCEDURE(),', Строка:', ERROR_LINE() )

	--EXEC dbo.k_adderrors_card @descr1 = @strerror;

	INSERT INTO ERROR_LOG
	([Db_Name]
	,[login]
	,[ErrorProcedure]
	,[Line]
	,[Message]
	,[Number]
	,[Severity]
	,[State]
	,MessageUser)
	VALUES (DB_NAME()
		   ,SUSER_NAME()
		   ,ERROR_PROCEDURE()
		   ,ERROR_LINE()
		   ,ERROR_MESSAGE()
		   ,ERROR_NUMBER()
		   ,ERROR_SEVERITY()
		   ,ERROR_STATE()
		   ,@strerror)

	RAISERROR (@strerror, 16, 1);
END
go

