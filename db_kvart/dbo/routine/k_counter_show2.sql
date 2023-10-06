CREATE   PROCEDURE [dbo].[k_counter_show2]
(
	@occ1		INT
	,@fin_id1	SMALLINT	= NULL
)
AS
	/*
	Показываем список счетчиков по лицевому счету
	
	exec k_counter_show2 910000873, 150	
	exec k_counter_show2 680000070, 181		
	exec k_counter_show2 680003808, 199	
	
	Используется в Картотеке
	
	Изменения 30.08.07
	Когда @fin_id1 is NULL показывать счетчики за все периоды
	*/
	SET NOCOUNT ON


	SELECT
		c.id
		,c.service_id
		,c.serial_number
		,c.type
		,c.build_id
		,c.flat_id
		,c.max_value
		,c.koef
		,c.unit_id
		,CAST(c.count_value AS INT) AS count_value
		,c.count_value AS count_value_decimal
		,c.date_create
		,CAST(c.CountValue_del AS INT) AS CountValue_del
		,c.CountValue_del AS CountValue_del_decimal
		,c.date_del
		,c.PeriodCheck
		,c.date_edit
		,c.comments
		,c.is_build
		,cl.occ_counter
		,s.name AS short_name
		,CASE
			WHEN c.date_del IS NULL THEN 'Работает'
			ELSE 'Закрыт'
		END AS closed
		,CASE
			WHEN cl.kol_occ<= 1 THEN 'Индивидуальный'
			WHEN COALESCE(c.room_id,0)>0 THEN 'Комнатный'
			ELSE 'Общий (квартирный)'
		END AS count_occ
		,cl.kol_occ
		,cp.StrFinPeriod AS fin_period
		,cl.fin_id as fin_id
		,o.address AS Adres
		,cl.internal
		,u.Initials AS Initial_user
		,c.mode_id
		,COALESCE(cm.name, 'Текущий') AS mode_name
		,s.sort_no
		,cl.KolmesForPeriodCheck
		,cl.avg_vday
		,c.id_pu_gis
		,c.is_sensor_temp
		,c.is_sensor_press
		,c.PeriodLastCheck
		,c.PeriodInterval AS PeriodInterval
		,c.is_remot_reading
		,c.room_id
		,c.ReasonDel
		,ci_last.inspector_value as inspector_value_last
		,ci_last.inspector_date as inspector_date_last
		,coalesce(cl.no_vozvrat, cast(0 as bit)) as no_vozvrat
		--,CAST(c.counter_uid AS VARCHAR(36)) AS counter_uid
		,c.counter_uid AS counter_uid
		,c.count_tarif
		,c.value_serv_many_pu
		,c.external_id
		,c.blocker_read_value
	FROM dbo.Counter_list_all AS cl 
		JOIN dbo.Counters AS c 
			ON c.id = cl.counter_id
		JOIN dbo.View_services AS s
			ON cl.service_id = s.id		
		JOIN dbo.Calendar_period cp
			ON cp.fin_id = cl.fin_id
		LEFT JOIN dbo.Users u ON 
			c.user_edit=u.id
		LEFT JOIN dbo.Occupations o ON 
			cl.occ=o.occ
		LEFT JOIN dbo.Cons_modes AS cm 
			ON c.mode_id = cm.id
			AND c.service_id = cm.service_id
		OUTER APPLY [dbo].Fun_GetCounterValue_last(c.id, @fin_id1) AS ci_last
	WHERE 
		cl.Occ = @occ1 
		AND (@fin_id1 IS NULL OR cl.fin_id = @fin_id1)
	ORDER BY fin_id DESC, s.sort_no
	OPTION(RECOMPILE)
go

