-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Выгрузка показаний приборов учёта в ГИС ЖКХ
-- =============================================
CREATE           PROCEDURE [dbo].[rep_gis_pu_values]
(
	@tip_id				SMALLINT
	,@build_id			INT			= NULL
	,@sup_id			INT			= NULL
	,@fin_id			SMALLINT
	,@tip_counter_build	SMALLINT	= NULL  -- 1-только ОПУ, 2-только ИПУ, иначе все
)
AS
/*
exec rep_gis_pu_values 28,1031,323,176,1
exec rep_gis_pu_values 4,NULL,NULL,243,1
exec rep_gis_pu_values 1,NULL,NULL,243,3
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @period VARCHAR(8)

	IF @fin_id IS NULL
		SELECT
			@fin_id = [dbo].[Fun_GetFinCurrent](@tip_id, @build_id, NULL, NULL)
	
	SELECT @period=RIGHT(CONVERT(VARCHAR(10), start_date, 3),5) --'MM/yy'
	FROM dbo.Calendar_period 
	WHERE fin_id=@fin_id

	SELECT
		vb.adres
		,c.serial_number
		,f.nom_kvr
		,CASE c.service_id
			WHEN 'хвод' THEN 'Холодная вода'
			WHEN 'гвод' THEN 'Горячая вода'
			WHEN 'элек' THEN 'Электрическая энергия'
			WHEN 'пгаз' THEN 'Газ'
			WHEN 'отоп' THEN 'Тепловая энергия'
			ELSE c.service_id
		END AS VidService
		,ci.inspector_value AS T1
		,ci.actual_value AS actual_value
		,CASE
			WHEN c.is_build = 1 THEN 'Коллективный (общедомовой)'
			WHEN dbo.Fun_GetCounter_occ(c.id, @fin_id) > 1 THEN 'Общий (квартирный)'
			--WHEN c.is_build=0 THEN 'Индивидуальный'
			ELSE 'Индивидуальный'
		END AS VidPU
		,c.id_pu_gis AS id_pu_gis
		,c.is_build
		,ci.inspector_date
		,@period AS period
		,c.PeriodCheck
	FROM dbo.Counters c 
		JOIN dbo.View_buildings vb 
			ON c.build_id = vb.id
		LEFT JOIN dbo.Flats f
			ON c.flat_id = f.id
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(c.id, @fin_id) AS ci
	WHERE vb.tip_id = @tip_id
		AND (@build_id IS NULL OR c.build_id = @build_id)
		AND vb.is_paym_build=1
		AND ci.inspector_value IS NOT NULL
		AND c.id_pu_gis IS NOT NULL
		AND (c.id_pu_gis<>'')
		AND c.is_build =
			CASE
				WHEN @tip_counter_build = 1 THEN 1
				WHEN @tip_counter_build = 2 THEN 0
				ELSE c.is_build
			END
		AND c.date_del IS NULL
		AND (c.PeriodCheck IS NULL OR ci.inspector_date<c.PeriodCheck)
		AND NOT EXISTS (SELECT
				1
			FROM dbo.SERVICES_TYPE_COUNTERS stc 
			WHERE stc.tip_id = vb.tip_id
			AND stc.service_id = c.service_id
			AND stc.no_export_gis = 1)
		AND (@sup_id IS NULL
			OR (c.is_build = 1	AND @tip_counter_build <> 2)
			OR EXISTS (SELECT
				1
			FROM OCC_SUPPLIERS os 
			JOIN dbo.OCCUPATIONS o1 ON os.occ = o1.occ
			WHERE os.fin_id = vb.fin_current
				AND o1.flat_id = f.id
				AND os.sup_id = @sup_id
				AND c.is_build = 0)
		)
	ORDER BY vb.street_name, vb.nom_dom_sort, f.nom_kvr_sort
END
go

