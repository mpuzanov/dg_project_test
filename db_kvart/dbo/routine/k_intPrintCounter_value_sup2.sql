-- =============================================
-- Author:		Пузанов
-- Create date: 13.04.2010   13.04.2023
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном доме или лицевом счете
-- =============================================
CREATE               PROCEDURE [dbo].[k_intPrintCounter_value_sup2]
(
	  @fin_id1 SMALLINT
	, @build_id INT
	, @occ1 INT = NULL
	, @sup_id INT = NULL
	, @is_inspector BIT = 1 -- выдавать только если есть показания в тек.месяце
	, @debug BIT = 0
)
AS
/*
EXEC k_intPrintCounter_value_sup2 @fin_id1=232, @build_id=NULL, @occ1=30039, @sup_id=NULL, @is_inspector=0
EXEC k_intPrintCounter_value_sup2 @fin_id1=232, @build_id=NULL, @occ1= 680003174, @sup_id=323, @is_inspector=0, @debug=0
EXEC k_intPrintCounter_value_sup2 @fin_id1=152, @build_id=NULL, @occ1= 680002159, @sup_id=323, @is_inspector=0, @debug=0
EXEC k_intPrintCounter_value_sup2 @fin_id1=182, @build_id=1061, @occ1= 680002126, @sup_id=323, @is_inspector=0, @debug=0
EXEC k_intPrintCounter_value_sup2 @fin_id1=234, @build_id=4095, @occ1= 314678, @sup_id=NULL, @is_inspector=0, @debug=1
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @start_date SMALLDATETIME
		  , @fin_current SMALLINT = [dbo].[Fun_GetFinCurrent](NULL, @build_id, NULL, @occ1)
		  , @tip_id SMALLINT
		  , @strerror VARCHAR(300)

	IF @is_inspector IS NULL
		SET @is_inspector = 1

	IF @fin_id1 > @fin_current
		SET @fin_id1 = @fin_current

	DECLARE @t TABLE (
		  occ INT
		, counter_id INT
		, service_id VARCHAR(10)
		, serv_name VARCHAR(20)
		, inspector_date SMALLDATETIME
		, cur_value DECIMAL(12, 4)
		, pred_value DECIMAL(12, 4)
		, pred_date SMALLDATETIME
		, tarif DECIMAL(10, 4)
		, sup_id INT DEFAULT 0
		, RESULT DECIMAL(12, 4) DEFAULT 0
		, serial_number VARCHAR(20)
		, [type] VARCHAR(30)
		, last_value DECIMAL(12, 4) DEFAULT NULL
		, last_date SMALLDATETIME DEFAULT NULL
		, PeriodCheck SMALLDATETIME
		, CurValueStr VARCHAR(30)
		, CurValueStr2 VARCHAR(30)
		, CurValueStr3 VARCHAR(30)
		, actual_value DECIMAL(12, 4)
		, kol_mes_PeriodCheck SMALLINT DEFAULT 100
		, ras_no_counter_poverka BIT DEFAULT 0
		, is_info BIT DEFAULT 0
		, mode_id INT DEFAULT 0
		, tip_id SMALLINT DEFAULT NULL
		, paym_blocked BIT DEFAULT 0
		, paid DECIMAL(9, 2) DEFAULT NULL
		, source_id INT DEFAULT 0
	)

	IF @fin_id1 IS NULL
		AND @build_id IS NULL
		AND @occ1 IS NULL
	BEGIN
		SELECT *
		FROM @t
		RETURN
	END

	IF @fin_id1 = 0
		SELECT @fin_id1 = @fin_current

	IF @occ1 IS NULL
		AND @build_id IS NULL
		SELECT @occ1 = 0

	IF @debug=1
		SELECT @fin_id1 AS fin_id1, @fin_current AS fin_current, @build_id AS build_id, @occ1 AS occ1, @sup_id AS sup_id
	--****************************************************************        
	BEGIN TRY

		SELECT @start_date = [start_date]
		FROM dbo.Global_values 
		WHERE fin_id = @fin_id1


		INSERT INTO @t (occ
					  , counter_id
					  , service_id
					  , serv_name
					  , inspector_date
					  , cur_value
					  , pred_value
					  , pred_date
					  , tarif
					  , serial_number
					  , [type]
					  , PeriodCheck
					  , actual_value
					  , kol_mes_PeriodCheck
					  , ras_no_counter_poverka
					  , mode_id
					  , tip_id
					  , paym_blocked
					  , paid
					  , source_id
					  , sup_id)
		SELECT cl.occ
			 , counter_id
			 , cl.service_id AS service_id
			 , S.short_name
			 , NULL AS inspector_date
			 , 0 AS cur_value
			 , 0 AS pred_value
			 , NULL AS pred_date
			 , COALESCE(vp.tarif,0) AS tarif
			 , c.serial_number
			 , c.[type]
			 , c.PeriodCheck
			 , 0 AS actual_value
			 , DATEDIFF(MONTH, @start_date, COALESCE(PeriodCheck, '20500101')) AS kol_mes_PeriodCheck
			 , CASE
				   WHEN B.ras_no_counter_poverka = 1 THEN 1
				   WHEN ot.ras_no_counter_poverka = 1 THEN 1
				   ELSE 0
			   END AS ras_no_counter_poverka
			 , c.mode_id
			 , o.tip_id
			 , sb.paym_blocked
			 , COALESCE(vp.paid, 0) AS paid
			 , vp.source_id
			 , COALESCE(vp.sup_id,0) AS sup_id
		FROM dbo.Counter_list_all AS cl 
			JOIN dbo.Counters AS c ON cl.counter_id = c.id
			JOIN dbo.Services AS S ON c.service_id = S.id
			JOIN dbo.Occupations AS o ON cl.occ = o.occ
			JOIN dbo.Occupation_Types AS ot ON ot.id = o.tip_id
			JOIN dbo.Buildings AS B ON c.build_id = B.id
			LEFT JOIN dbo.View_paym vp ON cl.occ = vp.occ
				AND cl.fin_id = vp.fin_id
				AND cl.service_id = vp.service_id
			LEFT JOIN dbo.Services_build AS sb ON c.service_id = sb.service_id
				AND c.build_id = sb.build_id
			LEFT JOIN dbo.Services_type_counters st ON c.service_id = st.service_id
				AND ot.id = st.tip_id
		WHERE 1=1
			AND cl.fin_id = @fin_id1
			AND (@build_id IS NULL OR c.build_id = @build_id)
			AND (@occ1 IS NULL OR cl.occ = @occ1)
			AND (st.tip_id IS NULL OR st.no_counter_raschet=0) -- признак нет расчета по счетчикам
			AND (c.date_del IS NULL OR c.date_del>vp.date_end)  -- 22.10.21
			AND (sb.build_id IS NULL OR sb.blocked_counter_kvit=0) -- признак блокировки ПУ в квитанции
		--ORDER BY cl.service_id
		OPTION (RECOMPILE, MAXDOP 1)

		UPDATE t
		SET inspector_date = ci.inspector_date
		  , cur_value = COALESCE(ci.inspector_value, 0)
		  , pred_date = ci_pred.inspector_date
		  , pred_value = COALESCE(ci_pred.inspector_value, 0)
		  , actual_value = COALESCE(ci.actual_value, 0)
		  , is_info = ci.is_info
		FROM @t AS t
			OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(t.counter_id, @fin_id1) AS ci
			OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(t.counter_id, @fin_id1) AS ci_pred


		IF @debug = 1
			SELECT '@t'
				 , *
			FROM @t

		--IF @debug = 1
		--	SELECT '#t2'
		--		 , *
		--	FROM #t2

		IF @fin_id1 = @fin_current
		BEGIN
			UPDATE t
			SET tarif =
					   CASE
						   WHEN mode_id > 0 THEN (
								   SELECT TOP (1) COALESCE(tarif, 0)
								   FROM dbo.Rates_counter AS rc 
								   WHERE rc.fin_id = @fin_id1
									   AND rc.tipe_id = t.tip_id
									   AND rc.service_id = t.service_id
									   AND rc.mode_id = t.mode_id
									   AND rc.tarif > 0
								   ORDER BY rc.tarif DESC
							   )
						   ELSE tarif
					   END
			FROM @t AS t
			WHERE t.tarif = 0
		END
		ELSE
		BEGIN
			UPDATE t
			SET tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, t.service_id, NULL)
			FROM @t AS t
		END

		UPDATE t
		SET sup_id = t2.sup_id
		FROM @t AS t
			JOIN @t AS t2 ON t2.occ = t.occ
		WHERE (t.service_id = 'гвод' AND t2.service_id = 'гвс2')
			OR (t.service_id = 'отоп' AND t2.service_id = 'ото2')
			OR (t.service_id = 'хвод' AND t2.service_id = 'хвс2')


		IF @debug = 1
			SELECT '@t 2'
				 , *
			FROM @t

		IF @is_inspector = 1 -- если нет текущих показаний удаляем
			DELETE FROM @t
			WHERE inspector_date IS NULL
				AND (kol_mes_PeriodCheck > 2)

		IF @sup_id > 0
			DELETE FROM @t WHERE sup_id <> @sup_id
		ELSE
			DELETE FROM @t WHERE sup_id>0

		IF @debug = 1
			SELECT '@t 3'
				 , *
			FROM @t

		SELECT occ
			 , counter_id
			 , CASE
				   WHEN service_id IN ('хвод', 'хвс2') THEN 'ХВС'
				   WHEN service_id IN ('гвод', 'гвс2') THEN 'ГВС'
				   WHEN service_id IN ('элек', 'эле2') THEN 'Эл.Энергия'
				   WHEN service_id IN ('отоп', 'ото2') THEN 'Отопл'
				   WHEN service_id IN ('пгаз') THEN 'Газ'
				   WHEN service_id IN ('газОтоп') THEN 'ГазОтоп'
				   ELSE SUBSTRING(serv_name, 1, 10)
			   END AS service_id
			 , inspector_date
			 , cur_value
			 , pred_value
			 , pred_date
			 , CASE
				   WHEN service_id = 'элек' THEN tarif
				   ELSE 0
			   END AS tarif
			 , sup_id
			 , dbo.nstr(CASE
				   WHEN inspector_date IS NULL THEN NULL
				   WHEN cur_value > pred_value THEN cur_value - pred_value
				   ELSE actual_value
			   END) AS RESULT
			 , serial_number
			 , [type]
			 , CASE
				   WHEN cur_value > pred_value THEN cur_value
				   ELSE pred_value
			   END AS [last_value]
			 , CASE
				   WHEN cur_value >= pred_value THEN inspector_date
				   ELSE pred_date
			   END AS last_date
			 , PeriodCheck
			 , CASE
				   WHEN paym_blocked = 0 AND
					   kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
				   WHEN kol_mes_PeriodCheck <= 2 AND
					   PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
				   ELSE CASE
                            WHEN inspector_date IS NULL THEN ''
                            ELSE dbo.nstr(cur_value) + ' - ' + dbo.nstr(pred_value)
                       END
			   END AS CurValueStr
			 , CASE
				   WHEN paym_blocked = 0 AND
					   kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
				   WHEN kol_mes_PeriodCheck <= 2 AND
					   PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
				   ELSE dbo.nstr(pred_value) + ' - ' + CASE WHEN cur_value <> 0 THEN dbo.nstr(cur_value) ELSE '' END
			   --LTRIM(REPLACE(STR(cur_value, 10, 4), '.0000', ''))
			   END AS CurValueStr2
			 , CASE
				   WHEN paym_blocked = 0 AND
					   kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
				   ELSE CASE
                            WHEN cur_value <> 0 THEN dbo.FSTR(cur_value, 10, 4)
                            ELSE 'нет'
                            END + '-'
					   + CASE
                             WHEN pred_value <> 0 THEN dbo.FSTR(pred_value, 10, 4)
                             ELSE 'нет'
                            END + '='
					   + dbo.nstr(CASE
						   WHEN inspector_date IS NULL THEN 0
						   WHEN cur_value > pred_value THEN cur_value - pred_value
						   ELSE actual_value
					   END)
			   END AS CurValueStr3
		FROM @t
		WHERE 1=1
			AND (tarif > 0 OR paid <> 0 OR (source_id % 1000 <> 0))
			OR is_info = 1 
		ORDER BY service_id

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + 'Лицевой: ' + LTRIM(STR(@occ1))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
	END CATCH


	RETURN

END
go

