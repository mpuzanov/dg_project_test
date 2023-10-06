-- =============================================
-- Author:		Пузанов
-- Create date: 13.04.2010
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном лицевом счете
-- =============================================
CREATE         PROCEDURE [dbo].[k_intPrintCounter_value_sup]
	@fin_id1	  SMALLINT
   ,@occ1		  INT
   ,@sup_id		  INT = NULL
   ,@is_inspector BIT = 1 -- выдавать только если есть показания в тек.месяце
   ,@debug		  BIT = 0
AS
/*

EXEC k_intPrintCounter_value_sup @fin_id1=180, @occ1= 680003174,@sup_id=0, @is_inspector=1, @debug=1
EXEC k_intPrintCounter_value_sup @fin_id1=152, @occ1= 680002159,@sup_id=323, @is_inspector=0, @debug=0
EXEC k_intPrintCounter_value_sup @fin_id1=182, @occ1= 680002126,@sup_id=323, @is_inspector=0, @debug=0

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @start_date	 SMALLDATETIME
		   ,@fin_current SMALLINT
		   ,@tip_id		 SMALLINT
		   ,@strerror	 VARCHAR(300)

	IF @is_inspector IS NULL
		SET @is_inspector = 1

	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)
	IF @fin_id1 > @fin_current
		SET @fin_id1 = @fin_current

	DECLARE @t TABLE
		(
			counter_id			   INT
		   ,service_id			   VARCHAR(10)
		   ,serv_name			   VARCHAR(20)
		   ,inspector_date		   SMALLDATETIME
		   ,cur_value			   DECIMAL(12, 4)
		   ,pred_value			   DECIMAL(12, 4)
		   ,pred_date			   SMALLDATETIME
		   ,tarif				   DECIMAL(10, 4)
		   ,sup_id				   INT			  DEFAULT 0
		   ,RESULT				   DECIMAL(12, 4) DEFAULT 0
		   ,serial_number		   VARCHAR(20)
		   ,[type]				   VARCHAR(30)
		   ,last_value			   DECIMAL(12, 4) DEFAULT NULL
		   ,last_date			   SMALLDATETIME  DEFAULT NULL
		   ,PeriodCheck			   SMALLDATETIME
		   ,CurValueStr			   VARCHAR(30)
		   ,CurValueStr2		   VARCHAR(30)
		   ,actual_value		   DECIMAL(12, 4)
		   ,kol_mes_PeriodCheck	   SMALLINT		  DEFAULT 100
		   ,ras_no_counter_poverka BIT			  DEFAULT 0
		   ,is_info				   BIT			  DEFAULT 0
		)

	IF @fin_id1 IS NULL
		AND @occ1 IS NULL
	BEGIN
		SELECT
			*
		FROM @t
		RETURN
	END

	IF @fin_id1 = 0
		SELECT
			@fin_id1 = @fin_current

	IF @occ1 IS NULL
		SELECT
			@occ1 = 0

	--****************************************************************        
	BEGIN TRY

		SELECT
			@start_date = [start_date]
		FROM dbo.GLOBAL_VALUES 
		WHERE fin_id = @fin_id1


		INSERT
		INTO @t
		(counter_id
		,service_id
		,serv_name
		,inspector_date
		,cur_value
		,pred_value
		,pred_date
		,tarif
		,serial_number
		,[type]
		,PeriodCheck
		,actual_value
		,kol_mes_PeriodCheck
		,ras_no_counter_poverka)
			SELECT
				counter_id
			   ,cl.service_id AS service_id
			   ,S.short_name
			   ,NULL AS inspector_date
			   ,0 AS cur_value
			   ,0 AS pred_value
			   ,NULL AS pred_date
			   ,0 AS tarif
			   ,C.serial_number
			   ,C.[type]
			   ,C.PeriodCheck
			   ,0 AS actual_value
			   ,DATEDIFF(MONTH, @start_date, COALESCE(PeriodCheck, '20500101')) AS kol_mes_PeriodCheck
			   ,CASE
					WHEN B.ras_no_counter_poverka = 1 THEN 1
					WHEN ot.ras_no_counter_poverka = 1 THEN 1
					ELSE 0
				END AS ras_no_counter_poverka
			FROM dbo.Counter_list_all AS cl
				JOIN dbo.Counters AS C 
					ON cl.counter_id = C.id
				JOIN dbo.SERVICES AS S 
					ON C.service_id = S.id
				JOIN dbo.Occupations AS o 
					ON cl.occ = o.occ
				JOIN dbo.Occupation_Types AS ot
					ON ot.id = o.tip_id
				JOIN dbo.Buildings AS B 
					ON C.build_id = B.id
			WHERE cl.occ = @occ1
			AND cl.fin_id = @fin_current
			ORDER BY cl.service_id

		UPDATE t
		SET inspector_date = ci.inspector_date
		   ,cur_value	   = COALESCE(ci.inspector_value, 0)
		   ,pred_date	   = ci_pred.inspector_date
		   ,pred_value	   = COALESCE(ci_pred.inspector_value, 0)
		   ,actual_value   = COALESCE(ci.actual_value, 0)
		   ,is_info		   = ci.is_info
		FROM @t AS t
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(t.counter_id, @fin_id1) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(t.counter_id, @fin_id1) AS ci_pred

		SELECT
			service_id
		   ,sup_id
		INTO #t2
		FROM dbo.View_CONSMODES_ALL AS vca 
		WHERE occ = @occ1
		AND vca.fin_id = @fin_id1
		AND vca.sup_id > 0

		--SELECT
		--	service_id
		--	,sup_id
		--  ,value
		--INTO #t2
		--FROM dbo.View_PAYM AS vp 
		--WHERE occ = @occ1
		--AND vp.fin_id = @fin_id1
		--AND vp.sup_id > 0

		IF @debug = 1
			SELECT
				'@t'
			   ,*
			FROM @t
		IF @debug = 1
			SELECT
				'#t2'
			   ,*
			FROM #t2

		IF @fin_id1 = @fin_current
		BEGIN
			UPDATE t
			SET tarif  = (SELECT TOP 1
						tarif
					FROM dbo.PAYM_LIST 
					WHERE occ = @occ1
					AND service_id = t.service_id)
			   ,sup_id = (SELECT TOP 1
						sup_id
					FROM #t2 AS t2
					WHERE service_id = t.service_id)
			FROM @t AS t
		END

		IF @fin_id1 < @fin_current
		BEGIN
			UPDATE t
			SET tarif  = dbo.Fun_GetCounterTarfServ(@fin_id1, @occ1, t.service_id, NULL)
			   ,sup_id = (SELECT TOP 1
						sup_id
					FROM #t2 AS t2
					WHERE t2.service_id = t.service_id)
			FROM @t AS t
		END

		UPDATE t
		SET sup_id = t2.sup_id
		FROM @t AS t
		, #t2 AS t2
		WHERE t.service_id = 'гвод'
		AND t2.service_id = 'гвс2'

		UPDATE t
		SET sup_id = t2.sup_id
		FROM @t AS t
		, #t2 AS t2
		WHERE t.service_id = 'отоп'
		AND t2.service_id = 'ото2'

		UPDATE t
		SET sup_id = t2.sup_id
		FROM @t AS t
		, #t2 AS t2
		WHERE t.service_id = 'хвод'
		AND t2.service_id = 'хвс2'

		IF @debug = 1
			SELECT
				'@t 2'
			   ,*
			FROM @t

		IF @is_inspector = 1 -- если нет текущих показаний удаляем
			DELETE FROM @t
			WHERE inspector_date IS NULL
				AND (kol_mes_PeriodCheck > 2)

		IF @sup_id > 0
			DELETE FROM @t
			WHERE COALESCE(sup_id, 0) <> @sup_id
		ELSE
		IF @sup_id = 0
			DELETE FROM @t
			WHERE sup_id IS NOT NULL

		IF @debug = 1
			SELECT
				'@t 3'
			   ,*
			FROM @t

		SELECT
			counter_id
		   ,CASE
				WHEN service_id IN ('хвод', 'хвс2') THEN 'ХВС'
				WHEN service_id IN ('гвод', 'гвс2') THEN 'ГВС'
				WHEN service_id IN ('элек', 'эле2') THEN 'Эл.Энергия'
				WHEN service_id IN ('отоп', 'ото2') THEN 'Отопл'
				ELSE SUBSTRING(serv_name, 1, 10)
			END AS service_id
		   ,inspector_date
		   ,cur_value
		   ,pred_value
		   ,pred_date
		   ,CASE
				WHEN service_id = 'элек' THEN tarif
				ELSE 0
			END AS tarif
		   ,sup_id
		   ,dbo.nstr(CASE
				WHEN inspector_date IS NULL THEN NULL
				WHEN cur_value > pred_value THEN cur_value - pred_value
				ELSE actual_value
			END) AS RESULT
		   ,serial_number
		   ,[type]
		   ,CASE
				WHEN cur_value > pred_value THEN cur_value
				ELSE pred_value
			END AS [last_value]
		   ,CASE
				WHEN cur_value > pred_value THEN inspector_date
				ELSE pred_date
			END AS last_date
		   ,PeriodCheck
		   ,CASE
				WHEN kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
				WHEN kol_mes_PeriodCheck <= 2 AND
				PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
				ELSE dbo.nstr(cur_value) + ' - ' + CONVERT(VARCHAR(15), inspector_date, 4)
			END AS CurValueStr
		   ,CASE
				WHEN kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
				WHEN kol_mes_PeriodCheck <= 2 AND
				PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
				ELSE LTRIM(REPLACE(STR(pred_value, 10, 4), '.0000', '')) + ' - ' + LTRIM(REPLACE(STR(cur_value, 10, 4), '.0000', ''))
			END AS CurValueStr2
		FROM @t
		WHERE 1=1
			AND tarif > 0
			OR is_info = CAST(1 AS BIT)

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + 'Лицевой: ' + LTRIM(STR(@occ1))

		EXECUTE k_GetErrorInfo @visible = @debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
	END CATCH


	RETURN

END
go

