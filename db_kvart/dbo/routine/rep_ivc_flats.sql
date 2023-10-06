-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	
-- =============================================
CREATE               PROCEDURE [dbo].[rep_ivc_flats]
(
	  @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*

rep_ivc_flats @tip_id=1, @build_id=Null
rep_ivc_flats @tip_id=Null, @build_id=1031, @format='xml'
rep_ivc_flats @tip_id=Null, @build_id=1031, @format='json'

*/
BEGIN
	SET NOCOUNT ON;


	SELECT CAST(b.build_uid AS VARCHAR(36)) AS UID_Doma
		 , CAST(f.flat_uid AS VARCHAR(36)) AS UID_Pomesheniya
		 , nom_kvr AS Nomer_Pomesheniya
		 , approach AS Podezs
		 , CASE
			   WHEN (f.is_flat = 0) OR
				   (f.is_unpopulated = 1) THEN 'Нежилое'
			   ELSE 'Жилое'
		   END AS Naznachenie
		 , CASE
			   WHEN (f.is_flat = 0) OR
				   (f.is_unpopulated = 1) THEN 'Нежилое'
			   ELSE 'Квартира'
		   END AS Tip
		 , COALESCE(f.[floor], 0) AS Etag
		 , COALESCE(f.rooms, 0) AS Kolichestvo_komnat
		 , b.kod_fias AS fias_code
		 , f.id AS flat_id
	INTO #t
	FROM dbo.Flats f 
		JOIN Buildings AS b 
			ON b.id = f.bldn_id
	WHERE 1=1
		AND (@tip_id IS NULL OR tip_id = @tip_id)
		AND (@build_id IS NULL OR bldn_id = @build_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
	ORDER BY bldn_id
		   , nom_kvr_sort


	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t
	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('pomeshenie'), ELEMENTS, ROOT ('pomesheniya')
			) AS result
	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('pomesheniya')
			) AS result

DROP TABLE IF EXISTS #t;

/*
<pomesheniya>
	<pomeshenie>
		<UID_Doma>5289bd5a-f14d-11e3-9b2a-1c6f65e34def</UID_Doma>
		<UID_Pomesheniya>d0eb6e44-0c59-11ea-8035-902b341af037</UID_Pomesheniya>
		<Nomer_Pomesheniya>36</Nomer_Pomesheniya>
		<Podezs/>
		<Etag/>
		<Naznachenie>Нежилое</Naznachenie>
		<Tip>Квартира</Tip>
		<Kolichestvo_komnat/>
	</pomeshenie>
</pomesheniya>
*/

END
go

