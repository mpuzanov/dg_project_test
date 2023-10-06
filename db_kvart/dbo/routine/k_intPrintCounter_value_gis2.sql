-- =============================================
-- Author:		Пузанов
-- Create date: 22.01.2020
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном лицевом счете для ГИС ЖКХ в платёжный документ
-- =============================================
CREATE     PROCEDURE [dbo].[k_intPrintCounter_value_gis2]
	@fin_id	  SMALLINT
   ,@build_id INT	   = NULL
   ,@occ	  INT	   = NULL
   ,@sup_id	  INT	   = NULL
   ,@debug	  BIT	   = 0
   ,@kol	  SMALLINT = 1 -- Количество показаний по услуге
AS
/*
EXEC k_intPrintCounter_value_gis2 @fin_id=186, @build_id=NULL, @occ= 315356,@sup_id=null, @debug=1, @kol=2
EXEC k_intPrintCounter_value_gis2 @fin_id=192, @build_id=3615, @occ= 339859,@sup_id=null, @debug=1, @kol=1
EXEC k_intPrintCounter_value_gis2 @fin_id=188, @build_id=NULL, @occ= 680004146,@sup_id=323, @debug=1, @kol=1
EXEC k_intPrintCounter_value_gis2 @fin_id=198, @build_id=3776
*/
BEGIN
	SET NOCOUNT ON;

	IF @build_id IS NULL
		AND @occ IS NULL
		SELECT
			@build_id = 0
		   ,@occ = 0

	IF @kol IS NULL
		SET @kol = 1

		;
	WITH cte
	AS
	(SELECT
			cl.Occ
		 --  ,CASE
			--	WHEN st.service_name_gis IS NULL THEN C.service_id
			--	ELSE LTRIM(RTRIM(st.service_name_gis))
			--END
			--AS service_name_gis
		   ,CASE  -- в гис зашиты наименования для ПУ
				WHEN C.service_id IN ('гвод') THEN 'Горячее водоснабжение'
				WHEN C.service_id IN ('хвод') THEN 'Холодное водоснабжение'
				WHEN C.service_id IN ('элек') THEN 'Электроснабжение'
				WHEN C.service_id IN ('пгаз') THEN 'Газоснабжение'
				WHEN C.service_id IN ('отоп') THEN 'Отопление'
				ELSE C.service_id
			END	AS service_name_gis
		   ,C.id
		   ,ci.inspector_value
		   ,C.build_id
		   ,C.serial_number
		   ,ci_pred.inspector_value AS pred_inspector_value
		   ,C.unit_id
		   ,CASE
				WHEN t_sb.build_is_export_gis IN (1, 0) THEN t_sb.build_is_export_gis
				WHEN t_stc.tip_is_export_gis = 0 THEN 0
				ELSE 1
			END AS is_export_gis
		FROM dbo.Counters C 
		JOIN dbo.Counter_list_all AS cl 
			ON C.id = cl.counter_id
		JOIN dbo.Occupations o 
			ON cl.Occ = o.Occ
		JOIN dbo.Services s 
			ON C.service_id = s.id
		LEFT JOIN dbo.Services_types AS st 
			ON C.service_id = st.service_id
			AND o.tip_id = st.tip_id
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(C.id, @fin_id) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(C.id, @fin_id) AS ci_pred
		--*****************************************************************
		OUTER APPLY (SELECT CASE
                                WHEN stc.no_export_gis = 1 THEN 0
                                ELSE 1
                                END AS tip_is_export_gis
			FROM dbo.Services_type_counters stc 
			WHERE stc.tip_id = o.tip_id
			AND stc.service_id = C.service_id
			AND stc.no_export_gis = CAST(1 AS BIT)) AS t_stc
		OUTER APPLY (SELECT
				sb.is_export_gis AS build_is_export_gis
			FROM dbo.SERVICES_BUILD sb 
			WHERE sb.build_id = C.build_id
			AND sb.service_id = C.service_id) AS t_sb
		--*****************************************************************
		WHERE (@build_id IS NULL OR C.build_id = @build_id)
			AND (@occ IS NULL OR cl.Occ = @occ)
			AND s.service_type = 2
			AND cl.fin_id = @fin_id)

	SELECT
		t1.Occ
	   ,t1.service_name_gis
	   ,t1.serial_number
	   ,LTRIM(STR(pred_inspector_value)) AS pred_inspector_value
	   ,LTRIM(STR(t1.inspector_value)) AS inspector_value_str
	   ,t1.build_id AS build_id
	   ,dbo.Fun_GetNumUV(Occ, @fin_id, @sup_id) AS num_pd
	   ,CASE t1.unit_id
			WHEN 'кубм' THEN 'м[3*]'
			WHEN 'квтч' THEN 'кВт.ч'
			WHEN 'ггкл' THEN 'Гкал'
			ELSE ''
		END AS unit_name
	FROM cte AS t1
	WHERE is_export_gis=1

/*
Литр;кубический дециметр	л;дм[3*]
Кубический метр	м[3*]
Гигакалория	Гкал
Киловатт-час	кВт.ч
Мегаватт-час;1000 киловатт-часов	МВт.ч; 10[3*] кВт.ч
Джоуль	Дж
Гигаджоуль	ГДж
Мегаджоуль	МДж
*/


END
go

