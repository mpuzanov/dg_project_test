CREATE   PROCEDURE [dbo].[rep_ivc_counter_value]
(
	  @fin_id SMALLINT
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @format VARCHAR(10) = NULL
	, @is_only_paym BIT = NULL
)
/*
Показания квартиросъемщика
при выгрузке должны отражаться показания последние учтенные в базе в месяце

exec rep_ivc_counter_value @fin_id=232, @tip_id=1, @build_id=null
exec rep_ivc_counter_value @fin_id=185, @tip_id=28, @build_id=null
exec rep_ivc_counter_value @fin_id=185, @tip_id=28, @build_id=1031, @format='xml'
exec rep_ivc_counter_value @fin_id=230, @tip_id=4, @build_id=6795, @format='xml'

select * FROM [dbo].[Fun_GetCounterValue_last](68836,230)

*/
AS

	SET NOCOUNT ON


	IF @fin_id IS NULL
		SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	DECLARE @period VARCHAR(7) --yyyy-MM
	
	SELECT @period=CONVERT(VARCHAR(7), cp.start_date, 126)  --yyyy-MM
	FROM dbo.Calendar_period cp
	WHERE cp.fin_id = @fin_id
	
	SELECT CAST(c.counter_uid AS VARCHAR(36)) AS UID_Shetchika
		 , @period AS Uchetnii_period
		 , 'BY_READINGS' AS Sposob_rascheta
		 , ci.inspector_value AS Pokazanie1
		 , 0 AS Pokazanie2
		 , CASE
			   WHEN c.unit_id IN ('кубм') THEN 'CBM'
			   WHEN c.unit_id IN ('квтч') THEN 'KILO_WATT_HOUR'
			   WHEN c.unit_id IN ('ггкл') THEN 'GIGA_CALORIE'
			   ELSE ''
		   END AS Ed_izm_pok1
		 , '' AS Ed_izm_pok2
		 , ci.inspector_date AS Date_otpravki
		 , c.id AS Сounter_id
	INTO #t
	FROM dbo.Counters AS c 
		JOIN dbo.View_build_all_lite AS b ON 
			c.build_id = b.build_id 
			AND b.fin_id=@fin_id
		OUTER APPLY dbo.Fun_GetCounterValue_last(c.id, @fin_id) AS ci
	WHERE 
		(@build_id IS NULL OR c.build_id = @build_id)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		--AND o.Total_sq > 0
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
		AND c.date_del IS NULL
		AND c.is_build=CAST(0 AS BIT) -- только показания ИПУ
	OPTION (RECOMPILE)

	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t
	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('pokazanie'), ELEMENTS, ROOT ('pokazaniya')
			) AS result
	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('pokazaniya')
			) AS result

DROP TABLE IF EXISTS #t;

/*
<pokazaniya>
	<pokazanie>
		<UID_Schetchika>fd133e51-f5f4-11e3-b1e7-1c6f65df4f58</UID_Schetchika>
		<Uchetnii_period>2019-07</Uchetnii_period>
		<Sposob_rascheta>BY_READINGS</Sposob_rascheta>
		<Pokazanie1>531</Pokazanie1>
		<Pokazanie2>581</Pokazanie2>
		<Ed_izm_pok1>DEFAULT</Ed_izm_pok1>
		<Ed_izm_pok2>DEFAULT</Ed_izm_pok2>
		<Date_otpravki>05.08.2020</Date_otpravki>
	</pokazanie>
</pokazaniya>
*/
go

