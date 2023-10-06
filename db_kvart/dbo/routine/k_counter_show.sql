CREATE   PROCEDURE [dbo].[k_counter_show]
(
	@build_id1		INT	-- код дома
	,@service_id1	VARCHAR(10)	= NULL
	,@flat_id		INT		= NULL
)
AS
	/*
		Показываем счетчики в доме или квартире
		exec k_counter_show 1031
		exec k_counter_show 1031, 'хвод'
		exec k_counter_show 1031, null, 12095
		exec k_counter_show 3802
		exec k_counter_show NULL,NULL,NULL
	*/
	SET NOCOUNT ON

	IF @build_id1 IS NULL
		AND @flat_id IS NULL
		SELECT
			@build_id1 = 0
			,@flat_id = 0

	SELECT
		*
	FROM (SELECT
			c.id
			,c.service_id
			,c.serial_number
			,c.type
			,c.build_id
			,c.flat_id
			,c.max_value
			,c.KOEF
			,c.unit_id
			,CAST(c.count_value AS INT) AS count_value
			,c.count_value AS count_value_decimal
			,c.date_create
			,CAST(c.CountValue_del AS INT) AS CountValue_del
			,c.CountValue_del AS CountValue_del_decimal
			,c.date_del
			,c.PeriodCheck
			,c.user_edit
			,c.date_edit
			,c.comments
			,c.internal
			,c.is_build
			,c.checked_fin_id
			,COALESCE(f.nom_kvr, '-') AS nom_kvr
			,s.name AS short_name--s.short_name
			,u.Initials AS Name_user
			,CAST(CASE
				WHEN c.is_build = 1 THEN CONCAT(vs.socr_name,' д. ', b.nom_dom)
				ELSE CONCAT(vs.socr_name,' д. ', b.nom_dom,' кв. ',f.nom_kvr) 
			END AS VARCHAR(200)) AS Adres
			,CASE
				WHEN checked_fin_id > 0 THEN dbo.Fun_NameFinPeriod(checked_fin_id)
				ELSE NULL
			END AS checked_fin_name
			,c.mode_id
			,COALESCE(cm.name, 'Текущий') AS mode_name
			,c.id_pu_gis
			,f.nom_kvr_sort
			,f.id_nom_gis
			,u1.name AS unit_name
			,c.is_sensor_temp
			,c.is_sensor_press
			,c.PeriodLastCheck
			,c.PeriodInterval
			,c.is_remot_reading
			,c.room_id
			,c.ReasonDel
			,CAST(c.counter_uid AS VARCHAR(36)) AS counter_uid
			,COALESCE((SELECT TOP(1)
					cl.kol_occ
				FROM dbo.COUNTER_LIST_ALL AS cl 
				WHERE c.id = cl.counter_id
				AND cl.fin_id = b.fin_current)
			, 0)
			AS count_occ
			,r.name AS room_num
			,r.id_room_gis AS id_room_gis
			,c.count_tarif
			,c.value_serv_many_pu
			,c.external_id
			,c.blocker_read_value
			,COUNT(c.id) OVER(PARTITION BY c.service_id, c.serial_number) AS Count_SerNum
		FROM dbo.Counters AS c 
		JOIN dbo.View_services AS s 
			ON c.service_id = s.id
		JOIN dbo.Buildings b 
			ON c.build_id = b.id
		JOIN dbo.VStreets AS vs 
			ON b.street_id = vs.id
		left JOIN dbo.Flats AS f 
			ON c.flat_id = f.id
		left JOIN dbo.Rooms AS r 
			ON r.id = c.room_id
		LEFT JOIN dbo.Cons_modes AS cm 
			ON c.mode_id = cm.id
			AND c.service_id = cm.service_id
		LEFT JOIN dbo.Users u
			ON c.user_edit = u.id
		LEFT JOIN dbo.Units u1
			ON c.unit_id = u1.id
		WHERE 1=1
		and (@service_id1 is null or s.id = @service_id1)
		and (@build_id1 is null or c.build_id = @build_id1)
		and (@flat_id is null or c.flat_id = @flat_id)
		) X
	ORDER BY nom_kvr_sort, service_id, id
	OPTION (RECOMPILE)
go

