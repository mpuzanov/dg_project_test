CREATE   FUNCTION [dbo].[Fun_InitialsPeople]
(
	@owner_id1 INT
)
RETURNS VARCHAR(30)
AS
BEGIN
	/*
		инициалы любого человека
	*/

	RETURN (SELECT
			CONCAT(RTRIM(p.Last_name),' ',LEFT(p.First_name,1),'.',LEFT(p.Second_name,1),'.')
		FROM dbo.People as p
		WHERE id = @owner_id1)

END
go

