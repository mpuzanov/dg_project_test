CREATE   PROCEDURE [dbo].[k_Find_telephon]
(
	@telephon1 BIGINT
)
AS
/*
	Поиск адреса по номеру телефона
*/
	SET NOCOUNT ON

	SELECT
		STREETS = s.NAME
		,b.nom_dom
		,f.nom_kvr
		,o.occ
	FROM dbo.OCCUPATIONS AS o 
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.ID
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.ID
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.ID
	WHERE o.telephon = @telephon1
go

