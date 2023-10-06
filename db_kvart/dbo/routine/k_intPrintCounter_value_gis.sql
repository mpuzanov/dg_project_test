-- =============================================
-- Author:		Пузанов
-- Create date: 22.01.2020
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном лицевом счете для ГИС ЖКХ в платёжный документ
-- =============================================
CREATE     PROCEDURE [dbo].[k_intPrintCounter_value_gis]
	@fin_id	  SMALLINT
   ,@build_id INT	   = NULL
   ,@occ	  INT	   = NULL
   ,@sup_id	  INT	   = NULL
   ,@debug	  BIT	   = 0
   ,@kol	  SMALLINT = 1 -- Количество показаний по услуге
AS
/*
EXEC k_intPrintCounter_value_gis @fin_id=186, @build_id=NULL, @occ= 315356,@sup_id=null, @debug=1, @kol=2
EXEC k_intPrintCounter_value_gis @fin_id=192, @build_id=3615, @occ= 339859,@sup_id=null, @debug=1, @kol=1
EXEC k_intPrintCounter_value_gis @fin_id=188, @build_id=NULL, @occ= 680004146,@sup_id=323, @debug=1, @kol=1
EXEC k_intPrintCounter_value_gis @fin_id=198, @build_id=3776
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
		   ,CASE
				WHEN st.service_name_gis IS NULL THEN C.service_id
				ELSE LTRIM(RTRIM(st.service_name_gis))
			END
			AS service_name_gis
		   ,C.id
		   ,ci.inspector_value
		   ,C.build_id
		FROM dbo.COUNTERS C 
		JOIN dbo.COUNTER_LIST_ALL AS cl 
			ON C.id = cl.counter_id
		JOIN dbo.COUNTER_INSPECTOR AS ci 
			ON cl.counter_id = ci.counter_id
			AND cl.fin_id = ci.fin_id
		JOIN dbo.OCCUPATIONS o 
			ON cl.Occ = o.Occ
		JOIN dbo.SERVICES s 
			ON C.service_id = s.id
		LEFT JOIN dbo.SERVICES_TYPES AS st 
			ON C.service_id = st.service_id
			AND o.tip_id = st.tip_id
		WHERE (C.build_id = @build_id
		OR @build_id IS NULL)
		AND (cl.Occ = @occ
		OR @occ IS NULL)
		AND s.service_type = 2
		AND ci.fin_id = @fin_id
		AND ci.tip_value =
			CASE
				WHEN C.is_build = 1 THEN 2
				ELSE 1 --  квартиросъемщика
			END)

	SELECT
		t1.Occ
	   ,t1.service_name_gis
	   ,STUFF((SELECT TOP (@kol)
				' ' + LTRIM(STR(t2.inspector_value))
			FROM cte AS t2
			WHERE t2.Occ = t1.Occ
			AND t2.service_name_gis = t1.service_name_gis
			GROUP BY t2.id
					,t2.inspector_value
			ORDER BY t2.id
			FOR XML PATH (''))
		, 1, 1, '')
		AS inspector_value_str
	   ,t1.build_id AS build_id
	   ,dbo.Fun_GetNumUV(Occ, @fin_id, @sup_id) AS num_pd
	FROM cte AS t1
	GROUP BY t1.Occ
			,t1.service_name_gis
			,t1.build_id



END
go

