CREATE   PROCEDURE [dbo].[rep_penalty_new_percent]
(
	  @occ1 INT
	, @sup_id1 INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @StavkaCB DECIMAL(9, 4) = NULL
	, @debug BIT = 0
)
AS
	/*
	
	Расчет пени для отчета с новой ставкой ЦБ за выбранные периоды

EXEC rep_penalty_new_percent
	@occ1 = 31059
	,@sup_id1 = 0
	, @fin_id1 = 230
	, @fin_id2 = 236
	, @StavkaCB = 6.5	
	
EXEC rep_penalty_new_percent
	@occ1 = 31059
	,@sup_id1 = 345
	, @fin_id1 = 230
	, @fin_id2 = 236
	, @StavkaCB = 6.5	

	*/

	SET NOCOUNT ON
	SET LANGUAGE Russian

	SELECT @sup_id1 = COALESCE(@sup_id1, 0)

	IF (@fin_id1 IS NULL)
		OR (@fin_id1 = 0)
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF (@fin_id2 IS NULL)
		SET @fin_id2 = @fin_id1


	-- 1. сохранить текущие данные из Peny_detail во временную таблицу
	SELECT p.fin_id
		 , pa.occ AS occ_sup
		 , pa.occ1 AS occ
		 , pa.sup_id
		 , CAST(NULL AS SMALLDATETIME) AS start_date
		 , p.fin_dolg
		 , p.dat1
		 , p.data1
		 , p.dolg
		 , p.paid_pred
		 , p.peny_old
		 , p.paymaccount_serv AS paymaccount
		 , p.paymaccount_peny
		 , p.peny_old_new
		 , p.dolg_peny
		 , gv.StavkaCB              AS StavkaCB
		 , p.StavkaCB               AS StavkaCB2
		 , p.proc_peny_day          AS proc_peny_day
		 , p.kol_day
		 , p.kol_day_dolg
		 , p.Peny
		 , @StavkaCB                AS StavkaCB_new
		 , CAST(CASE
                    WHEN p.proc_peny_day > 0 THEN @StavkaCB / ROUND(gv.StavkaCB / p.proc_peny_day, 0)
                    ELSE 0
        END AS DECIMAL(9, 4))       AS proc_peny_day_new
		 , CAST(0 AS DECIMAL(9, 2)) AS Peny_new
		 , CAST(0 AS DECIMAL(9, 2)) AS Peny_old_new2
		 , CAST(0 AS DECIMAL(9, 2)) AS Peny_itog_new
		 , 0                        AS fin_number
	INTO #tmp
	FROM dbo.Peny_detail AS p 
		JOIN dbo.Peny_all pa ON p.occ = pa.occ
			AND p.fin_id = pa.fin_id
		JOIN dbo.Global_values gv ON p.fin_id = gv.fin_id
	WHERE pa.occ1 = @occ1
		AND pa.sup_id = @sup_id1
		AND pa.fin_id BETWEEN @fin_id1 AND @fin_id2

	-- 2. выполнить в ней новый расчет (начиная со старых периодов)
	UPDATE #tmp
	SET Peny_new = dolg_peny * 0.01 * proc_peny_day_new * kol_day

	IF @debug=1 SELECT * FROM #tmp ORDER BY fin_id DESC

	-- добавляем итоги по периодам
	INSERT INTO #tmp
	SELECT t.fin_id
		 , MAX(t.occ_sup)
		 , MAX(t.occ)
		 , MAX(t.sup_id)
		 , MAX(cp.start_date) AS start_date
		 , NULL AS fin_dolg
		 , MAX(cp.start_date) AS dat1
		 , MAX(cp.start_date) AS data1
		 , MAX(pa.dolg) AS dolg
		 , MAX(pa.paid_pred) AS paid_pred
		 , MAX(pa.Peny_old) AS Peny_old
		 , MAX(pa.paymaccount) AS paymaccount_serv
		 , MAX(pa.paymaccount_peny) AS paymaccount_peny
		 , MAX(pa.Peny_old_new) AS Peny_old_new
		 , MAX(pa.dolg_peny) AS dolg_peny
		 , MAX(StavkaCB) AS StavkaCB
		 , MAX(StavkaCB2) AS StavkaCB2
		 , 0 AS proc_peny_day
		 , 0 AS kol_day
		 , 0 AS kol_day_dolg
		 , SUM(t.Peny) AS Peny
		 , @StavkaCB AS StavkaCB_new
		 , 0 AS proc_peny_day_new
		 , SUM(t.Peny_new) AS Peny_new
		 , 0 AS Peny_old_new2
		 , 0 AS Peny_itog_new
		 , 0 AS fin_number
	FROM #tmp t
		JOIN dbo.Peny_all pa ON t.occ_sup = pa.occ
			AND t.fin_id = pa.fin_id
			AND t.sup_id = pa.sup_id
		JOIN dbo.Calendar_period cp ON t.fin_id = cp.fin_id
	GROUP BY t.fin_id

	-- подсчитаем Peny_old_new2 и Peny_itog_new
	DECLARE @start_peny_old DECIMAL(9, 2) = 0
	SELECT TOP (1) @start_peny_old = t.peny_old_new
	FROM #tmp t
	WHERE fin_dolg IS NULL
	ORDER BY t.fin_id

	;
	WITH cte AS
	(
		SELECT t.fin_id
			 , ROW_NUMBER() OVER (ORDER BY t.fin_id DESC) AS fin_number
			 , @start_peny_old + COALESCE(SUM(t.peny_new) OVER (ORDER BY t.fin_id
			   ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS Peny_old_new2
			 , @start_peny_old + SUM(t.peny_new) OVER (ORDER BY t.fin_id
			   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Peny_itog_new
		FROM #tmp t
		WHERE fin_dolg IS NULL
	)
	UPDATE T
	SET fin_number = cte.fin_number
	  , Peny_old_new2 = cte.Peny_old_new2
	  , Peny_itog_new = cte.Peny_itog_new
	FROM #tmp AS T
		JOIN cte ON T.fin_id = cte.fin_id
	WHERE T.fin_dolg IS NULL

	-- 3. вывести информацию для отчёта

	SELECT CASE
               WHEN t.sup_id > 0 THEN t.occ_sup
               ELSE dbo.Fun_GetFalseOccOut(t.occ, o.tip_id)
        END AS occ_print
		 , CASE
               WHEN t.fin_dolg IS NULL THEN dbo.Fun_NameFinPeriodDate(t.start_date)
               ELSE cp.StrFinPeriod
        END AS StrMes
		   --, cp.StrMes AS 'Период долга'
		 , t.*
		 , o.address
	FROM #tmp t
		JOIN dbo.Occupations o ON t.occ = o.occ
		LEFT JOIN dbo.Calendar_period cp ON t.fin_dolg = cp.fin_id
	--WHERE t.proc_peny_day>0
	ORDER BY fin_id DESC
		   , t.start_date DESC
		   , t.fin_dolg
go

