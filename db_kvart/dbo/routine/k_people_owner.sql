CREATE   PROCEDURE [dbo].[k_people_owner]
(
	  @owner1 INT
	, @new BIT
)
AS
	SET NOCOUNT ON

	SELECT 'new' = @new
		 , People.*
	FROM dbo.People 
	WHERE id = @owner1
go

