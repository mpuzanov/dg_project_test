CREATE   PROCEDURE [dbo].[rep_olap_counter_insp2]
(
	  @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
)
/*
Показания квартиросъемщика без привязки к лицевым счетам

автор:		    Пузанов
дата создания:	27.04.21
дата изменеия:	
автор изменеия:	

используется в:	аналитике

exec rep_olap_counter_insp2 @tip_id1=2,@fin_id1=250,@fin_id2=250, @build_id1=null

*/
AS

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)

	IF @fin_id1 IS NOT NULL
		AND @fin_id2 IS NULL
		SELECT @fin_id2 = @fin_id1


	SELECT cp.start_date AS 'Период'
		 , cp.StrFinPeriod AS 'Фин.Период'
		 , b.tip_name AS 'Тип фонда'
		 , s1.name AS 'Услуга'
		 , b.adres AS 'Адрес дома'
		 , b.street_name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , f.nom_kvr AS 'Квартира'
		 , c.id AS 'Код ПУ'
		 , c.serial_number AS 'Серийный номер'
		 , CASE WHEN(c.is_build = CAST(1 AS BIT)) THEN 'Да' ELSE 'Нет' END AS 'ОДПУ'
		 , ci.inspector_value AS 'Показание'
		 , ci.inspector_date AS 'Дата показания'
		 , ci.actual_value AS 'Расход'
		 , ci.kol_day AS 'Дней'
		 , ci.value_vday AS 'Расход в день'
		 , ci.tarif AS 'Тариф'
		 , ci.value_paym AS 'Начислено'
		 , ci.comments AS 'Комментарий'
		 , ci.date_edit AS 'Дата редактирования'
		 , c.id AS 'Код счётчика'		 
		 , c.PeriodCheck AS 'Период поверки'
		 , c.date_del AS 'Дата закрытия'
		 , CASE
			   WHEN c.date_del IS NOT NULL THEN 'Да'
			   ELSE 'Нет'
		   END AS 'Закрыт'
		 , CASE
			   WHEN ci.mode_id = 0 THEN 'Текущий'
			   ELSE (
					   SELECT name
					   FROM dbo.Cons_modes
					   WHERE id = ci.mode_id
				   )
		   END AS 'Режим'
		 , CASE ci.metod_input
			   WHEN 1 THEN 'ручной'
			   WHEN 2 THEN 'из файла'
			   WHEN 3 THEN 'мобильный'
		   END AS 'Метод ввода'
		 , c.id_pu_gis AS '№ ПУ в ГИС ЖКХ'
		 , b.kod_fias AS 'Дом по ФИАС'
		 , CONCAT(b.street_name, b.nom_dom_sort) AS sort_dom
		 , b.nom_dom_sort
		 , f.nom_kvr_sort
		 , ci.fin_id
		 , c.external_id AS 'Внешний код ПУ'
		 , c.counter_uid AS 'УИД счётчика'
	FROM dbo.Counter_inspector AS ci
		JOIN dbo.Counters AS c ON 
			ci.counter_id = c.id
		JOIN dbo.View_buildings_lite AS b ON 
			c.build_id = b.id
		JOIN dbo.Services s1 ON 
			s1.id = c.service_id
		JOIN dbo.Calendar_period cp ON 
			ci.fin_id = cp.fin_id
		LEFT JOIN dbo.Flats AS f ON 
			c.flat_id = f.id
	WHERE 
		(ci.fin_id BETWEEN @fin_id1 AND @fin_id2)
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR c.build_id = @build_id1)
	OPTION (RECOMPILE)
go

