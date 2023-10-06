CREATE PROC [dbo].[adm_DOG_BUILDUpdate] 
    @dog_int int,
    @fin_id smallint,
    @build_id int
AS 
	SET NOCOUNT ON 
	SET XACT_ABORT ON  
	
	BEGIN TRAN

	UPDATE [dbo].[DOG_BUILD]
	SET    [dog_int] = @dog_int, [fin_id] = @fin_id, [build_id] = @build_id
	WHERE  [dog_int] = @dog_int
	       AND [fin_id] = @fin_id
	       AND [build_id] = @build_id
	
	-- Begin Return Select <- do not remove
	SELECT [dog_int], [fin_id], [build_id]
	FROM   [dbo].[DOG_BUILD]
	WHERE  [dog_int] = @dog_int
	       AND [fin_id] = @fin_id
	       AND [build_id] = @build_id	
	-- End Return Select <- do not remove

	COMMIT
go

