CREATE   PROCEDURE [dbo].[rep_olap_counter_alert]
(
	  @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
)
/*
Выдаём подозрительные показания ПУ

автор:		    Пузанов
дата создания:
дата изменеия:	
автор изменеия:	

используется в:	аналитике

exec rep_olap_counter_alert @tip_id1=NULL,@fin_id1=228,@fin_id2=228, @build_id1=null
exec rep_olap_counter_alert @tip_id1=1,@fin_id1=233,@fin_id2=233, @build_id1=null
*/
AS

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)

	IF @fin_id1 IS NOT NULL
		AND @fin_id2 IS NULL
		SELECT @fin_id2 = @fin_id1

	SELECT o.start_date AS 'Период'
		 , cp.StrFinPeriod AS 'Фин.Период'
		 , o.tip_name AS 'Тип фонда'
		 , s1.name AS 'Услуга'
		 , CONCAT(s.name , ' д.' , b.nom_dom) AS 'Адрес дома'
		 , s.name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , f.nom_kvr AS 'Квартира'
		 , ci.Occ AS 'Лицевой'
		 , c.id AS 'Код ПУ'		 
		 , c.serial_number AS 'Серийный номер'
		 , ci.inspector_value AS 'Значение'
		 , ci.inspector_date AS 'Дата значения'
		 , ci.actual_value AS 'Расход'
		 , ci.kol_day AS 'Дней'
		 , ci.value_vday AS 'Расход в день'
		 , ci.tarif AS 'Тариф'
		 , ci.value_paym AS 'Начислено'
		 , ci.comments AS 'Комментарий'
		 , ci.date_edit AS 'Дата редактирования'
		 , ci.warning AS 'Предупреждение'
		 , c.max_value AS 'Макс значение ПУ'
		 , c.count_value AS 'Начальное значение ПУ'
		 , c.date_create AS 'Дата утановки ПУ'
		 , c.PeriodCheck AS 'Период поверки'	 
		 , c.date_del AS 'Дата закрытия'
		 , CASE
			   WHEN c.date_del IS NOT NULL THEN 'Да'
			   ELSE 'Нет'
		   END AS 'Закрыт'
		 , CASE ci.metod_input
			   WHEN 1 THEN 'ручной'
			   WHEN 2 THEN 'из файла'
			   WHEN 3 THEN 'мобильный'
		   END AS 'Метод ввода'
		 , c.id_pu_gis AS '№ ПУ в ГИС ЖКХ'
		 , CONCAT(s.name, b.nom_dom_sort) AS sort_dom
		 , b.nom_dom_sort
		 , f.nom_kvr_sort
		 , c.counter_uid AS 'УИД счётчика'
	FROM dbo.View_counter_inspector AS ci 
		JOIN dbo.Counters AS c ON 
			ci.counter_id = c.id
		JOIN dbo.Flats AS f ON 
			c.flat_id = f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id = b.id
		JOIN dbo.VStreets AS s ON 
			b.street_id = s.id
		JOIN dbo.Services s1 ON 
			s1.id = c.service_id
		JOIN dbo.Calendar_period cp ON 
			ci.fin_id = cp.fin_id
		JOIN dbo.View_occ_all_lite AS o ON 
			ci.Occ = o.Occ
			AND ci.fin_id = o.fin_id
		LEFT JOIN (SELECT *	FROM dbo.Fun_GetCounterServValueLimits()) t_max ON 
			ci.service_id = t_max.service_id
	WHERE (ci.fin_id BETWEEN @fin_id1 AND @fin_id2)
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR b.id = @build_id1)
		AND o.total_sq > 0		
		AND (ci.warning = 'ALERT' OR ci.value_vday >= t_max.alert_value_vday OR ci.actual_value >= t_max.alert_value_month OR ci.actual_value < 0
		)
	OPTION (RECOMPILE)
go

