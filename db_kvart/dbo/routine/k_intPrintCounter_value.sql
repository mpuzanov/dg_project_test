-- =============================================
-- Author:		Пузанов
-- Create date: 13.04.2010
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном лицевом счете
-- k_intPrintCounter_value 135,200590204
-- =============================================
CREATE             PROCEDURE [dbo].[k_intPrintCounter_value]
	@fin_id1	  SMALLINT
   ,@occ1		  INT
   ,@is_inspector BIT = 1 -- выдавать только если есть показания в тек.месяце
AS
/*
EXEC k_intPrintCounter_value @fin_id1=180, @occ1= 680003174, @is_inspector=1
EXEC k_intPrintCounter_value @fin_id1=162, @occ1= 286362, @is_inspector=1
EXEC k_intPrintCounter_value @fin_id1=185, @occ1= 339096, @is_inspector=0
*/
BEGIN
	SET NOCOUNT ON;

	IF @is_inspector IS NULL
		SET @is_inspector = 1

	DECLARE @start_date SMALLDATETIME

	SELECT
		@occ1 = dbo.Fun_GetFalseOccIn(@occ1) -- если на входе был ложный лицевой

	IF @occ1 IS NULL
		SET @occ1 = 0

	IF @fin_id1 IS NULL
		SET @fin_id1 = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	SELECT
		@start_date = start_date
	FROM dbo.GLOBAL_VALUES 
	WHERE fin_id = @fin_id1

	DECLARE @t TABLE
		(
			counter_id			   INT
		   ,service_id			   VARCHAR(10)
		   ,inspector_date		   SMALLDATETIME
		   ,cur_value			   DECIMAL(12, 4)
		   ,pred_value			   DECIMAL(12, 4)
		   ,pred_date			   SMALLDATETIME
		   ,tarif				   DECIMAL(10, 4)
		   ,serial_number		   VARCHAR(20)
		   ,[type]				   VARCHAR(30)
		   ,PeriodCheck			   SMALLDATETIME
		   ,CurValueStr			   VARCHAR(30)
		   ,actual_value		   DECIMAL(12, 4)
		   ,kol_mes_PeriodCheck	   SMALLINT DEFAULT 100
		   ,ras_no_counter_poverka BIT		DEFAULT 0
		)

	INSERT INTO @t
	(counter_id
	,service_id
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
		   ,NULL AS inspector_date
		   ,0 AS cur_value
		   ,0 AS pred_value
		   ,NULL AS pred_date
		   ,0 AS tarif
		   ,C.serial_number
		   ,C.[type]
		   ,CASE
				WHEN B.ras_no_counter_poverka = 1 THEN C.PeriodCheck
				WHEN ot.ras_no_counter_poverka = 1 THEN C.PeriodCheck
				ELSE NULL
			END AS PeriodCheck
		   ,0 AS actual_value
		   ,DATEDIFF(MONTH, @start_date, COALESCE(PeriodCheck, '20500101'))
		   ,CASE
				WHEN B.ras_no_counter_poverka = 1 THEN 1
				WHEN ot.ras_no_counter_poverka = 1 THEN 1
				ELSE 0
			END AS ras_no_counter_poverka
		FROM dbo.COUNTER_LIST_ALL AS cl 
			JOIN dbo.COUNTERS AS C 
				ON cl.counter_id = C.id
			JOIN dbo.OCCUPATIONS AS o
				ON cl.occ = o.occ
			JOIN dbo.OCCUPATION_TYPES AS ot 
				ON ot.id = o.tip_id
			JOIN dbo.BUILDINGS AS B
				ON C.build_id = B.id
		WHERE 1=1
			AND cl.occ = @occ1
			AND cl.fin_id = b.fin_current  -- тек.период
		ORDER BY cl.service_id

	-- 
	UPDATE t
	SET inspector_date = ci.inspector_date
	   ,cur_value	   = COALESCE(ci.inspector_value, 0)
	   ,tarif		   = ci.tarif
	   ,pred_date	   = ci_pred.inspector_date
	   ,pred_value	   = COALESCE(ci_pred.inspector_value, 0)
	   ,actual_value   = COALESCE(ci.actual_value, 0)
	FROM @t AS t
	OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(t.counter_id, @fin_id1) AS ci
	OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(t.counter_id, @fin_id1) AS ci_pred


	UPDATE t
	SET tarif = vp.tarif
	FROM @t AS t
	JOIN View_PAYM vp
		ON t.service_id = vp.service_id
	WHERE vp.occ = @occ1
	AND vp.fin_id = @fin_id1

	--DELETE FROM @t
	--WHERE COALESCE(tarif, 0) = 0

	IF @is_inspector = 1 -- если нет текущих показаний удаляем
		DELETE FROM @t
		WHERE inspector_date IS NULL
			AND (kol_mes_PeriodCheck > 2)

	SELECT
		counter_id
	   ,CASE
			WHEN service_id IN ('хвод', 'хвс2') THEN 'ХВС'
			WHEN service_id IN ('гвод', 'гвс2') THEN 'ГВС'
			WHEN service_id IN ('элек', 'эле2') THEN 'Эл.Энергия'
			WHEN service_id IN ('отоп', 'ото2') THEN 'Отопл'
			ELSE service_id
		END AS service_id
	   ,inspector_date
	   ,cur_value
	   ,pred_value
	   ,pred_date
	   ,CASE
			WHEN service_id = 'элек' THEN tarif
			ELSE 0
		END AS tarif
	   ,dbo.nstr(CASE
			WHEN inspector_date IS NULL THEN NULL
			WHEN cur_value > pred_value THEN cur_value - pred_value
			ELSE actual_value
		END) AS RESULT  --, '###,###.##', 'ru-RU')
	   ,serial_number
	   ,[type]
	   ,dbo.nstr(CASE
			WHEN cur_value > pred_value THEN cur_value
			ELSE pred_value
		END) AS [LAST_VALUE]
	   ,CASE
			WHEN cur_value > pred_value THEN inspector_date
			ELSE pred_date
		END AS last_date
	   ,PeriodCheck
	   ,kol_mes_PeriodCheck
	   ,CASE
			WHEN kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
			WHEN kol_mes_PeriodCheck <= 2 AND
			PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
			ELSE LTRIM(REPLACE(STR(cur_value, 10, 4), '.0000', '') + ' - ' + CONVERT(VARCHAR(15), inspector_date, 4))
		END AS CurValueStr
	   ,CASE
			WHEN kol_mes_PeriodCheck < 0 THEN 'срок поверки истёк!'
			WHEN kol_mes_PeriodCheck <= 2 AND
			PeriodCheck IS NOT NULL THEN 'срок поверки ' + CONVERT(VARCHAR(10), PeriodCheck, 4) + '!'
			ELSE LTRIM(REPLACE(STR(pred_value, 10, 4), '.0000', '')) + ' - ' + LTRIM(REPLACE(STR(cur_value, 10, 4), '.0000', ''))
		END AS CurValueStr2
	FROM @t
	WHERE (inspector_date IS NOT NULL
	OR pred_date IS NOT NULL)
	AND tarif > 0


END
go

