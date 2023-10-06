-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	
-- =============================================
CREATE           PROCEDURE [dbo].[rep_ivc_counter]
(
	  @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @format VARCHAR(10) = NULL
	, @is_only_paym BIT = NULL
)
AS
/*
rep_ivc_counter
rep_ivc_counter @tip_id=1
rep_ivc_counter @tip_id=28, @build_id=1031
*/
BEGIN
	SET NOCOUNT ON;


	SELECT
		CAST(c.counter_uid AS VARCHAR(36)) AS UID_Shetchika
	  , CAST(C.date_create AS DATE) AS Data_ustanovki
	  , '' AS Naimenovanie
	  , C.[type] AS Marka_Model
	  , CASE
			WHEN C.PeriodCheck > current_timestamp THEN 'VERIFIED'
			ELSE ''
		END AS Sostoyanei_poverki   --
	  , CAST(C.PeriodCheck AS DATE) AS Data_sled_poverki
	  , C.serial_number AS Nomer_pribora
	  , '' AS Dostup_k_peredache_pokazanii  --ALLOW
	  , '' AS Prichina_zapreta_peredachi_pokazanii
	  , CASE
            WHEN C.date_del IS NULL THEN 'WORKING'
            ELSE 'NOT_WORKING'
        END AS Sostoyanie
	  , CASE
			WHEN C.service_id IN ('хвод') THEN 'COLD'
			WHEN C.service_id IN ('гвод') THEN 'НОТ'
			WHEN C.service_id IN ('элек') THEN 'ELECTRICITY'
			WHEN C.service_id IN ('отоп') THEN 'HEAT'
			ELSE '?'
		END AS Tip_resursa
	  , CAST(f.flat_uid AS VARCHAR(36)) AS UID_Pomesheniya
	INTO #t
	FROM dbo.Counters AS C
		JOIN dbo.Flats f ON C.flat_id = f.Id
		JOIN dbo.Buildings b ON f.bldn_id = b.Id
	WHERE 1=1
		AND (@build_id IS NULL OR b.Id = @build_id)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
		AND NOT EXISTS (
				SELECT 1 FROM [dbo].[Fun_GetTableBlockedExportPu](b.tip_id, b.id, c.service_id)
			)
	ORDER BY b.street_id
		   , b.nom_dom_sort
		   , F.nom_kvr_sort


	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('shetchik'), ELEMENTS, ROOT ('shetchiki')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('shetchiki')
			) AS result

DROP TABLE IF EXISTS #t;

/*
<shetchiki>
	<shetchik>
		<UID_Pomesheniya>c8abe0ac-9189-11e9-85ff-902b341af037</UID_Pomesheniya>
		<UID_Shetchika>045c3fb4-0b5a-11ea-8035-902b341af037</UID_Shetchika>
		<Data_ustanovki>01.06.2019</Data_ustanovki>
		<Naimenovanie>ГВС 50-10</Naimenovanie>
		<Marka_Model>_"</Marka_Model>
		<Sostoyanei_poverki>VERIFIED</Sostoyanei_poverki>
		<Data_sled_poverki>01.01.2021</Data_sled_poverki>
		<Nomer_pribora>26334936</Nomer_pribora>
		<Dostup_k_peredache_pokazanii>ALLOW</Dostup_k_peredache_pokazanii>
		<Prichina_zapreta_peredachi_pokazanii/>
		<Sostoyanie>WORKING</Sostoyanie>
		<Tip_resursa>HOT</Tip_resursa>
	</shetchik>
</shetchiki>
*/

END
go

