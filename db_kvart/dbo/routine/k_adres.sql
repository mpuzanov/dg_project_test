CREATE   PROCEDURE [dbo].[k_adres]
(
	  @Street_id1 INT
	, @Nom_dom VARCHAR(12)
	, @Nom_kvr VARCHAR(20)
)
AS
/*
	Список лицевых в квартире

	exec k_adres 17, '289А','3'
*/
	SET NOCOUNT ON

	SELECT o.occ
		 , o.address
		 , roomtype_id
		 , proptype_id
		 , total_sq
		 , dbo.Fun_Initials(o.occ) AS FIO
		 , f.[floor]
		 , o.Rooms
		 , o.status_id
		 , o.tip_id
		 , b.id AS build_id
		 , t.Name AS tipname
		 , t.fin_id
		 , o.kol_people
		 , o.id_jku_gis
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f ON o.flat_id = f.id
		JOIN dbo.Buildings AS b  ON f.bldn_id = b.id
		JOIN dbo.VOcc_types AS t ON b.tip_id = t.id
	WHERE b.street_id = @Street_id1
		AND b.nom_dom = @Nom_dom
		AND f.nom_kvr = @Nom_kvr
go

