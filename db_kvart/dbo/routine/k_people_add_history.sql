CREATE   PROCEDURE [dbo].[k_people_add_history]
(
	  @owner_id1 INT
)
AS
/*
Добавляем историю по человеку
*/
SET NOCOUNT ON

IF NOT EXISTS (
		SELECT 1
		FROM dbo.People_2 AS p2
		WHERE p2.owner_id = @owner_id1
	)
BEGIN
	INSERT INTO dbo.People_2 (owner_id)
	VALUES(@owner_id1)
END
go

