-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE             PROCEDURE [dbo].[rep_gis_adres]
(
	@tip_id		SMALLINT	= NULL
   ,@build_id   INT			= NULL
   ,@occ		INT			= NULL
   ,@id_els_gis VARCHAR(15) = NULL
)
AS
BEGIN
/*
exec rep_gis_adres @tip_id=1	
exec rep_gis_adres @occ=680000138
exec rep_gis_adres @occ=85000398
exec rep_gis_adres @id_els_gis='40ЕТ107614'
EXEC rep_gis_adres @tip_id=225, @occ=334320
*/
SET NOCOUNT ON;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
	

	IF @DB_NAME <> 'NAIM'
		AND @tip_id IS NULL
		AND @build_id IS NULL
		AND @occ IS NULL
		AND @id_els_gis IS NULL
		SET @occ = 0

	SELECT * FROM (
	SELECT
		o.occ AS occ
	   ,dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ_false
	   ,o.id_els_gis
	   ,f.id_nom_gis
	   ,o.id_jku_gis
	   ,CONCAT(s.name , ' д.' , b.nom_dom) AS adres_build
	   ,CONCAT(s.name , ' д.' , b.nom_dom , ' кв.' , f.nom_kvr) AS address
	   ,ot.name AS tip_name
	   ,o.status_id
	   ,o.proptype_id
	   ,o.total_sq
	   ,o.Paid
	   ,s.Name as street_name, b.nom_dom_sort, f.nom_kvr_sort
	FROM dbo.Occupations o 
	JOIN dbo.Flats f 
		ON o.flat_id = f.id
	JOIN dbo.Buildings b 
		ON f.bldn_id = b.id
	JOIN dbo.Streets s
		ON b.street_id = s.id
	JOIN dbo.Occupation_Types AS ot
		ON o.tip_id = ot.id
	WHERE (o.occ = @occ	OR @occ IS NULL	OR o.schtl = @occ)
		AND (o.tip_id = @tip_id	OR @tip_id IS NULL)
		AND (@build_id IS NULL OR f.bldn_id = @build_id)
		AND (@id_els_gis IS NULL OR o.id_els_gis = @id_els_gis)
	UNION
	SELECT
		os.occ_sup AS occ
	   ,os.occ_sup AS occ_false
	   ,o.id_els_gis
	   ,f.id_nom_gis
	   ,os.id_jku_gis
	   ,CONCAT(s.name , ' д.' , b.nom_dom) AS adres_build
	   ,CONCAT(s.name , ' д.' , b.nom_dom , ' кв.' , f.nom_kvr) AS address
	   ,ot.name AS tip_name
	   ,o.status_id
	   ,o.proptype_id
	   ,o.total_sq
	   ,os.paid
	   ,s.Name as street_name,b.nom_dom_sort, f.nom_kvr_sort
	FROM dbo.Occ_Suppliers os
	JOIN dbo.Occupations o 
		ON os.occ = o.occ 
		and os.fin_id = o.fin_id
	JOIN dbo.Flats f 
		ON o.flat_id = f.id
	JOIN dbo.Buildings b 
		ON f.bldn_id = b.id
	JOIN dbo.Streets s 
		ON b.street_id = s.id
	JOIN dbo.Occupation_Types AS ot 
		ON o.tip_id = ot.id
	WHERE (@occ IS NULL OR os.occ_sup = @occ)
		AND (@tip_id IS NULL OR o.tip_id = @tip_id)
		AND (@build_id IS NULL OR f.bldn_id = @build_id)
		AND (@id_els_gis IS NULL OR o.id_els_gis = @id_els_gis)
		) as t
	--ORDER BY occ, street_name,nom_dom_sort,nom_kvr_sort
END
go

