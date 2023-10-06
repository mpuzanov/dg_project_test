-- =============================================
-- Author:		Пузанов
-- Create date: 23.02.2013
-- Description:	Счётчики
-- =============================================
CREATE                 PROCEDURE [dbo].[rep_olap_counter] 
( @build INT = NULL
, @fin_id1 SMALLINT = NULL
, @fin_id2 SMALLINT = NULL
, @tip_id SMALLINT = NULL)
AS
/*
exec rep_olap_counter null, 250,250,2
exec rep_olap_counter null, 230,230,1
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	-- для ограничения доступа услуг
	CREATE TABLE #s (
		id VARCHAR(10) COLLATE database_default PRIMARY KEY
	   ,[name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #s (id, name) SELECT id,name FROM dbo.View_services

	SELECT
		p.start_date AS 'Период'
	   ,b.town_name AS 'Населенный пункт'
	   ,p.tip_name AS 'Тип фонда'
	   ,sec.name AS 'Участок'
	   ,b.adres AS 'Адрес дома'
	   ,o.address AS 'Адрес квартиры'
	   ,b.street_name AS 'Улица'
	   ,b.nom_dom AS 'Номер дома'
	   ,b.nom_dom_without_korp AS '№ дома'
	   ,b.korp AS 'Корпус'
	   ,F.nom_kvr AS 'Квартира'
	   ,o.address AS 'Адрес'
	   ,p.Occ AS 'Единый_Лицевой'
	   ,dbo.Fun_GetFalseOccOut(p.Occ, p.tip_id) AS 'Лицевой'
	   ,CASE WHEN(COALESCE(servt.service_name_full, '') = '') THEN s.name ELSE servt.service_name_full END AS 'Услуга' -- заменяем наименования услуг по типам фонда
	   ,C.serial_number AS 'Серийный номер'
	   ,C.unit_id AS 'Ед.измерения'
	   ,C.date_create AS 'Дата установки'
	   ,C.date_del AS 'Дата закрытия'
	   ,C.PeriodCheck AS 'Период поверки'
	   ,C.PeriodLastCheck AS 'Последняя поверка'
	   ,C.PeriodInterval AS 'Интервал поверки'
	   ,C.date_edit AS 'Дата редактирования'
	   ,CAST(o.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
	   ,C.max_value AS 'Разрядность'
	   ,C.[type] AS 'Тип прибора'
	   ,C.count_value AS 'Нач.значение'
	   ,ci.inspector_date AS 'Дата посл.значения'
	   ,ci.inspector_value AS 'Послед.значение'
	   ,ci.actual_value AS 'Расход'
	   ,ci.value_vday AS 'Расход в день'
	   ,ci_pred.inspector_date AS 'Дата пред.значения'
	   ,ci_pred.inspector_value AS 'Пред.значение'
		--,dbo.Fun_Initials(p.occ) AS 'ФИО'
	   ,C.id AS 'Код счётчика'	   
	   ,p.flat_id AS 'Код квартиры'
	   ,p.bldn_id AS 'Код дома'
	   ,b.nom_dom AS 'Дом'
	   ,CASE WHEN(p.kol_occ <= 1) THEN 'Индивидуальный' ELSE 'Общий (квартирный)' END AS 'Вид ПУ'
	   ,p.bldn_id AS 'КодДома'
	   ,C.id_pu_gis AS '№ ПУ в ГИС ЖКХ'
	   ,p.KolmesForPeriodCheck AS 'Кол.мес.до поверки'
	   ,CASE
			WHEN C.PeriodCheck < dbo.fn_end_month(p.start_date) THEN 'Да'
			ELSE 'Нет'
		END AS 'Истёк срок поверки'
	   ,dbo.Fun_GetKolMonthCounterNo(p.Occ, p.service_id, p.fin_id) AS 'Кол_мес без показаний'
	   ,o.kol_people AS 'Кол_человек'
	   ,b.kod_fias AS 'Дом по ФИАС'
	   ,b.id_nom_dom_gis AS 'Код дома в ГИС ЖКХ'
	   ,CONCAT(b.street_name, b.nom_dom_sort) AS sort_dom
	   ,b.nom_dom_sort
	   ,F.nom_kvr_sort
	   ,CASE
			WHEN (ci.value_vday < 1) THEN 'Нет'
			WHEN C.service_id IN ('хвод', 'гвод') AND
				(ci.value_vday > 1) THEN 'Да'
			WHEN C.service_id IN ('элек') AND
				(ci.value_vday > 50) THEN 'Да'
			ELSE 'Нет'
		END AS 'Большой расход'
	   ,vp.Value AS 'Начислено'
	   ,vp.metod_name AS 'Метод'
	   ,CASE WHEN(COALESCE(vp.Value, 0) <> 0) THEN 'Да' ELSE 'Нет' END AS 'Есть начисления'
	   ,c.external_id AS 'Внешний код ПУ'
	   ,cl.lic_source as 'Внешний л/сч'
	   ,C.counter_uid AS 'УИД счётчика'
	FROM dbo.View_counter_all AS p
	JOIN dbo.Counters AS C
		ON p.counter_id = C.id
	JOIN dbo.Flats AS F
		ON F.id = p.flat_id
	JOIN #s AS s
		ON p.service_id = s.id
	JOIN dbo.View_buildings AS b
		ON p.bldn_id = b.id
	JOIN dbo.Occupations o 
		ON p.Occ = o.Occ
	LEFT JOIN dbo.Services_types AS servt 
		ON servt.service_id = s.id
			AND servt.tip_id = p.tip_id
	LEFT JOIN dbo.Sector sec 
		ON b.sector_id = sec.id
	LEFT JOIN dbo.Consmodes_list as cl ON 
		cl.occ=o.occ 
		and cl.service_id=c.service_id
	--OUTER APPLY [dbo].[Fun_GetCounterValue_last](p.counter_id, @fin_id2) AS ci
	OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(p.counter_id, @fin_id2) AS ci
	OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(p.counter_id, p.fin_id) AS ci_pred
	LEFT JOIN dbo.View_paym vp ON 
		p.fin_id = vp.fin_id
		AND p.Occ = vp.Occ	
		AND p.service_id = vp.service_id
	WHERE 
		p.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@build IS NULL OR p.bldn_id = @build)
		AND (@tip_id IS NULL OR p.tip_id = @tip_id)
	OPTION (RECOMPILE)
	--OPTION (MAXDOP 1, RECOMPILE);

END
go

