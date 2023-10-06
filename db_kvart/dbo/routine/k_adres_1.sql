CREATE   PROCEDURE [dbo].[k_adres_1]
(
	@flat_id1 INT  --  код квартиры
   ,@occ1	  INT = NULL
)
AS
	/*
		Список лицевых в квартире
		exec  k_adres_1 10581
	*/
	SET NOCOUNT ON

	SELECT
		o.OCC
	   ,o.address
	   ,ROOMTYPE_ID
	   ,proptype_id
	   ,Total_sq
	   ,dbo.Fun_Initials(o.OCC) AS FIO
	   ,floor
	   ,o.ROOMS
	   ,o.status_id
	   ,o.tip_id
	   ,b.id AS build_id
	   ,t.name AS tipname
	   ,t.fin_id
	   ,o.kol_people
	   ,o.id_jku_gis
	FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.FLATS AS f 
			ON f.id = o.flat_id
		JOIN dbo.BUILDINGS AS b 
			ON b.id = f.bldn_id
		JOIN dbo.VOCC_TYPES AS t
			ON t.id = b.tip_id
	WHERE 1=1
		AND f.id = @flat_id1
		AND (@occ1 IS NULL OR o.OCC = @occ1)
go

