-- =============================================
-- Author:		Пузанов
-- Create date: 14.04.2013
-- Description:	Выдаем показания ОПУ на заданном лицевом счете
-- =============================================
CREATE           PROCEDURE [dbo].[k_intPrintCounterOpu]
	  @fin_id SMALLINT
	, @occ INT = NULL
	, @sup_id INT = NULL
	, @build_id INT = NULL
	, @all BIT = NULL
	, @debug BIT = 0
	, @tip_id SMALLINT = NULL
AS
/*
EXEC k_intPrintCounterOpu @fin_id=182,@sup_id=347,@build_id=1081,@all=1--,@occ=680004996
EXEC k_intPrintCounterOpu @fin_id=232,@occ=31001,@build_id=6785,@all=1
EXEC k_intPrintCounterOpu @fin_id=232,@occ=null,@build_id=6785,@all=1
EXEC k_intPrintCounterOpu @fin_id=232,@occ=null,@build_id=null, @tip_id=1, @all=1
*/
BEGIN
	SET NOCOUNT ON;

	IF @fin_id IS NULL
		AND @build_id IS NULL
		AND @occ IS NULL
		AND @tip_id IS NULL
		RETURN

	IF @all IS NULL
		SET @all = 0

	IF @build_id IS NULL
		AND @tip_id IS NULL
		AND @occ IS NOT NULL
	BEGIN
		SELECT @occ = dbo.Fun_GetFalseOccIn(@occ) -- если на входе был ложный лицевой

		SELECT @build_id = f.bldn_id
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats AS f ON o.flat_id = f.id
		WHERE o.occ = @occ
	END

	SELECT c.id AS counter_id
		 , c.service_id
		 , COALESCE(s.sup_id, 0) AS sup_id
		 , c.count_value AS count_value_create
		 , c.date_create
		 , c.koef AS koef
		 , c.serial_number
		 , c.build_id
	INTO #t_sup
	FROM dbo.Counters c 
		JOIN dbo.Buildings b ON c.build_id = b.id
		LEFT JOIN dbo.Build_source vp ON vp.build_id = c.build_id
			AND vp.service_id = c.service_id
		LEFT JOIN dbo.Suppliers s ON vp.source_id = s.id
			AND s.account_one = 1
	WHERE c.is_build = CAST(1 AS BIT)
		AND (@build_id IS NULL OR c.build_id = @build_id)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		--AND (vp.source_id % 1000 <> 0)  -- закомментировал 28.09.22
	OPTION (RECOMPILE)

	IF @debug = 1 SELECT '#t_sup' AS tbl, * FROM #t_sup
	
	;
	WITH cte AS
	(
		SELECT CASE
				   WHEN ci.[service_id] IN ('гвод', 'гвс2') THEN 'Гвс'
				   WHEN ci.[service_id] IN ('хвод', 'хвс2') THEN 'Хвс'
				   WHEN ci.[service_id] IN ('элек', 'эле2', 'элмп') THEN 'Элек'
				   WHEN ci.[service_id] IN ('отоп', 'ото2') THEN 'Отоп'
				   WHEN ci.[service_id] IN ('газОтоп') THEN 'ГазОтоп'
				   ELSE ci.[service_id]
			   END AS serv_name
			 , t_sup.serial_number
			 , u.short_id AS unit_id
			 , COALESCE(ci_pred.inspector_value, t_sup.count_value_create) AS pred_value
			 , COALESCE(ci_pred.inspector_date, t_sup.date_create) AS pred_date
			 , ci.inspector_value
			 , ci.inspector_date
			 , ci.actual_value
			 , ci.service_id
			 , t_sup.sup_id
			 , t_sup.Koef
			 , t_sup.build_id
		FROM #t_sup AS t_sup
			JOIN dbo.View_counter_insp_build AS ci ON ci.service_id = t_sup.service_id
				AND t_sup.counter_id = ci.counter_id AND ci.build_id = t_sup.build_id
			JOIN dbo.Units AS u ON ci.unit_id = u.id
			OUTER APPLY (
				SELECT TOP (1) ci2.inspector_value
							 , ci2.inspector_date
				FROM dbo.Counter_inspector AS ci2 
				WHERE ci2.counter_id = ci.counter_id
					AND ci2.fin_id < @fin_id
					AND ci2.tip_value = 2
				ORDER BY ci2.inspector_date DESC
			) AS ci_pred
		WHERE ci.fin_id = @fin_id
			AND ci.inspector_value > 0
			AND ci.blocked=0  --30.05.2022
	)

	SELECT DISTINCT *
	FROM cte ts
	WHERE ((@all = 0 AND sup_id = COALESCE(@sup_id, 0)) OR (@all = 1))
	ORDER BY ts.build_id
--OPTION (RECOMPILE)

END
go

