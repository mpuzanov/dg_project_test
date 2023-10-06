CREATE   PROCEDURE [dbo].[k_raschet_people]
(
	@occ1 INT
)
AS
/*

*/
	SET NOCOUNT ON

	SELECT
		CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') AS Initials
		,p.*
	FROM dbo.People_list_ras AS p --WITH (SNAPSHOT)
	JOIN dbo.People p1 ON p.owner_id=p1.id
	WHERE p.occ = @occ1
	ORDER BY service_id, p.owner_id
go

