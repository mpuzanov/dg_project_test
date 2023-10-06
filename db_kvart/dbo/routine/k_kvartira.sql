CREATE   PROCEDURE [dbo].[k_kvartira]
(
	@street_id1	INT
	,@nom_dom	VARCHAR(12)
)
AS

	SET NOCOUNT ON

	SELECT
		f.nom_kvr
		,f.id
	FROM dbo.BUILDINGS AS b 
	JOIN dbo.FLATS AS f
		ON b.id = f.bldn_id
	WHERE b.street_id = @street_id1
	AND b.nom_dom = @nom_dom
	ORDER BY f.nom_kvr_sort
go

