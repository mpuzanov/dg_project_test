-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	
-- =============================================
CREATE             PROCEDURE [dbo].[rep_ivc_buildings]
(
	  @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @format VARCHAR(10) = NULL
	, @is_only_paym BIT = NULL
)
AS
/*
exec rep_ivc_buildings @tip_id=1,@build_id=null,@format=null, @is_only_paym = 1
exec rep_ivc_buildings @tip_id=2,@build_id=null,@format='xml'
exec rep_ivc_buildings @tip_id=1,@build_id=null,@format='json'
exec rep_ivc_buildings @tip_id=4,@build_id=null,@format=''

*/
BEGIN
	SET NOCOUNT ON;


	SELECT CAST(b.build_uid AS VARCHAR(36)) AS UID_Doma
		 , t.name AS Gorod
		 , short_name AS Ulitsya   -- Сабурова  s.NAME = Сабурова ул.
		 , nom_dom AS Nomer_Doma
		 , '' AS Korpus
		 , 'Жилой' AS Tip_Doma
		 , b.kolpodezd AS Kolichestvo_podyezdov
		 , COALESCE(b.levels, 0) AS Kolichestvo_etagei
		 , b.build_total_sq AS Obshaya_Ploshad
		 , 0 AS Zhilaya_Ploshad
		 , 0 AS Komm_Ploshad
		 , b.kod_fias AS fias_code
		 , b.id AS build_id
		 , COALESCE((SELECT STUFF((
				SELECT ',' + LTRIM(STR(sup_id))
				FROM dbo.View_dog_build AS vdb
				WHERE vdb.build_id=b.id
				AND vdb.fin_id=ot.fin_id
				FOR XML PATH ('')), 1, 1, '')),'') AS suppliers-- коды поставщиков с отд.квит. через запятую
	INTO #t
	FROM dbo.Buildings AS b
		JOIN dbo.VStreets AS s ON 
			b.street_id = s.id
		JOIN dbo.Towns t ON 
			s.town_id = t.id
		JOIN dbo.Occupation_Types AS ot ON 
			b.tip_id = ot.id
	WHERE 
		(@tip_id IS NULL OR tip_id = @tip_id)
		AND (@build_id IS NULL OR b.id = @build_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
	ORDER BY s.name
		   , nom_dom_sort

	IF COALESCE(@format,'')='' OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('dom'), ELEMENTS, ROOT ('doma')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('doma')
			) AS result


DROP TABLE IF EXISTS #t;

/*

<doma>
	<dom>
		<UID_Doma>7523a64e-253f-11e9-966d-902b341af037</UID_Doma>
		<Gorod>Ижевск</Gorod>
		<Ulitsya>Пушкинская</Ulitsya>
		<Nomer_Doma>248</Nomer_Doma>
		<Korpus/>
		<Tip_Doma/>
		<Kolichestvo_podyezdov>0</Kolichestvo_podyezdov>
		<Kolichestvo_etagei>0</Kolichestvo_etagei>
		<Obshaya_Ploshad>0</Obshaya_Ploshad>
		<Zhilaya_Ploshad>0</Zhilaya_Ploshad>
		<Komm_Ploshad>0</Komm_Ploshad>
	</dom>
</doma>

*/

END
go

