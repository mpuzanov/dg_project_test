CREATE   PROCEDURE [dbo].[ka_ShowOcc_in_Dom]
(
	  @bldn_id1 INT
)
AS
	--
	--  Список лицевых по дому (для разовых)
	--
	SET NOCOUNT ON

	SELECT o.Occ
		 , f.nom_kvr
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f ON o.flat_id = f.id
	WHERE f.bldn_id = @bldn_id1
		AND o.status_id <> 'закр'
	ORDER BY f.nom_kvr_sort
go

