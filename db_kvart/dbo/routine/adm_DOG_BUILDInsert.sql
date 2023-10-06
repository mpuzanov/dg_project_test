CREATE     PROC [dbo].[adm_DOG_BUILDInsert] 
    @dog_int INT,
    @fin_id SMALLINT,
    @str_build_id VARCHAR(8000)
AS 
	SET NOCOUNT ON 
	SET XACT_ABORT ON  
	
BEGIN TRY

	DECLARE @dog_id_name VARCHAR(20)
	SELECT @dog_id_name=dog_id FROM dbo.DOG_SUP WHERE id=@dog_int
	
	-- Таблица с новыми значениями 
	DECLARE @t1 TABLE(build_id INT)

	INSERT INTO @t1
	SELECT * FROM STRING_SPLIT (@str_build_id,';') WHERE RTRIM(value) <> ''; 

	BEGIN TRAN
	
		DELETE FROM [dbo].[DOG_BUILD] WHERE dog_int=@dog_int AND fin_id=@fin_id
				
		INSERT INTO [dbo].[DOG_BUILD] ([dog_int], [fin_id], [build_id])
		SELECT @dog_int, @fin_id, build_id FROM @t1
		
		-- Begin Return Select <- do not remove
		SELECT [dog_int], [fin_id], [build_id]
		FROM   [dbo].[DOG_BUILD]
		WHERE  [dog_int] = @dog_int
			   AND [fin_id] = @fin_id
	-- End Return Select <- do not remove
               
	COMMIT TRAN

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

