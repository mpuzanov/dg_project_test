CREATE   PROCEDURE [dbo].[k_find_address_occ]
(
	@occ1 INT
)
AS
/*
Показываем адрес по лицевому счету

EXEC k_find_address_occ @occ1=31001

*/
	SET NOCOUNT ON

	SET @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

	IF EXISTS(SELECT 1 FROM dbo.Occupations WHERE occ=@occ1)
		SELECT
			o.occ
			,s.name as street_name
			,s.short_name
			,s.socr_name
			,s.name_socr
			,b.nom_dom
			,f.nom_kvr
			,o.[address]
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.VStreets AS s 
			ON b.street_id = s.id
		WHERE o.occ=@occ1
	ELSE
		SELECT
			os.occ_sup as occ
			,s.name as street_name
			,s.short_name
			,s.socr_name
			,s.name_socr
			,b.nom_dom
			,f.nom_kvr
			,o.[address]
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.VStreets AS s 
			ON b.street_id = s.id
		JOIN dbo.Occ_Suppliers as os 
			ON os.occ=o.Occ AND os.fin_id=b.fin_current
		WHERE os.occ_sup=@occ1
go

