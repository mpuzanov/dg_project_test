CREATE   PROCEDURE [dbo].[k_counter_inspector]
(
	  @counter_id1 INT -- код счетчика
	, @tip_value1 SMALLINT = 0 -- 0 -инспектора 1-квартиросъемщика, 2- домовой, null- все
	, @fin_id1 SMALLINT = NULL
)
AS
/*
	Показываем паказатели по счетчику инспектора или квартиросъемщика
	exec k_counter_inspector 66140,1,null
	exec k_counter_inspector 10429,null,170
	exec k_counter_inspector 10429,1,170
	  
	exec k_counter_inspector 97914,1,null
*/
	SET NOCOUNT ON

	IF @fin_id1 = 0
		SET @fin_id1 = NULL

	--IF @tip_value1 IS NULL
	--	SET @tip_value1 = 1

	SELECT ci.id
		 , ci.counter_id
		 , ci.tip_value
		 , CAST(ci.inspector_value AS INT) AS inspector_value
		 , ci.inspector_value AS insp_value_decimal
		 , ci.inspector_date
		 , ci.blocked
		 , ci.user_edit
		 , ci.date_edit
		 , ci.kol_day
		 --, CAST(ci.actual_value AS INT) AS actual_value
		 , ci.actual_value AS actual_value
		 , ci.actual_value AS actual_value_decimal
		 , ci.value_vday
		 , ci.comments
		 , ci.fin_id
		 , ci.mode_id
		 , ci.tarif
		 , ci.value_paym
		 , u.Initials AS Name_user
		 , cp.StrFinPeriod AS Fin_name
		 , CASE
			   WHEN ci.mode_id = 0 THEN 'Текущий'
			   ELSE (
					   SELECT name
					   FROM dbo.Cons_modes 
					   WHERE id = ci.mode_id
				   )
		   END AS mode_name
		 , ci.volume_arenda
		 , ci.volume_odn
		 , ci.norma_odn
		 , ci.volume_direct_contract
		 , ci.is_info
		 , CASE
			   WHEN ci.tip_value = 0 THEN 'Инспектор'
			   WHEN ci.tip_value = 1 THEN 'Квартиросъемщик'
			   WHEN ci.tip_value = 2 THEN 'Инспектор ОПУ'
			   ELSE '?'
		   END AS tip_value_str
         , COALESCE(cl.cnt_occ,0) AS counter_occ
		 , CASE ci.metod_rasch
			   WHEN 0 THEN 'не начислять'
			   WHEN 1 THEN 'по норме'
			   WHEN 2 THEN 'по среднему'
			   WHEN 3 THEN 'по счетчику'
			   WHEN 4 THEN 'по домовому'
			   ELSE NULL
		   END AS metod_rasch
		 , ci.warning AS warning
		 , COALESCE(ci.blocked_value_negativ, cast(0 as bit)) AS blocked_value_negativ
	FROM dbo.Counter_inspector AS ci
		JOIN dbo.Counters AS C ON 
			ci.counter_id = C.id		
		JOIN dbo.Calendar_period cp ON 
			cp.fin_id = ci.fin_id
		LEFT JOIN dbo.Users u ON 
			ci.user_edit = u.id
		OUTER APPLY (
			   SELECT COUNT(cla.occ) as cnt_occ
			   FROM dbo.Counter_list_all AS cla 
			   WHERE ci.fin_id = cla.fin_id
				   AND ci.counter_id = cla.counter_id) as cl
	WHERE 
		ci.counter_id = @counter_id1
		AND (@tip_value1 IS NULL OR ci.tip_value = @tip_value1)
		AND (ci.fin_id = COALESCE(@fin_id1, ci.fin_id) OR ci.fin_id = 0)	
	ORDER BY ci.inspector_date DESC
		   , ci.fin_id DESC
		   , ci.id DESC
go

