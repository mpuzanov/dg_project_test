CREATE   PROCEDURE [dbo].[k_GetErrorInfo]
(
	  @visible BIT = 0 -- показать ошибку (выдать select)
	, @strerror VARCHAR(4000) = '' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	/*
    DECLARE @debug BIT=1, @strerror VARCHAR(4000)='Проверка!!!'
    EXECUTE k_GetErrorInfo @visible=@debug, @strerror=@strerror OUT
	RAISERROR (@strerror, 16, 1)
    */

	IF @visible IS NULL
		SET @visible = 0
	IF @strerror IS NULL
		SET @strerror = ''

	DECLARE @error_msg NVARCHAR(4000) = ERROR_MESSAGE()
		  , @severity TINYINT = ERROR_SEVERITY()
		  , @state TINYINT = ERROR_STATE()
		  , @error_no INT = ERROR_NUMBER()
		  , @proc SYSNAME = ERROR_PROCEDURE()
		  , @line_no INT = ERROR_LINE()

	SELECT @strerror = CONCAT(N'<',@error_msg,'>,',CHAR(13),'База: ',DB_NAME(),', Процедура:',@proc,', Строка:',@line_no,', ',@strerror)

	IF @visible = 1
		SELECT DB_NAME() AS ErrorDb_Name
			 , @proc AS ErrorProcedure
			 , @line_no AS ErrorLine
			 , @error_msg AS ErrorMessage
			 , @error_no AS ErrorNumber
			 , @severity AS ErrorSeverity
			 , @state AS ErrorState
			 , @strerror AS ErrorMessageUser

	INSERT INTO Error_log ([db_name]
						 , [login]
						 , [ErrorProcedure]
						 , [Line]
						 , [Message]
						 , [number]
						 , [Severity]
						 , [State]
						 , MessageUser)
	VALUES(DB_NAME()
		 , SUSER_NAME()
		 , @proc
		 , @line_no
		 , @error_msg
		 , @error_no
		 , @severity
		 , @state
		 , @strerror)
END
go

