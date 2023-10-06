CREATE   PROC [dbo].[adm_DOG_BUILDDelete] 
    @dog_int INT,
    @fin_id SMALLINT,
    @build_id INT
AS 
	SET NOCOUNT ON 
	

	DELETE
	FROM   dbo.DOG_BUILD
	WHERE  dog_int = @dog_int
	       AND fin_id = @fin_id
	       AND build_id = @build_id
go

