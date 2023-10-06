CREATE   PROCEDURE [dbo].[k_adderrors_card]
(
	@descr1		VARCHAR(400)
   ,@officeinfo VARCHAR(200)   = NULL
   ,@ip			VARCHAR(15)	   = NULL
   ,@versia		VARCHAR(15)	   = NULL
   ,@file_error VARBINARY(MAX) = NULL -- Копия экрана
   ,@StackTrace VARCHAR(4000)  = NULL
)
AS
	/*
		Вставляем ошибку, которая произошла у пользователя в программе 
	*/
	SET NOCOUNT ON

	SET @descr1 = REPLACE(@descr1,'[Phys][ODBC][Microsoft]','')

	INSERT INTO dbo.ERRORS_CARD
	(data
	,[user_id]
	,app
	,descriptions
	,[host_name]
	,OfficeInfo
	,ip
	,versia
	,file_error
	,StackTrace)
	VALUES (current_timestamp
		   ,dbo.Fun_GetCurrentUserId()
		   ,SUBSTRING(dbo.fn_app_name(), 1, 25)
		   ,@descr1
		   ,SUBSTRING(HOST_NAME(), 1, 20)
		   ,@officeinfo
		   ,@ip
		   ,@versia
		   ,@file_error
		   ,@StackTrace)
go

