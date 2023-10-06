-- =============================================
-- Author:		Пузанов
-- Create date: 28/05/2015
-- Description:	Параметры домов для электронного паспорта
-- =============================================
CREATE     PROCEDURE [dbo].[rep_build_pasport1]
(
	@build_id	INT			= NULL
	,@tip_id	SMALLINT	= NULL
)
-- rep_build_pasport1 1047,null
AS
BEGIN
	SET NOCOUNT ON;


	IF @build_id IS NULL
		AND @tip_id IS NULL
		SELECT
			@build_id = 0

	SELECT
		CONCAT(CASE
			WHEN b.index_postal > 0 THEN CONCAT(CAST(b.index_postal AS VARCHAR(6)) , ',')
			ELSE ''
		END ,
		CONCAT(RTRIM(t.name) , ', ' , RTRIM(s.name) , ' ' , RTRIM(b.nom_dom))) AS adres_dom
		,tip_name = vt.name
		,town_name = t.name
		,b.*
		,CountFlats = (SELECT
				COUNT(DISTINCT t1.id)
			FROM dbo.FLATS AS t1
			WHERE t1.bldn_id = b.id)
		,CountLic = (SELECT
				COUNT(t2.occ)
			FROM dbo.View_OCC_ALL_LITE AS t2 
			WHERE t2.bldn_id = b.id
			AND t2.status_id <> 'закр'
			AND b.fin_current = t2.fin_id)
		,CountPeople = (SELECT
				SUM(t3.kol_people)
			FROM dbo.View_OCC_ALL_LITE t3 
			WHERE t3.bldn_id = b.id
			AND t3.status_id <> 'закр'
			AND b.fin_current = t3.fin_id)
		,CountLicPrivat = (SELECT
				COUNT(t.occ)
			FROM dbo.View_OCC_ALL_LITE AS t 
			WHERE t.bldn_id = b.id
			AND t.status_id <> 'закр'
			AND b.fin_current = t.fin_id
			AND t.PROPTYPE_ID <> 'непр')
		,CountLicNoPrivat = (SELECT
				COUNT(t.occ)
			FROM dbo.View_OCC_ALL_LITE AS t 
			WHERE t.bldn_id = b.id
			AND t.status_id <> 'закр'
			AND b.fin_current = t.fin_id
			AND t.PROPTYPE_ID = 'непр')

		,CountRooms1Otdk = (SELECT
				COUNT(o.occ)
			FROM dbo.OCCUPATIONS o 
			JOIN dbo.FLATS f 
				ON o.flat_id = f.id
			WHERE f.bldn_id = b.id
			AND o.status_id <> 'закр'
			AND COALESCE(o.rooms, 1) = 1
			AND o.ROOMTYPE_ID = 'отдк')
		,CountRooms2Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 2)
		,CountRooms3Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 3)
		,CountRooms4Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 4)
		,CountRooms5Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 5)
		,CountRooms6Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 6)
		,CountRooms7Otdk = dbo.Fun_GetKolRooms(b.id, 'отдк', 7)
		,CountRooms1komm = dbo.Fun_GetKolRooms(b.id, 'комм', 1)
		,CountRooms2komm = dbo.Fun_GetKolRooms(b.id, 'комм', 2)
		,CountRooms3komm = dbo.Fun_GetKolRooms(b.id, 'комм', 3)
		,CountRooms4komm = dbo.Fun_GetKolRooms(b.id, 'комм', 4)
		,CountRooms5komm = dbo.Fun_GetKolRooms(b.id, 'комм', 5)
		,CountRooms6komm = dbo.Fun_GetKolRooms(b.id, 'комм', 6)
		,CountRooms7komm = dbo.Fun_GetKolRooms(b.id, 'комм', 7)
	FROM dbo.BUILDINGS AS b 
	JOIN dbo.VSTREETS AS s 
		ON s.id = b.street_id
	JOIN dbo.VOCC_TYPES AS vt 
		ON vt.id = b.tip_id
	JOIN dbo.TOWNS t 
		ON b.town_id = t.id
	WHERE (b.tip_id = @tip_id OR @tip_id IS NULL)
	AND (b.id = @build_id OR @build_id IS NULL)
	ORDER BY s.name
	, b.nom_dom_sort


END
go

