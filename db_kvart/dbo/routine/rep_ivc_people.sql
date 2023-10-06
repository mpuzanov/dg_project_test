-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	информация по гражданам
-- =============================================
CREATE             PROCEDURE [dbo].[rep_ivc_people]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*
По гражданам

rep_ivc_people @fin_id=232, @tip_id=1, @build_id=null
rep_ivc_people @fin_id=232, @tip_id=1, @build_id=null, @format='xml'

*/
BEGIN
	SET NOCOUNT ON;


	IF @fin_id = 0
		OR @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	SELECT CAST(p2.people_uid AS VARCHAR(36)) AS UID_Zhitelya
		 , vpa.occ AS UID_LC
		 , CAST(f.flat_uid AS VARCHAR(36)) AS UID_Pomesheniya
		 , vpa.last_name AS Familiya
		 , vpa.first_name AS Imya
		 , vpa.second_name AS Otchestvo
		 , CAST(vpa.birthdate AS DATE) AS Data_rogdeniya
		 , p2.INN AS INN
		 , p2.SNILS AS SNILS
		 , I.DOC_NO AS Passport_number
		 , I.PASSSER_NO AS Passport_series
		 , i.kod_pvs AS Passport_code
		 , p2.Contact_info AS Phone
		 , p2.Email AS Email
	INTO #t
	FROM dbo.View_people_all vpa
		JOIN dbo.People AS p2 
			ON vpa.id = p2.id
		JOIN dbo.Person_statuses ps 
			ON ps.id = p2.status2_id
		JOIN dbo.View_occ_all AS o 
			ON vpa.occ = o.occ
			AND o.fin_id = vpa.fin_id
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS ba 
			ON o.bldn_id = ba.id
		LEFT JOIN dbo.Iddoc AS I 
			ON vpa.owner_id = I.owner_id
			AND I.active = 1
		LEFT JOIN dbo.Iddoc_types AS IT 
			ON I.DOCTYPE_ID = IT.id
	WHERE 1=1
		AND vpa.fin_id = @fin_id
		AND (@tip_id IS NULL OR o.tip_id = @tip_id)
		AND (@build_id IS NULL OR o.bldn_id = @build_id)
		AND o.status_id <> 'закр'
		AND p2.DateDel IS NULL
		AND ps.is_kolpeople = CAST(1 AS BIT)
		AND (@is_only_paym IS NULL OR ba.is_paym_build = @is_only_paym) 

	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('zhitel'), ELEMENTS, ROOT ('zhiteli')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('zhiteli')
			) AS result

DROP TABLE IF EXISTS #t;
/*
<zhiteli>
	<zhitel>
		<UID_Zhitelya>d30d4a25-fb0f-11e9-8cb9-902b341af037</UID_Zhitelya>
		<UID_LC>a77ad9e1-fb0f-11e9-8cb9-902b341af037</UID_LC>
		<LC_Nomer>350265090</LC_Nomer>
		<UID_Pomesheniya_propisan>c22a8734-fb0f-11e9-8cb9-902b341af037</UID_Pomesheniya_propisan>
		<UID_Pomesheniya_sobstvennik>c22a8734-fb0f-11e9-8cb9-902b341af037</UID_Pomesheniya_sobstvennik>
		<UID_Pomesheniya_progivaet>c22a8734-fb0f-11e9-8cb9-902b341af037</UID_Pomesheniya_progivaet>
		<Familiya>Брендюк</Familiya>
		<Imya>Татьяна</Imya>
		<Otchestvo>Валерьевна</Otchestvo>
		<Data_rogdeniya>08.08.1985</Data_rogdeniya>
		<INN/>
		<SNILS/>
		<Seriya_pasporta/>
		<Nomer_pasporta/>
		<Phone/>
		<Email/>
	</zhitel>
</zhiteli>
*/

END
go

