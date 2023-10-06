CREATE PROC [dbo].[k_FileFTPDelete] 
    @id int
AS 
	SET NOCOUNT ON 
	SET XACT_ABORT ON  
	
	BEGIN TRAN

	DELETE
	FROM   [dbo].[FileFTP]
	WHERE  [id] = @id

	COMMIT
go

