-- =============================================
-- Author:		Пузанов
-- Create date: 23.02.2013
-- Description:	Счётчики  или Аналитика - По ипу -проверка расчётов
-- =============================================
CREATE                     PROCEDURE [dbo].[rep_olap_counter2]
(
	@build	 INT	  = NULL
   ,@fin_id1 SMALLINT = NULL
   ,@fin_id2 SMALLINT = NULL
   ,@tip_id	 SMALLINT = NULL
)
AS
/*
exec rep_olap_counter2 NULL, 250,250,1
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
	CREATE TABLE #s
	(
		id	 VARCHAR(10) COLLATE database_default PRIMARY KEY
	   ,[name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #s(id,name)	SELECT id,name FROM dbo.View_SERVICES

	SELECT
		ot.start_date AS 'Период'
	   ,T.name AS 'Населенный пункт'
	   ,ot.name AS 'Тип фонда'
	   ,CONCAT(st.name , ' д.' , b.nom_dom) AS 'Адрес дома'
	   ,CONCAT(st.name , ' д.' , b.nom_dom , ' кв.' , F.nom_kvr) AS 'Адрес квартиры'
	   ,st.name AS 'Улица'
	   ,b.nom_dom AS 'Номер дома'
	   ,F.nom_kvr AS 'Квартира'
	   ,O.address AS 'Адрес'
	   ,p.Occ AS 'Лицевой'
	   --,s.name AS 'Услуга'
	   ,CASE WHEN(servt.service_name_full is NULL) THEN s.name ELSE servt.service_name_full END AS 'Услуга' -- заменяем наименования услуг по типам фонда
	   ,C.serial_number AS 'Серийный номер'
	   ,C.[type] AS 'Тип прибора'
	   ,C.unit_id AS 'Ед.измерения'
	   ,C.date_create AS 'Дата установки'
	   ,C.date_del AS 'Дата закрытия'
	   ,C.PeriodCheck AS 'Период поверки'
	   ,C.PeriodLastCheck AS 'Последняя поверка'
	   ,C.PeriodInterval AS 'Интервал поверки'
	   ,C.date_edit AS 'Дата редактирования'
	   ,C.max_value AS 'Разрядность'
	   ,CAST(O.TOTAL_SQ AS DECIMAL(9, 2)) AS 'Площадь'
	   ,C.count_value AS 'Нач.значение'
	   ,ci_pred.inspector_date AS 'Дата пред.значения'
	   ,ci_pred.inspector_value AS 'Пред.значение'
	   ,ci.inspector_date AS 'Дата посл.значения'
	   ,ci.inspector_value AS 'Послед.значение'
	   ,ci.actual_value AS 'Расход'
	   ,ci.value_vday AS 'Расход в день'
		--,dbo.Fun_Initials(p.occ) AS 'ФИО'
	   ,C.id AS 'Код счётчика'	   
	   ,F.id AS 'Код квартиры'
	   ,C.id AS 'Код дома'
	   ,CASE
			WHEN p.kol_occ <= 1 THEN 'Индивидуальный'
			ELSE 'Общий (квартирный)'
		END AS 'Вид ПУ'
	   ,b.id AS 'КодДома'
	   ,C.id_pu_gis AS 'Номер прибора учета в ГИС ЖКХ'
	   ,p.KolmesForPeriodCheck AS 'Кол.мес.до поверки'
	   ,CASE
			WHEN C.PeriodCheck < dbo.fn_end_month(ot.start_date) THEN 'Да'
			ELSE 'Нет'
		END AS 'Истёк срок поверки'
	   ,dbo.Fun_GetKolMonthCounterNo(p.Occ, p.service_id, p.fin_id) AS 'Кол_мес без показаний'
	   ,O.kol_people AS 'Кол_человек'
	   ,CONCAT(st.name, b.nom_dom_sort) AS sort_dom
	   ,b.nom_dom AS 'Дом'
	   ,b.nom_dom_sort
	   ,F.nom_kvr_sort
	   ,vp.metod_name AS 'Метод'
	   ,vp.tarif AS 'Тариф'
	   ,vp.value AS 'Начислено'
	   ,p.kol_occ AS 'Кол-во л/сч на ПУ'
	   ,p2.kol_PU AS 'Кол-во ПУ на л/сч'
	   ,p2.kol_PPU AS 'Кол-во ППУ на л/сч'
	   ,vp.kol AS 'Объём услуги'
	   ,vp.kol_norma_single AS 'Норматив'
	   ,CASE
			WHEN (ci.value_vday < 1) THEN 'Нет'
			WHEN C.service_id IN ('хвод', 'гвод') AND
			(ci.value_vday > 1) THEN 'Да'
			--WHEN c.service_id IN ('элек') AND (ci.value_vday>50) THEN 'Да'
			ELSE 'Нет'
		END AS 'Большой расход'
		,c.counter_uid AS 'УИД счётчика'
	FROM dbo.COUNTERS AS C
		JOIN dbo.FLATS AS F ON 
			F.id = C.flat_id
		JOIN #s AS s ON 
			C.service_id = s.id
		JOIN dbo.BUILDINGS AS b ON 
			C.build_id = b.id
		JOIN dbo.VSTREETS AS st ON 
			b.street_id = st.id
		JOIN dbo.TOWNS AS T	ON 
			b.town_id = T.id
		JOIN dbo.COUNTER_LIST_ALL AS p ON 
			p.counter_id = C.id
		JOIN dbo.OCCUPATIONS O ON 
			p.Occ = O.Occ
		JOIN dbo.VOCC_TYPES_ALL AS ot ON 
			O.tip_id = ot.id 
			and ot.fin_id=p.fin_id	
		LEFT JOIN dbo.View_PAYM vp ON 
			p.fin_id = vp.fin_id
			AND p.Occ = vp.Occ
			AND p.service_id = vp.service_id
		LEFT JOIN dbo.Services_types as servt ON 
			servt.service_id=s.id
			AND servt.tip_id = ot.id
		--OUTER APPLY [dbo].[Fun_GetCounterValue_last](p.counter_id, @fin_id2) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(p.counter_id, @fin_id2) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(p.counter_id, p.fin_id) AS ci_pred
		OUTER APPLY (SELECT
						COUNT(DISTINCT cla.counter_id) AS kol_PU
						,COUNT(DISTINCT ci.id) AS kol_PPU
					FROM dbo.Counter_list_all cla
					LEFT JOIN dbo.Counter_inspector ci ON 
						ci.counter_id = cla.counter_id
						AND cla.fin_id = ci.fin_id
					WHERE 
						cla.fin_id = vp.fin_id
						AND cla.Occ = vp.Occ
						AND cla.service_id = vp.service_id
					) AS p2
	WHERE 
		p.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@build IS NULL OR f.bldn_id = @build)
	OPTION (MAXDOP 1, RECOMPILE);

END
go

