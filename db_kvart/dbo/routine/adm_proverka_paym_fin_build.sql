-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Проверка платежей и расчётов по типу фонда
-- =============================================
CREATE             PROCEDURE [dbo].[adm_proverka_paym_fin_build]
(
	  @build_id INT
	, @in_table BIT = 0
	, @fin_id SMALLINT = NULL
	, @debug BIT = 0
	, @is_job BIT = 0 -- Выполняется в JOB
)
AS
/*
EXEC adm_proverka_paym_fin_build @build_id=6768, @in_table=0, @fin_id=244, @debug=0

*/
BEGIN
	SET NOCOUNT ON;

	-- Если запуск по расписанию - то днём (в рабочее время) не делать
	IF @is_job = 1
		AND DATEPART(HOUR, current_timestamp) BETWEEN 9 AND 20
		RETURN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @in_table IS NULL
		SET @in_table = 0
	IF @fin_id = 0
		SET @fin_id = NULL

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @str VARCHAR(200) = ''
		  , @name_test VARCHAR(200) = ''
		  , @time1 DATETIME
		  , @time1_begin DATETIME
		  , @tip_id SMALLINT

	CREATE TABLE #t (
		  occ INT
		, fin_id SMALLINT
		, fin_pred SMALLINT
		, payms_value BIT DEFAULT 1
		, is_cash_serv BIT DEFAULT 0
		, is_penalty_calc_tip BIT DEFAULT 1
		, tip_id SMALLINT DEFAULT NULL
	)
	CREATE INDEX occ ON #t (occ, fin_id)

	INSERT INTO #t (occ
					, fin_id
					, fin_pred
					, payms_value
					, is_cash_serv
					, is_penalty_calc_tip
					, tip_id)
	SELECT o.occ
			, CASE WHEN(@fin_id IS NULL) THEN b.fin_current ELSE @fin_id END
			, CASE WHEN(@fin_id IS NULL) THEN b.fin_current - 1 ELSE @fin_id - 1 END
			, ot.payms_value
			, ot.is_cash_serv
			, ot.penalty_calc_tip
			, b.tip_id
	FROM dbo.Buildings AS b
		JOIN dbo.Occupation_Types ot ON b.tip_id=ot.id
		JOIN dbo.Flats AS f ON b.id=f.bldn_id
		JOIN dbo.Occupations AS o ON f.id=o.flat_id
	WHERE (b.id = @build_id)
		AND b.is_paym_build = 1
		AND ot.raschet_no = 0
		AND ot.only_pasport = 0;
		
	SELECT TOP(1) @tip_id=tip_id FROM #t;

	IF @debug = 1
		SELECT * FROM #t;

	CREATE TABLE #t_out
	--DECLARE @t_out TABLE
	(
		  [data] SMALLDATETIME DEFAULT current_timestamp
		, occ INT
		, summa DECIMAL(15, 4)
		, comments VARCHAR(100) COLLATE database_default
		, fin_id SMALLINT DEFAULT NULL
		, build_id INT DEFAULT NULL
		, tip_id SMALLINT DEFAULT NULL
	)
	--***********************************************************************
	SELECT @time1_begin = current_timestamp
		 , @name_test = N'Проверка-1. Нет оплаты на лицевом (нужен расчёт)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	--region Проверка-1. Нет оплаты на лицевом (нужен перерасчёт)
	SET @time1 = current_timestamp
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (1000) t1.occ
				  , t1.value
				  , comments = @name_test
				  , t1.fin_id				  
	FROM (
		SELECT vp.fin_id
			 , vp.occ
			 , SUM(vp.VALUE) AS VALUE
			 , SUM(vp.paymaccount_peny) AS paymaccount_peny
		FROM dbo.View_payings_lite AS vp 
			JOIN #t AS tt ON vp.occ = tt.occ
				AND tt.fin_id = vp.fin_id
		WHERE vp.forwarded = 1
		GROUP BY vp.fin_id
			   , vp.occ
	) AS t1
		JOIN (
			SELECT pl.fin_id
				 , pl.occ
				 , SUM(pl.paymaccount) AS paymaccount
				 , SUM(pl.paymaccount_peny) AS paymaccount_peny
			FROM dbo.View_paym AS pl 
			JOIN #t AS tt
				ON pl.occ = tt.occ
				AND tt.fin_id = pl.fin_id
			--WHERE pl.sup_id=0
			GROUP BY pl.fin_id
				   , pl.occ
		) AS t2 ON t1.occ = t2.occ
			AND t1.fin_id = t2.fin_id
	WHERE (COALESCE(t1.value, 0) <> COALESCE(t2.paymaccount, 0) OR COALESCE(t1.PaymAccount_peny, 0) <> COALESCE(t2.PaymAccount_peny, 0))
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-2. Оплата не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-2. Оплата не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 t1.occ
				  , t1.value
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Payings AS t1 
		JOIN #t AS tt ON t1.occ = tt.occ
			AND t1.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.value), 0) AS value_serv
			FROM dbo.Paying_serv AS t2 
			WHERE t2.paying_id = t1.id
			GROUP BY t2.paying_id
		) AS t2
	WHERE t1.forwarded = 1
		AND t1.value <> t2.value_serv
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-3. Оплата пени не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-3. Оплата пени не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 t1.occ
				  , value = t1.PaymAccount_peny
				  , comments = N'3.Оплата пени не раскидалась по услугам(заново перераспределите платежи на л/сч)'
				  , tt.fin_id
	FROM dbo.Payings AS t1 
		JOIN #t AS tt ON t1.occ = tt.occ
			AND t1.fin_id = tt.fin_id
	WHERE t1.forwarded = 1
		AND t1.PaymAccount_peny <> COALESCE((
			SELECT SUM(PaymAccount_peny)
			FROM dbo.Paying_serv AS t2 
			WHERE t2.paying_id = t1.id
		), 0)
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-4. Оплата по поставщику не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-4. Оплата по поставщику не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- оплачено по поставщику 
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 t1.occ
				  , value = t1.PaymAccount_peny
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS o
		JOIN [dbo].Payings AS t1  ON o.occ = t1.occ
			AND t1.sup_id = o.sup_id
		JOIN dbo.Paydoc_packs pp ON t1.pack_id = pp.id
			AND o.fin_id = pp.fin_id
		JOIN #t AS tt ON t1.occ = tt.occ
			AND pp.fin_id = tt.fin_id
	WHERE pp.forwarded = 1
		AND t1.value <> COALESCE((
			SELECT SUM(t2.value)
			FROM dbo.Paying_serv AS t2 
			WHERE t2.paying_id = t1.id
		), 0)
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-5. Оплата пени по поставщику не раскидалась в платежах по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-5. Оплата пени по поставщику не раскидалась в платежах по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- оплачено пени по поставщику
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 t1.occ
				  , value = t1.PaymAccount_peny
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS o 
		JOIN dbo.Payings AS t1  ON o.occ = t1.occ
			AND t1.sup_id = o.sup_id
		JOIN dbo.Paydoc_packs pp ON t1.pack_id = pp.id
			AND o.fin_id = pp.fin_id
		JOIN #t AS tt ON t1.occ = tt.occ
			AND pp.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.PaymAccount_peny), 0) AS paym_serv
			FROM dbo.Paying_serv AS t2 
			WHERE t2.paying_id = t1.id
			GROUP BY t2.paying_id
		) AS t2
	WHERE pp.forwarded = 1
		AND t1.PaymAccount_peny <> t2.paym_serv
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-6. Сальдо (или оплата пени) на л.сч <> по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-6. Сальдо (или оплата пени) на л.сч <> по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка сальдо
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , value = o.saldo
				  , comments = @name_test
				  , tt.fin_id				  
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
			AND o.status_id <> N'закр'
			AND o.total_sq > 0

		CROSS APPLY (
			SELECT SUM(pl.SALDO) AS SALDO
				 , SUM(pl.PaymAccount_peny) AS PaymAccount_peny
			FROM dbo.View_paym AS pl 
			WHERE pl.sup_id = 0
				AND (pl.fin_id = o.fin_id)
				AND (pl.occ = o.occ)
			GROUP BY pl.occ
		) AS P
	WHERE (o.saldo <> COALESCE(P.saldo, 0) OR o.PaymAccount_peny <> COALESCE(P.PaymAccount_peny, 0))


	--AND EXISTS (SELECT
	--		1
	--	FROM dbo.View_PAYM AS pl 
	--	WHERE pl.occ = o.occ
	--	AND pl.fin_id = o.fin_id
	--	AND pl.sup_id = 0
	--	GROUP BY pl.occ
	--	HAVING SUM(pl.saldo) <> o.saldo
	--	OR SUM(pl.PaymAccount_peny) <> o.PaymAccount_peny)
	OPTION (RECOMPILE)
	--OPTION (MAXDOP 1)

	--***********************************************************************	
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-6-2. Сальдо (или оплата пени) поставщика <> по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-6-2. Сальдо (или оплата пени) поставщика <> по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка Пени по услугам
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 os.occ
				  , value = os.saldo
				  , comments =
							  CASE
								  WHEN COALESCE(p.saldo, 0) <> os.saldo THEN N'6-2.Сальдо поставщика <> по услугам'
								  WHEN COALESCE(p.PaymAccount_peny, 0) <> os.PaymAccount_peny THEN N'6-2.Оплата пени поставщика <> по услугам'
								  WHEN COALESCE(p.penalty_serv, 0) <> (os.Penalty_value + os.Penalty_added) OR
									  COALESCE(p.Penalty_old, 0) <> os.Penalty_old_new THEN N'11-2.Пени поставщика <> по услугам'
								  ELSE '6-2.?'
							  END
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS os 
		JOIN dbo.Occupations AS o ON os.occ = o.occ
		JOIN #t AS tt ON o.occ = tt.occ
			AND os.fin_id = tt.fin_id
		CROSS APPLY (
			SELECT SUM(pl.saldo) AS saldo
				 , SUM(pl.paymaccount_peny) AS paymaccount_peny
				 , SUM(pl.penalty_serv) AS penalty_serv
				 , SUM(pl.Penalty_old) AS Penalty_old
			FROM dbo.View_paym AS pl
			WHERE pl.occ = os.occ
				AND pl.fin_id = os.fin_id
				AND pl.sup_id = os.sup_id
			GROUP BY pl.occ
		) AS p
	WHERE o.status_id <> N'закр'
		AND o.total_sq > 0
		AND (COALESCE(p.saldo, 0) <> os.saldo OR COALESCE(p.PaymAccount_peny, 0) <> os.PaymAccount_peny OR COALESCE(p.penalty_serv, 0) <> (os.Penalty_value + os.Penalty_added) OR COALESCE(p.Penalty_old, 0) <> os.Penalty_old_new
		)
	OPTION (RECOMPILE)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-7. Сальдо на л.сч по услуге не сходиться с конечным
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-7. Сальдо на л.сч по услуге не сходиться с конечным'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 PL.occ
				  , PL.saldo
				  , comments = N'7.Сальдо на л.сч по услуге ' + PL.service_id + N' не сходиться с конечным'
				  , tt.fin_id
	FROM dbo.View_paym PL 
		JOIN dbo.View_occ_all_lite o  ON PL.occ = o.occ
			AND PL.fin_id = o.fin_id
		JOIN #t AS tt ON o.occ = tt.occ
			AND PL.fin_id = tt.fin_id
	WHERE o.status_id <> N'закр'
		AND o.total_sq > 0
		AND o.saldo_edit = 0
		AND EXISTS (
			SELECT 1
			FROM dbo.Paym_history ph 
			WHERE ph.occ = PL.occ
				AND ph.service_id = PL.service_id
				AND ph.fin_id = tt.fin_pred
				AND ph.sup_id = PL.sup_id
				AND ph.debt <> PL.saldo
		)
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-8. После расчёта пени не сделан перерасчёт
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-8. После расчёта пени не сделан расчёт квартплаты'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , value = o.saldo
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occupations AS o
		JOIN #t AS tt ON o.occ = tt.occ
		LEFT JOIN dbo.Peny_all PS ON o.occ = PS.occ
			AND tt.fin_id = PS.fin_id
	WHERE o.status_id <> N'закр'
		AND o.total_sq > 0
		AND o.Data_rascheta < PS.Data_rascheta
		AND tt.payms_value = 1
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-9. Платежи закрыты без перерасчёта
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-9. Платежи закрыты без расчёта квартплаты'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out WITH (TABLOCKX) (occ
									  , summa
									  , comments
									  , fin_id)
	SELECT TOP 500 o.occ
				 , value = o.saldo
				 , comments = @name_test
				 , tt.fin_id
	FROM dbo.Occupations AS o
		JOIN #t AS tt ON o.occ = tt.occ
		INNER JOIN dbo.Paydoc_packs AS pd ON tt.fin_id = pd.fin_id
		INNER JOIN dbo.Payings AS p ON pd.id = p.pack_id
			AND o.occ = p.occ
	WHERE o.status_id <> N'закр'
		AND o.Data_rascheta < pd.date_edit
	OPTION (RECOMPILE)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-10. Квитанции не обновлены
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-10. Квитанции не обновлены'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (1000) o.occ
				  , o.Whole_payment AS value
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ AND o.fin_id=tt.fin_id
		JOIN dbo.Intprint PS ON o.occ = PS.occ
			AND o.fin_id = PS.fin_id
	WHERE status_id <> N'закр'
		--AND o.data_rascheta > PS.DateCreate
		AND (o.Whole_payment <> PS.SumPaym OR o.Debt <> PS.Debt OR o.PaymAccount_peny <> PS.PaymAccount_peny OR (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) <> PS.Penalty_value
		)

	OPTION (MAXDOP 1)
	--***********************************************************************	
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-11. Пени на л.сч <> Пени по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-11. Пени на л.сч <> Пени по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка Пени по услугам
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , value = (o.Penalty_value + o.Penalty_old_new)
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
		CROSS APPLY (
			SELECT SUM(pl.Penalty_old + pl.penalty_serv) AS Penalty_itog
				 , SUM(pl.Penalty_old) AS Penalty_old_new
				 , SUM(pl.Penalty_old + pl.PaymAccount_peny) AS Penalty_old
			FROM dbo.View_paym AS pl 
			WHERE pl.occ = o.occ
				AND pl.fin_id = o.fin_id
				AND pl.sup_id = 0
			GROUP BY pl.occ
		) AS t
	WHERE o.status_id <> N'закр'
		AND o.total_sq > 0
		AND (o.Penalty_itog <> t.Penalty_itog OR o.Penalty_old_new <> t.Penalty_old_new OR o.Penalty_old <> t.Penalty_old)
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-12. Сальдо на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-12. Сальдо на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , o.saldo
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
	WHERE status_id <> N'закр'
		AND o.total_sq > 0
		AND tt.payms_value = 1
		AND o.saldo_edit = 0
		AND EXISTS (
			SELECT 1
			FROM dbo.Occ_history ph 
			WHERE ph.occ = o.occ
				AND ph.fin_id = tt.fin_pred
				AND ph.debt <> o.saldo
		)
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-13. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-13. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o1.occ
				  , o.saldo
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS o 
		JOIN dbo.View_occ_all_lite AS o1 ON o.occ = o1.occ
			AND o.fin_id = o1.fin_id
		JOIN #t AS tt ON o1.occ = tt.occ
			AND o.fin_id = tt.fin_id
	WHERE o1.status_id <> N'закр'
		AND o1.total_sq > 0
		AND o1.saldo_edit = 0
		AND EXISTS (
			SELECT 1
			FROM dbo.Occ_Suppliers ph 
			WHERE ph.occ = o.occ
				AND ph.fin_id = tt.fin_pred
				AND ph.sup_id = o.sup_id
				AND ph.debt <> o.saldo
		)
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-13.2. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-13.2. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ_sup
				  , o.saldo
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS o 
		JOIN dbo.Occupations AS o1 ON o.occ = o1.occ
		JOIN #t AS tt ON o1.occ = tt.occ
			AND o.fin_id = tt.fin_pred
	WHERE o.debt <> 0
		AND o1.status_id <> N'закр'
		AND o1.total_sq > 0
		AND NOT EXISTS (
			SELECT -- нет текущей строки расчёта по поставщику
				1
			FROM dbo.Occ_Suppliers ph 
			WHERE ph.occ = o.occ
				AND ph.fin_id = tt.fin_id
				AND ph.sup_id = o.sup_id
		--AND ph.saldo <> o.debt
		)
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка 14. Кап.ремонт начисляется?
	IF @DB_NAME IN ('KR1')
	BEGIN
		SET @time1 = current_timestamp
		RAISERROR (N'Проверка 14. Кап.ремонт начисляется?', 10, 1) WITH NOWAIT;
		INSERT INTO #t_out (occ
						  , summa
						  , comments
						  , fin_id)
		SELECT TOP 1000 PL.occ
					  , PL.value
					  , comments = N'14.Кап.ремонт начисляется?'
					  , tt.fin_id
		FROM dbo.View_paym PL 
			JOIN dbo.Occupations AS o ON PL.occ = o.occ
			JOIN #t AS tt ON o.occ = tt.occ
				AND PL.fin_id = tt.fin_id
		WHERE status_id <> N'закр'
			AND o.total_sq > 0
			AND PL.service_id = N'капр'
			AND PL.value > 0
		OPTION (MAXDOP 1)
		SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
		RAISERROR (@str, 10, 1) WITH NOWAIT;
	END
	--endregion

	--region Проверка-15.Расчётного счёта по поставщику нет!
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-15.Расчётного счёта по поставщику нет!'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ_sup
				  , 0
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.Occ_Suppliers AS o 
		JOIN dbo.Occupations AS o1 ON o.occ = o1.occ
		JOIN #t AS tt ON o1.occ = tt.occ
			AND o.fin_id = tt.fin_id
	WHERE status_id <> N'закр'
		AND o1.total_sq > 0
		AND o.rasschet IS NULL
		AND tt.payms_value = 1
		AND o.value > 0
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-16. Сумма пени не совпадает с расчётной
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-16. Сумма пени не совпадает с расчётной'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (1000) o.occ
					, value = o.Penalty_itog
					, comments = @name_test
					, tt.fin_id
	FROM dbo.View_occ_and_sup AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
		JOIN dbo.View_peny_all PS ON o.occ = PS.occ
			AND o.fin_id = PS.fin_id
	WHERE o.Penalty_itog <> PS.debt_peny
	OPTION (MAXDOP 1)

	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-17. Оплата не раскидалась для чеков по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-17. Оплата не раскидалась для чеков по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 t1.occ
				  , t1.value
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_payings_lite AS t1 
		JOIN #t AS tt ON t1.occ = tt.occ
			AND t1.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.value_cash), 0) AS value_cash
			FROM dbo.Paying_cash AS t2 
			WHERE t2.paying_id = t1.id
		) AS t2
	WHERE t1.forwarded = 1
		AND tt.is_cash_serv = 1
		AND t1.value <> t2.value_cash
	OPTION (MAXDOP 1)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-18. Лицевые без режимов
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-18. Лицевые без режимов'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , o.Whole_payment
				  , comments = @name_test
				  , o.fin_id
	FROM dbo.VOcc o 
		JOIN #t AS tt ON o.occ = tt.occ
	WHERE o.status_id <> N'закр'
		AND o.total_sq <> 0
		AND tt.payms_value = 1
		AND (@DB_NAME <> 'NAIM')
		--OR (@DB_NAME='NAIM' AND o.PROPTYPE_ID='непр'))
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Consmodes_list cl
			WHERE cl.occ = o.occ
				AND (cl.mode_id % 1000 <> 0 OR cl.source_id % 1000 <> 0)
		)
	OPTION (MAXDOP 1)

	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-19. Сумма разовых несовпадает с лицевым 
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19. Сумма разовых несовпадает с лиц/сч (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , o.AddedAll
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(ap.value), 0) AS value
			FROM dbo.View_added AS ap 
			WHERE ap.occ = o.occ
				AND ap.fin_id = tt.fin_id
			GROUP BY ap.occ
		) AS t2
	WHERE status_id <> N'закр'
		AND tt.payms_value = 1
		AND o.AddedAll <> t2.value
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-19-2. Сумма разовых по услугам несовпадает с лиц/сч
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-2. Сумма разовых по услугам несовпадает с лиц/сч (нужен расчёт кварплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP 1000 o.occ
				  , o.AddedAll
				  , comments = @name_test
				  , tt.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN #t AS tt ON o.occ = tt.occ
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(ap.Added), 0) AS Added
			FROM dbo.View_paym AS ap 
			WHERE ap.occ = o.occ
				AND ap.fin_id = tt.fin_id
			GROUP BY ap.occ
		) AS t2
	WHERE status_id <> N'закр'
		AND tt.payms_value = 1
		AND o.AddedAll <> t2.Added
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion


	--region Проверка-19-3. Кол-во разовых по услугам несовпадает с перерасчетом
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-3. Кол-во разовых по услугам несовпадает перерасчетом (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (1000) o.occ
					, o.kol
					, o.comments
					, o.fin_id
	FROM (
		SELECT ap.occ
			 , SUM(ap.kol) AS kol
			 , comments = @name_test + ' ' + ap.service_id
			 , o.fin_id
			 , o.tip_id
			 , ap.service_id
		FROM dbo.View_added_lite AS ap 
			JOIN dbo.View_occ_all_lite AS o ON o.occ = ap.occ
				AND o.fin_id = ap.fin_id
			JOIN #t AS tt ON o.occ = tt.occ
				AND o.fin_id = tt.fin_id
		WHERE tt.payms_value = 1
			AND ap.kol IS NOT NULL
		GROUP BY o.fin_id
			   , o.tip_id
			   , ap.occ
			   , ap.service_id
	) AS o
	WHERE EXISTS (
			SELECT SUM(vp.kol_added) AS kol_added
			FROM dbo.View_paym AS vp 
			WHERE vp.occ = o.occ
				AND vp.fin_id = o.fin_id
				AND vp.service_id = o.service_id
				AND vp.kol_added IS NOT NULL
			GROUP BY vp.occ
				   , vp.service_id
			HAVING SUM(vp.kol_added) <> o.kol
		)
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion


	--region Проверка-19-4. Кол-во разовых по услугам несовпадает с перерасчетом
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-4. Кол-во разовых по услугам несовпадает перерасчетом (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (1000) o.occ
					, o.kol
					, o.comments
					, o.fin_id
	FROM (
		SELECT vp.occ
			 , SUM(vp.kol_added) AS kol
			 , comments = @name_test + ' ' + vp.service_id
			 , o.fin_id
			 , o.tip_id
			 , vp.service_id
		FROM dbo.View_paym AS vp
			JOIN dbo.View_occ_all_lite AS o ON o.occ = vp.occ
				AND o.fin_id = vp.fin_id
			JOIN #t AS tt ON o.occ = tt.occ
				AND o.fin_id = tt.fin_id
		WHERE tt.payms_value = 1
			AND vp.kol_added <> 0
		GROUP BY o.fin_id
			   , o.tip_id
			   , vp.occ
			   , vp.service_id
	) AS o
		OUTER APPLY (
			SELECT SUM(COALESCE(ap.kol,0)) AS kol_added
			FROM dbo.View_added_lite AS ap 
			WHERE ap.occ = o.occ
				AND ap.fin_id = o.fin_id
				AND ap.service_id = o.service_id
			GROUP BY ap.occ
				   , ap.service_id
		) AS t2
	WHERE o.kol <> t2.kol_added
		OR t2.kol_added IS NULL
	OPTION (MAXDOP 1)
	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--region Проверка-21. Подозрительный файл с платежами 
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-21. Подозрительный файл с платежами'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	;WITH cte AS (
		SELECT filenamedbf, summa, COUNT(*) AS kol
		FROM dbo.Bank_tbl_spisok
		GROUP BY filenamedbf, summa
		HAVING COUNT(*)>1
		)
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id)
	SELECT TOP (500) P.occ, P.value
				   , comments = @name_test
				   , tt.fin_id
   FROM dbo.Payings AS p 
	JOIN dbo.Paydoc_packs pp  ON p.pack_id = pp.id
	JOIN dbo.Bank_tbl_spisok bts ON p.filedbf_id = bts.filedbf_id
	JOIN #t AS tt ON p.occ = tt.occ
			AND pp.fin_id = tt.fin_id
	WHERE tt.payms_value = 1
	AND EXISTS(			
		SELECT * FROM cte WHERE cte.filenamedbf=bts.filenamedbf
	)

	--***********************************************************************
	SET @str = N'Выполнено за ' + dbo.Fun_GetTimeStr(@time1) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--endregion

	--***********************************************************************
	SET @str = N'Итог выполнения: ' + dbo.Fun_GetTimeStr(@time1_begin) + CHAR(13) + CHAR(10)
	RAISERROR (@str, 10, 1) WITH NOWAIT;

	--**************************
	UPDATE #t_out SET build_id=@build_id, tip_id=@tip_id
	--************ Выдаем результат *******************
	-- Выбираем по 3 ошибки для каждого типа фонда

	IF @debug = 1
		SELECT *
		FROM #t_out

	SELECT [data]
		 , build_id
		 , tip_name
		 , occ
		 , comments
		 , summa
		 , fin_id
		 , toprank
		 , kol_error
		 , kol_error_itogo
	INTO #t2
	FROM (
		SELECT t1.[data]
			 , t1.build_id
			 , ot.[name] AS tip_name
			 , t1.occ
			 , t1.comments
			 , t1.summa
			 , t1.fin_id
			 , DENSE_RANK() OVER (PARTITION BY t1.tip_id, t1.comments ORDER BY occ) AS toprank
			 , COUNT(occ) OVER (PARTITION BY t1.tip_id, t1.comments) AS kol_error
			 , COUNT(occ) OVER () AS kol_error_itogo
		FROM #t_out AS t1
			JOIN dbo.Occupation_Types ot ON t1.tip_id = ot.id
	) AS t
	WHERE toprank <= 3

	IF @in_table = 0
		SELECT *
		FROM #t2

	ELSE
	BEGIN
		RAISERROR (N'Заносим результат в таблицу', 10, 1) WITH NOWAIT;
		TRUNCATE TABLE dbo.Errors_occ
		INSERT INTO dbo.Errors_occ (DATA
								  , occ
								  , summa
								  , comments
								  , fin_id
								  , tip_id
								  , kol_error
								  , kol_error_itogo)
		SELECT DATA
			 , occ
			 , summa
			 , comments
			 , fin_id
			 , build_id
			 , kol_error
			 , kol_error_itogo
		FROM #t2

		IF EXISTS (SELECT 1 FROM #t)
		BEGIN
			DECLARE @msg VARCHAR(MAX)
			SET @msg = N'База: ' + RTRIM(DB_NAME()) + N',Дата:' + CONVERT(CHAR(20), current_timestamp, 113) +
			CHAR(13) + CHAR(10)
			--',Дата:' + CONVERT(CHAR(10), DATA, 104)
			SELECT @msg = @msg +
				CONCAT(N'Лиц: ',occ,',build_id: ',build_id,'(',tip_name,'), ',comments,',(',kol_error,')', CHAR(13) , CHAR(10) )				
			FROM #t2
			--  select @msg
			EXEC dbo.adm_send_mail @msg
		END

	END

END
go

