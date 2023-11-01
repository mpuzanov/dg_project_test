-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Проверка платежей и расчётов по типу фонда
-- =============================================
CREATE       PROCEDURE [dbo].[adm_proverka_paym_fin]
(
	  @tip_id SMALLINT = NULL
	, @in_table BIT = 0
	, @fin_id SMALLINT = NULL
	, @debug BIT = 0
	, @is_job BIT = 0 -- Выполняется в JOB
)
AS
/*
adm_proverka_paym_fin @tip_id=28,@in_table=0,@fin_id=203
adm_proverka_paym_fin @tip_id=1,@in_table=0,@fin_id=231,@debug=1
*/
BEGIN
	SET NOCOUNT ON;

	-- Если запуск по расписанию - то днём (в рабочее время) не делать
	IF @is_job = 1
		AND DATEPART(HOUR, current_timestamp) BETWEEN 9 AND 20
		BEGIN
			RAISERROR ('днём (в рабочее время) нельзя', 10, 1) WITH NOWAIT;
			RETURN
		END

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

	CREATE TABLE #t_tip (
		  tip_id SMALLINT
		, fin_id SMALLINT
		, fin_pred SMALLINT
		, payms_value BIT DEFAULT 1
		, is_cash_serv BIT DEFAULT 0
		, is_penalty_calc_tip BIT DEFAULT 1
	)
	CREATE INDEX tip_id ON #t_tip (tip_id, fin_id)

	INSERT INTO #t_tip (tip_id
					  , fin_id
					  , fin_pred
					  , payms_value
					  , is_cash_serv
					  , is_penalty_calc_tip)
	SELECT ot.id
		 , CASE WHEN(@fin_id IS NULL) THEN ot.fin_id ELSE @fin_id END
		 , CASE WHEN(@fin_id IS NULL) THEN ot.fin_id - 1 ELSE @fin_id - 1 END
		 , ot.payms_value
		 , ot.is_cash_serv
		 , ot.penalty_calc_tip
	FROM Occupation_Types ot
	WHERE 
		(@tip_id IS NULL OR ot.id = @tip_id)
		AND (
			(ot.payms_value = CAST(1 AS BIT) -- можно начислять
				AND ot.raschet_no = CAST(0 AS BIT) -- ночной расчет не заблокирован
				AND ot.only_pasport = CAST(0 AS BIT) -- не только паспортный стол
			) 
			OR @DB_NAME IN ('KVART','KOMP_SPDU')
			)

	-- удаляем тип фонда где закрытие было вчера (на след.день всегда есть ошибки)
	DELETE t1
	FROM #t_tip as t1
	WHERE EXISTS(SELECT 1 FROM Occupation_Types_History as t2 
				WHERE t2.id=t1.tip_id 
				AND t2.fin_id=t1.fin_pred
				AND DATEDIFF(Day,t2.FinClosedData,CURRENT_TIMESTAMP)<2);

	IF @debug = 1
		SELECT *
		FROM #t_tip

	CREATE TABLE #t_out
	--DECLARE @t_out TABLE
	(
		  DATA SMALLDATETIME DEFAULT current_timestamp
		, occ INT
		, summa DECIMAL(15, 4)
		, summa2 DECIMAL(15, 4) DEFAULT 0
		, comments VARCHAR(200) COLLATE database_default
		, fin_id SMALLINT DEFAULT NULL
		, tip_id SMALLINT DEFAULT NULL
	)
	--***********************************************************************
	SELECT @time1_begin = current_timestamp
	SET @str = CHAR(13) + CHAR(10) + 'Поехали'
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--region Проверка-1. Нет оплаты на лицевом (нужен перерасчёт)	
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-1. Нет оплаты на лицевом (нужен расчёт)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) t1.occ
				  , t1.value + t1.paymaccount_peny
				  , t2.paymaccount + t2.paymaccount_peny
				  , @name_test as comments
				  , t1.fin_id
				  , t1.tip_id
	FROM (
		SELECT vp.fin_id
			 , vp.occ
			 , MAX(tt.tip_id) AS tip_id
			 , SUM(vp.VALUE) AS VALUE
			 , SUM(vp.paymaccount_peny) AS paymaccount_peny
		FROM Payings AS vp
			JOIN Occupations o 
				ON vp.occ = o.occ
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id
				AND tt.fin_id = vp.fin_id			
		WHERE vp.forwarded = CAST(1 AS BIT) -- платёж закрыт
		GROUP BY vp.fin_id
			   , vp.occ
	) AS t1
		OUTER APPLY (
			SELECT SUM(t2.paymaccount) AS paymaccount, SUM(t2.paymaccount_peny) AS paymaccount_peny
			FROM View_paym AS t2
			WHERE t1.occ = t2.occ AND t1.fin_id = t2.fin_id	 
		) AS t2
	WHERE (COALESCE(t1.value, 0) <> COALESCE(t2.paymaccount, 0)) OR (COALESCE(t1.PaymAccount_peny, 0) <> COALESCE(t2.PaymAccount_peny, 0))
	--OPTION (RECOMPILE)
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-2. Оплата не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-2. Оплата не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) t1.occ
				  , t1.value
				  , t2.value_serv
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Payings AS t1 
		JOIN Paydoc_packs pp ON 
			t1.pack_id = pp.id
		JOIN #t_tip AS tt ON 
			pp.tip_id = tt.tip_id
			AND t1.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.value), 0) AS value_serv
			FROM Paying_serv AS t2 
			WHERE t2.paying_id = t1.id			
		) AS t2
	WHERE t1.forwarded = CAST(1 AS BIT)
		AND t1.value <> t2.value_serv
	OPTION (MAXDOP 1)
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-3. Оплата пени не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-3. Оплата пени не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) t1.occ
				  , t1.PaymAccount_peny
				  , t2.PaymAccount_peny
				  , N'3.Оплата пени не раскидалась по услугам(заново перераспределите платежи на л/сч)' as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Payings AS t1 
		JOIN Paydoc_packs pp ON 
			t1.pack_id = pp.id
		JOIN #t_tip AS tt ON 
			pp.tip_id = tt.tip_id
			AND t1.fin_id = tt.fin_id
		OUTER APPLY (
					SELECT COALESCE(SUM(t2.PaymAccount_peny), 0) AS PaymAccount_peny
					FROM Paying_serv AS t2 
					WHERE t2.paying_id = t1.id
				) AS t2
	WHERE t1.forwarded = 1
		AND t1.PaymAccount_peny <> t2.PaymAccount_peny
	OPTION (MAXDOP 1)
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-4. Оплата по поставщику не раскидалась по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-4. Оплата по поставщику не раскидалась по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- оплачено по поставщику 
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) t1.occ
				  , t1.PaymAccount_peny as value
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS o 
		JOIN Payings AS t1 ON 
			o.occ = t1.occ
			AND t1.sup_id = o.sup_id
		JOIN Paydoc_packs pp ON 
			t1.pack_id = pp.id
			AND o.fin_id = pp.fin_id
		JOIN #t_tip AS tt ON 
			pp.tip_id = tt.tip_id
			AND pp.fin_id = tt.fin_id
	WHERE 1=1
		AND pp.forwarded = CAST(1 AS BIT)
		AND t1.value <> COALESCE((
								SELECT SUM(t2.value)
								FROM Paying_serv AS t2 
								WHERE t2.paying_id = t1.id
								), 0)
	OPTION (MAXDOP 1)
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-5. Оплата пени по поставщику не раскидалась в платежах по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-5. Оплата пени по поставщику не раскидалась в платежах по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- оплачено пени по поставщику
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) t1.occ
				  , t1.PaymAccount_peny
				  , t2.paym_serv
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS o 
		JOIN Payings AS t1 ON 
			o.occ = t1.occ
			AND t1.sup_id = o.sup_id
		JOIN Paydoc_packs pp ON 
			t1.pack_id = pp.id
			AND o.fin_id = pp.fin_id
		JOIN #t_tip AS tt ON 
			pp.tip_id = tt.tip_id
			AND pp.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.PaymAccount_peny), 0) AS paym_serv
			FROM Paying_serv AS t2 
			WHERE t2.paying_id = t1.id
			GROUP BY t2.paying_id
		) AS t2
	WHERE 1=1
		AND pp.forwarded = CAST(1 AS BIT)
		AND t1.PaymAccount_peny <> t2.paym_serv
	OPTION (MAXDOP 1)
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-6. Сальдо (или оплата пени) на л.сч <> по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-6. Сальдо (или оплата пени) на л.сч <> по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка сальдо
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ
				  , o.saldo
				  , P.saldo
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt ON 
			o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
			AND o.status_id <> 'закр'
			AND o.total_sq > 0

		CROSS APPLY (
			SELECT SUM(pl.SALDO) AS SALDO
				 , SUM(pl.PaymAccount_peny) AS PaymAccount_peny
			FROM View_paym AS pl 
			WHERE pl.sup_id = 0
				AND (pl.fin_id = o.fin_id)
				AND (pl.occ = o.occ)
		) AS P
	WHERE (o.saldo <> COALESCE(P.saldo, 0) OR o.PaymAccount_peny <> COALESCE(P.PaymAccount_peny, 0))
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************	
	--endregion

	--region Проверка-6-2. Сальдо (или оплата пени) поставщика <> по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-6-2. Сальдо (или оплата пени) поставщика <> по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка Пени по услугам
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) os.occ
				  , value = os.saldo
				  , CASE
						WHEN COALESCE(p.saldo, 0) <> os.saldo THEN N'6-2.Сальдо поставщика <> по услугам'
						WHEN COALESCE(p.PaymAccount_peny, 0) <> os.PaymAccount_peny THEN N'6-2.Оплата пени поставщика <> по услугам'
						WHEN COALESCE(p.penalty_serv, 0) <> (os.Penalty_value + os.Penalty_added) OR
							COALESCE(p.Penalty_old, 0) <> os.Penalty_old_new THEN N'11-2.Пени поставщика <> по услугам'
						ELSE '6-2.?'
					END as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS os 
		JOIN Occupations AS o ON 
			os.occ = o.occ
		JOIN #t_tip AS tt ON 
			o.tip_id = tt.tip_id
			AND os.fin_id = tt.fin_id
		CROSS APPLY (
			SELECT SUM(pl.saldo) AS saldo
				 , SUM(pl.paymaccount_peny) AS paymaccount_peny
				 , SUM(pl.penalty_serv) AS penalty_serv
				 , SUM(pl.Penalty_old) AS Penalty_old
			FROM View_paym AS pl 
			WHERE pl.occ = os.occ
				AND pl.fin_id = os.fin_id
				AND pl.sup_id = os.sup_id
		) AS p
	WHERE o.status_id <> 'закр'
		AND o.total_sq > 0
		AND (COALESCE(p.saldo, 0) <> os.saldo OR COALESCE(p.PaymAccount_peny, 0) <> os.PaymAccount_peny OR COALESCE(p.penalty_serv, 0) <> (os.Penalty_value + os.Penalty_added) OR COALESCE(p.Penalty_old, 0) <> os.Penalty_old_new
		)
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-7. Сальдо на л.сч по услуге не сходиться с конечным
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-7. Сальдо(или пени) на л.сч по услуге не сходиться с конечным'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) PL.occ
				  , PL.saldo + pl.penalty_prev
				  , t.debt + t.penalty_itog
				  , N'7.Сальдо(или пени) на л.сч по услуге <' + PL.service_id + N'> не сходиться с конечным' as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_paym PL
		JOIN View_occ_all_lite o ON 
			PL.occ = o.occ
			AND PL.fin_id = o.fin_id
		JOIN #t_tip AS tt ON 
			o.tip_id = tt.tip_id
			AND PL.fin_id = tt.fin_id
		CROSS APPLY (
			SELECT ph.debt, (ph.penalty_serv+ph.penalty_old) as penalty_itog
			FROM Paym_history ph
			WHERE ph.occ = PL.occ
				AND ph.service_id = PL.service_id
				AND ph.fin_id = tt.fin_pred
				AND ph.sup_id = PL.sup_id
		) AS t
	WHERE o.status_id <> 'закр'
		AND o.total_sq > 0
		AND (o.saldo_edit = 0 AND o.Penalty_old_edit=0)  -- небыло ручного измения сальдо или пени
		AND (t.debt<> PL.saldo OR t.penalty_itog<>pl.penalty_prev)
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-8. После расчёта пени не сделан перерасчёт
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-8. После расчёта пени не сделан расчёт квартплаты'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ
				  , o.saldo
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occupations AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
		JOIN Flats AS f 
			ON f.id = o.flat_id
		JOIN Buildings AS b 
			ON b.id = f.bldn_id
		LEFT JOIN Peny_all PS 
			ON o.occ = PS.occ
			AND tt.fin_id = PS.fin_id
	WHERE o.status_id <> 'закр'
		AND o.total_sq > 0
		AND o.Data_rascheta < PS.Data_rascheta
		AND tt.payms_value = CAST(1 AS BIT)
		AND b.is_paym_build = CAST(1 AS BIT)
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-9. Платежи закрыты без перерасчёта
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-9. Платежи закрыты без расчёта квартплаты'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
						, summa
						, comments
						, fin_id
						, tip_id)
	SELECT TOP (500) o.occ
				 , o.saldo
				 , @name_test as comments
				 , tt.fin_id
				 , tt.tip_id
	FROM Occupations AS o
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
		JOIN Paydoc_packs AS pd 
			ON tt.fin_id = pd.fin_id
		JOIN Payings AS p 
			ON pd.id = p.pack_id
			AND o.occ = p.occ
	WHERE o.status_id <> 'закр'
		AND o.Data_rascheta < pd.date_edit
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-10. Квитанции не обновлены
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-10. Квитанции не обновлены'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ
				  , o.whole_payment
				  , PS.SumPaym
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id 
			AND o.fin_id=tt.fin_id
		JOIN Intprint PS 
			ON o.occ = PS.occ
			AND o.fin_id = PS.fin_id
	WHERE status_id <> 'закр'
		--AND o.data_rascheta > PS.DateCreate
		AND (o.whole_payment <> PS.SumPaym OR o.Debt <> PS.Debt OR o.PaymAccount_peny <> PS.PaymAccount_peny OR (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) <> PS.Penalty_value
		)
	OPTION (RECOMPILE, MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************	
	--endregion

	--region Проверка-11. Пени на л.сч <> Пени по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-11. Пени на л.сч <> Пени по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	-- Проверка Пени по услугам
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ
				  , (o.Penalty_value + o.Penalty_old_new)
				  , t.Penalty_itog
				  , @name_test
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT SUM(pl.Penalty_old + pl.penalty_serv) AS Penalty_itog
				 , SUM(pl.Penalty_old) AS Penalty_old_new
				 , SUM(pl.Penalty_old + pl.PaymAccount_peny) AS Penalty_old
			FROM View_paym AS pl 
			WHERE pl.occ = o.occ
				AND pl.fin_id = o.fin_id
				AND pl.sup_id = 0
		) AS t
	WHERE o.status_id <> 'закр'
		--AND o.total_sq > 0
		AND (o.Penalty_itog <> t.Penalty_itog OR o.Penalty_old_new <> t.Penalty_old_new OR o.Penalty_old <> t.Penalty_old)
	OPTION (RECOMPILE)

	--***********************************************************************	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;

	SET @time1 = current_timestamp
	RAISERROR ('Проверка-11-2. Пени на л.сч поставщика <> Пени по услугам', 10, 1) WITH NOWAIT;
	-- Проверка Пени по услугам
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) os.occ_sup
				  , os.debt_peny
				  , t.Penalty_itog
				  , @name_test
				  , tt.fin_id
				  , tt.tip_id
	FROM VOcc_Suppliers AS os 
		JOIN Occupations AS o 
			ON os.occ = o.occ 
			AND os.fin_id=o.fin_id
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND  os.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT SUM(pl.Penalty_old + pl.penalty_serv) AS Penalty_itog
				 , SUM(pl.Penalty_old) AS Penalty_old_new
				 , SUM(pl.Penalty_old + pl.PaymAccount_peny) AS Penalty_old
			FROM View_paym AS pl 
			WHERE pl.occ = o.occ
				AND pl.fin_id = o.fin_id
				AND pl.sup_id = os.sup_id
		) AS t
	WHERE o.status_id <> 'закр'
		AND (
		(os.debt_peny <> t.Penalty_itog OR os.Penalty_old_new <> t.Penalty_old_new OR os.Penalty_old <> t.Penalty_old)
		OR
		(os.debt_peny<>0 AND t.Penalty_itog is NULL))
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-12. Сальдо на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-12. Сальдо(или пени) на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ
				  , o.saldo
				  , t2.Debt
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		CROSS APPLY (SELECT ph.debt
			FROM Occ_history ph 
			WHERE ph.occ = o.occ
				AND ph.tip_id=o.tip_id  -- чтобы тип тоже совпадал
				AND ph.fin_id = tt.fin_pred) as t2
	WHERE status_id <> 'закр'
		AND o.total_sq > 0
		AND tt.payms_value = CAST(1 AS BIT)
		AND o.saldo_edit = 0
		AND o.saldo <> t2.Debt
	OPTION (RECOMPILE, MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-13. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-13. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o1.occ
				  , o.saldo
				  , t.debt
				  , @name_test AS comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS o
		JOIN View_occ_all_lite AS o1 
			ON o.occ = o1.occ
			AND o.fin_id = o1.fin_id
		JOIN #t_tip AS tt ON 
			o1.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT ph.debt
			FROM Occ_Suppliers ph 
			WHERE ph.occ = o.occ
				AND ph.fin_id = tt.fin_pred
				AND ph.sup_id = o.sup_id) AS t				
	WHERE o1.status_id <> 'закр'
		AND o1.total_sq > 0
		AND o1.saldo_edit = 0
		AND t.debt <> o.saldo
	OPTION (RECOMPILE, MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-13.2. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-13.2. Сальдо поставщика на л.сч не сходиться с конечным прошлого периода'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ_sup
				  , o.saldo
				  , @name_test AS comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS o 
		JOIN Occupations AS o1 
			ON o.occ = o1.occ
		JOIN #t_tip AS tt 
			ON o1.tip_id = tt.tip_id
		JOIN Flats as f 
			ON o1.flat_id=f.id				
		JOIN Buildings as b 
			ON f.bldn_id=b.id
			AND o.fin_id = b.fin_current-1
	WHERE o.debt <> 0
		AND o1.status_id <> 'закр'
		AND o1.total_sq > 0
		AND NOT EXISTS (
			SELECT -- нет текущей строки расчёта по поставщику
				1
			FROM Occ_Suppliers ph 
			WHERE ph.occ = o.occ
				AND ph.fin_id = b.fin_current --tt.fin_id
				AND ph.sup_id = o.sup_id
		--AND ph.saldo <> o.debt
		)
	OPTION (MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка 14. Кап.ремонт начисляется?
	IF @DB_NAME IN ('KR1')
	BEGIN
		SET @time1 = current_timestamp
		RAISERROR (N'Проверка 14. Кап.ремонт начисляется?', 10, 1) WITH NOWAIT;
		INSERT INTO #t_out (occ
						  , summa
						  , comments
						  , fin_id
						  , tip_id)
		SELECT TOP(1000) PL.occ
					  , PL.value
					  , N'14.Кап.ремонт начисляется?' as comments
					  , tt.fin_id
					  , tt.tip_id
		FROM View_paym PL 
			JOIN Occupations AS o 
				ON PL.occ = o.occ
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id
				AND PL.fin_id = tt.fin_id
		WHERE status_id <> 'закр'
			AND o.total_sq > 0
			AND PL.service_id = 'капр' -- старый код услуги
			AND PL.value > 0
		OPTION (MAXDOP 1)

		SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
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
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ_sup
				  , 0
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM Occ_Suppliers AS o
		JOIN Occupations AS o1 
			ON o.occ = o1.occ
		JOIN #t_tip AS tt ON o1.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
	WHERE status_id <> 'закр'
		AND o1.total_sq > 0
		AND o.rasschet IS NULL
		AND tt.payms_value = 1
		AND o.value > 0
	OPTION (MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-16. Сумма пени не совпадает с расчётной
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-16. Сумма пени не совпадает с расчётной'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ
					, o.Penalty_itog AS [value]
					, PS.debt_peny
					, @name_test as comments
					, tt.fin_id
					, tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		JOIN Peny_all PS 
			ON o.occ = PS.occ 
			AND ps.sup_id=0
			AND o.fin_id = PS.fin_id 
			AND o.Penalty_itog <> PS.debt_peny	
	UNION
	SELECT TOP (1000) os.occ_sup
					, os.debt_peny AS [value]
					, PS.debt_peny
					, comments = @name_test
					, tt.fin_id
					, tt.tip_id
	FROM VOcc_Suppliers AS os 
		JOIN Occupations AS o 
			ON o.occ=os.occ
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id 
			AND os.fin_id = tt.fin_id			
		JOIN Peny_all PS 
			ON os.occ_sup = PS.occ
			AND os.fin_id = PS.fin_id 
			AND os.sup_id=ps.sup_id 
			AND os.debt_peny <> PS.debt_peny	
	OPTION (MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-17. Оплата не раскидалась для чеков по услугам
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-17. Оплата не раскидалась для чеков по услугам'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) t1.occ
				  , t1.[value]
				  , t2.value_cash
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_payings_lite AS t1
		JOIN #t_tip AS tt 
			ON t1.tip_id = tt.tip_id
			AND t1.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(t2.value_cash), 0) AS value_cash
			FROM Paying_cash AS t2 
			WHERE t2.paying_id = t1.id
		) AS t2
	WHERE t1.forwarded = 1
		AND tt.is_cash_serv = 1
		AND t1.[value] <> t2.value_cash
	OPTION (MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-18. Лицевые без режимов
	--SELECT @time1 = current_timestamp
	--	 , @name_test = N'Проверка-18. Лицевые без режимов'
	--RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	--INSERT INTO #t_out (occ
	--				  , summa
	--				  , comments
	--				  , fin_id
	--				  , tip_id)
	--SELECT TOP(1000) o.occ
	--			  , o.whole_payment
	--			  , @name_test as comments
	--			  , o.fin_id
	--			  , o.tip_id
	--FROM VOcc o
	--	JOIN Flats as f ON 
	--		o.flat_id=f.id
	--	JOIN Buildings as b ON 
	--		b.id=f.bldn_id
	--	JOIN #t_tip AS tt ON 
	--		o.tip_id = tt.tip_id
	--WHERE o.status_id <> 'закр'
	--	AND o.total_sq <> 0
	--	AND tt.payms_value = CAST(1 AS BIT)
	--	AND b.is_paym_build = CAST(1 AS BIT)
	--	AND (@DB_NAME <> 'NAIM')
	--	--OR (@DB_NAME='NAIM' AND o.PROPTYPE_ID='непр'))
	--	AND NOT EXISTS (
	--		SELECT 1
	--		FROM Consmodes_list cl
	--		WHERE cl.occ = o.occ
	--			AND (cl.mode_id % 1000 <> 0 OR cl.source_id % 1000 <> 0)
	--	)
	--OPTION (MAXDOP 1)

	--SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	--RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-19. Сумма разовых несовпадает с лицевым 
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19. Сумма разовых несовпадает с лиц/сч (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ
				  , o.AddedAll
				  , t2.[value]
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o 
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(ap.value), 0) AS value
			FROM View_added_lite AS ap 
			WHERE ap.occ = o.occ
				AND ap.fin_id = tt.fin_id
			--GROUP BY ap.occ
		) AS t2
	WHERE o.status_id <> 'закр'
		AND tt.payms_value = CAST(1 AS BIT)
		AND o.AddedAll <> t2.[value]
	OPTION (MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-19-2. Сумма разовых по услугам несовпадает с лиц/сч
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-2. Сумма разовых по услугам несовпадает с лиц/сч (нужен расчёт кварплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP(1000) o.occ
				  , o.AddedAll
				  , t2.Added
				  , @name_test as comments
				  , tt.fin_id
				  , tt.tip_id
	FROM View_occ_all_lite AS o
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id
			AND o.fin_id = tt.fin_id
		OUTER APPLY (
			SELECT COALESCE(SUM(ap.Added), 0) AS Added
			FROM View_paym AS ap 
			WHERE ap.occ = o.occ
				AND ap.fin_id = tt.fin_id
			--GROUP BY ap.occ
		) AS t2
	WHERE status_id <> 'закр'
		AND tt.payms_value = CAST(1 AS BIT)
		AND o.AddedAll <> t2.Added
	OPTION (RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion


	--region Проверка-19-3. Кол-во разовых по услугам несовпадает с перерасчетом
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-3. Кол-во разовых по услугам несовпадает перерасчетом (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ
					, o.kol
					, o.comments as comments
					, o.fin_id
					, o.tip_id
	FROM (
		SELECT ap.occ
			 , SUM(COALESCE(ap.kol,0)) AS kol
			 , comments = @name_test + ' ' + ap.service_id
			 , o.fin_id
			 , o.tip_id
			 , ap.service_id
		FROM View_added_lite AS ap 
			JOIN View_occ_all_lite AS o 
				ON o.occ = ap.occ
				AND o.fin_id = ap.fin_id
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id
				AND o.fin_id = tt.fin_id
		WHERE tt.payms_value = CAST(1 AS BIT)
		GROUP BY o.fin_id
			   , o.tip_id
			   , ap.occ
			   , ap.service_id
	) AS o
	WHERE EXISTS (
			SELECT SUM(COALESCE(vp.kol_added,0)) AS kol_added
			FROM View_paym AS vp
			WHERE vp.occ = o.occ
				AND vp.fin_id = o.fin_id
				AND vp.service_id = o.service_id
			HAVING SUM(COALESCE(vp.kol_added,0)) <> o.kol
		)
	OPTION (RECOMPILE, MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion


	--region Проверка-19-4. Кол-во разовых по услугам несовпадает с перерасчетом
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-19-4. Кол-во разовых по услугам несовпадает перерасчетом (нужен расчёт квартплаты)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (1000) o.occ
					, o.kol
					, t2.kol_added
					, o.comments as comments
					, o.fin_id
					, o.tip_id
	FROM (
		SELECT vp.occ
			 , SUM(COALESCE(vp.kol_added,0)) AS kol
			 , comments = @name_test + ' ' + vp.service_id
			 , o.fin_id
			 , o.tip_id
			 , vp.service_id
		FROM View_paym AS vp 
			JOIN View_occ_all_lite AS o 
				ON o.occ = vp.occ
				AND o.fin_id = vp.fin_id
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id
				AND o.fin_id = tt.fin_id
		WHERE tt.payms_value = CAST(1 AS BIT)
		GROUP BY o.fin_id
			   , o.tip_id
			   , vp.occ
			   , vp.service_id
		) AS o
		OUTER APPLY (
			SELECT 
				SUM(COALESCE(ap.kol,0)) AS kol_added
			FROM View_added_lite_short AS ap
			WHERE 
				ap.occ = o.occ
				AND ap.fin_id = o.fin_id
				AND ap.service_id = o.service_id
		) AS t2
	WHERE o.kol <> t2.kol_added
		OR (o.kol<>0 AND t2.kol_added IS NULL)
	OPTION (RECOMPILE, MAXDOP 1)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-20. Нет оплаты пени 
	--SELECT @time1 = current_timestamp
	--	 , @name_test = N'Проверка-20. Нет оплаты пени  (нужен расчёт пени)'
	--RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	--INSERT INTO #t_out (occ
	--				  , summa
	--				  , comments
	--				  , fin_id
	--				  , tip_id)
	--SELECT TOP (500) o.occ
	--			   , o.paymaccount_peny
	--			   , comments = @name_test
	--			   , tt.fin_id
	--			   , tt.tip_id
	--FROM View_occ_all_lite AS o 
	--	JOIN #t_tip AS tt ON o.tip_id = tt.tip_id
	--		AND o.fin_id = tt.fin_id
	--WHERE status_id <> 'закр'
	--	AND tt.payms_value = CAST(1 AS BIT)
	--	AND o.paymaccount > 0
	--	AND o.paymaccount > o.saldo
	--	AND (o.Penalty_old > 0 AND o.penalty_value >= 0)
	--	AND o.paymaccount_peny = 0
	--	AND tt.is_penalty_calc_tip = 1
	--	AND @DB_NAME <> 'NAIM' -- когда до 1 числа оплата то оплаты пени нет
	--UNION
	--SELECT TOP (500) o.occ_sup
	--			   , o.paymaccount_peny
	--			   , comments = @name_test
	--			   , tt.fin_id
	--			   , tt.tip_id
	--FROM Occ_Suppliers AS o 
	--	JOIN Occupations o1 ON o.occ = o1.occ
	--	JOIN #t_tip AS tt ON o1.tip_id = tt.tip_id
	--		AND o.fin_id = tt.fin_id
	--WHERE status_id <> 'закр'
	--	AND tt.payms_value = CAST(1 AS BIT)
	--	AND o.paymaccount > 0
	--	AND o.paymaccount > o.saldo
	--	AND (o.Penalty_old > 0 AND o.penalty_value >= 0)
	--	AND o.paymaccount_peny = 0
	--	AND o.Penalty_calc = 1
	--	AND tt.is_penalty_calc_tip = 1
	--	AND @DB_NAME <> 'NAIM'
	--OPTION (MAXDOP 1)
	--SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	--RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-21. Подозрительный файл с платежами 
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-21. Подозрительный файл с платежами. Двойной файл:'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	;WITH cte AS (
		SELECT filenamedbf, summa, COUNT(*) AS kol
		FROM Bank_tbl_spisok
		GROUP BY filenamedbf, summa
		HAVING COUNT(*)>1
		)
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT TOP (500) P.occ, P.value
				   , concat(@name_test,' ',bts.filenamedbf) as comments
				   , tt.fin_id
				   , tt.tip_id
   FROM Payings AS p 
	JOIN Paydoc_packs pp 
		ON p.pack_id = pp.id
	JOIN Bank_tbl_spisok bts 
		ON p.filedbf_id = bts.filedbf_id
	JOIN #t_tip AS tt ON pp.tip_id = tt.tip_id
			AND pp.fin_id = tt.fin_id
	WHERE tt.payms_value = CAST(1 AS BIT)
	AND EXISTS(			
		SELECT * FROM cte WHERE cte.filenamedbf=bts.filenamedbf
	)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion


	--region Проверка-22. Проверка объёмов Водоотведения = ХВС + ГВС 
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-22. Проверка объёмов Водоотведения = ХВС + ГВС (№ 888)'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , summa2
					  , comments
					  , fin_id
					  , tip_id)
	
	SELECT TOP(1000) 
		t1.occ,
		t1.kol_v + t1.kol_v_added1, 
		t2.kol2 + t2.kol_added2,
		@name_test,
		t1.fin_id,
		t1.tip_id	
	FROM (
		SELECT 
		p1.fin_id, p1.occ, MIN(o.tip_id) as tip_id, sum(p1.kol) AS kol_v, sum(p1.kol) AS kol_v_added1
		FROM view_added p1
			JOIN Occupations AS o 
				ON o.Occ=p1.occ
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id 
				AND p1.fin_id = tt.fin_id
		WHERE p1.service_id in ('вотв', 'вот2')
			AND p1.Value<>0
			AND p1.doc_no='888'
			and p1.add_type=12
		GROUP BY p1.fin_id, p1.occ
		) AS t1
		JOIN 
		(
		SELECT 
			p2.fin_id, p2.occ, MIN(o.tip_id) as tip_id, sum(p2.kol) AS kol2, sum(p2.kol) AS kol_added2
		FROM view_added p2
			JOIN Occupations AS o 
				ON o.Occ=p2.occ
			JOIN #t_tip AS tt 
				ON o.tip_id = tt.tip_id 
				AND p2.fin_id = tt.fin_id
		WHERE p2.service_id in ('хвод', 'хвс2', 'гвод','гвс2')
			AND p2.doc_no='888'
			and p2.add_type=12
		GROUP BY p2.fin_id, p2.occ
		) AS t2 ON t1.Occ=t2.Occ
	JOIN Occupation_Types as ot ON 
		t1.tip_id=ot.id 
		AND ot.is_vozvrat_votv_sum=1
	WHERE t1.kol_v<>t2.kol2 OR t1.kol_v_added1<>t2.kol_added2
	OPTION(RECOMPILE)

	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-23. Проверка объёмов Водоотведения СОИ = ХВС СОИ + ГВС СОИ
	--SELECT @time1 = current_timestamp
	--	 , @name_test = N'Проверка-23. Проверка объёмов Водоотведения СОИ = ХВС СОИ + ГВС СОИ'
	--RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	--INSERT INTO #t_out (occ
	--				  , summa
	--				  , summa2
	--				  , comments
	--				  , fin_id
	--				  , tip_id)
	
	--SELECT TOP (1000) 
	--	t1.occ, 
	--	t1.kol_v + t1.kol_v_added1, 
	--	t2.kol2 + t2.kol_added2,
	--	@name_test,
	--	t1.fin_id,
	--	t1.tip_id	
	--FROM (
	--	SELECT 
	--		p1.fin_id, p1.occ, MIN(o.tip_id) as tip_id, sum(p1.kol) AS kol_v, sum(p1.kol_added) AS kol_v_added1
	--	FROM View_paym p1
	--		JOIN Occupations AS o 
	--			ON o.Occ=p1.occ
	--		JOIN #t_tip AS tt 
	--			ON o.tip_id = tt.tip_id 
	--			AND p1.fin_id = tt.fin_id
	--	WHERE p1.service_id in ('одвж')
	--		AND p1.Value<>0
	--	GROUP BY p1.fin_id, p1.occ
	--	) AS t1
	--	JOIN 
	--	(
	--	SELECT 
	--		p2.fin_id, p2.occ, MIN(o.tip_id) as tip_id, sum(p2.kol) AS kol2, sum(p2.kol_added) AS kol_added2
	--	FROM View_paym p2
	--		JOIN Occupations AS o 
	--			ON o.Occ=p2.occ
	--		JOIN #t_tip AS tt 
	--			ON o.tip_id = tt.tip_id 
	--			AND p2.fin_id = tt.fin_id
	--	WHERE p2.service_id in ('одхж', 'одгж')
	--	GROUP BY p2.fin_id, p2.occ
	--	) AS t2 ON t1.Occ=t2.Occ
	--JOIN Occupation_Types as ot 
	--	ON t1.tip_id=ot.id 
	--	AND (ot.soi_votv_fact=1 AND ot.soi_metod_calc='CALC_KOL')
	--WHERE t1.kol_v<>t2.kol2 OR t1.kol_v_added1<>t2.kol_added2
	--OPTION(RECOMPILE)

	--SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	--RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-24. Проверка Оплаты без долга
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-24. Проверка Оплаты без долга'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	
	SELECT TOP (1000) pl.occ, 
			pl.paymaccount, 
			CONCAT(@name_test ,' - ' , pl.service_id),
			tt.fin_id,
			tt.tip_id	
	FROM View_paym as pl
		JOIN Buildings as b 
			ON b.id=pl.build_id
		JOIN #t_tip AS tt 
			ON b.tip_id = tt.tip_id 
			AND pl.fin_id = tt.fin_id
		LEFT JOIN Services_build as sb 
			ON sb.build_id=b.id 
			AND sb.service_id=pl.service_id
	WHERE 1=1
		and pl.paymaccount>0
		and ((pl.saldo+pl.paid)<=0 AND sb.paym_blocked=CAST(1 AS BIT))
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-25. Поиск ошибочных лицевых без автовозвратов
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-25. Поиск ошибочных лицевых без автовозвратов'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	SELECT top(100) pl.occ
			,pl.Value
			,@name_test as comments
			,tt.fin_id
			,tt.tip_id
	FROM View_paym as pl
		JOIN Buildings as b 
			ON b.id=pl.build_id
		JOIN #t_tip AS tt 
			ON b.tip_id = tt.tip_id 
			AND pl.fin_id = tt.fin_id
		JOIN View_paym as pl2 
			ON pl.occ=pl2.occ 
			AND pl.service_id=pl2.service_id 
			and pl2.fin_id=pl.fin_id-1 
			AND pl2.sup_id=pl.sup_id
	WHERE pl.metod=3
		and pl.service_id in ('хвод','гвод')
		and pl2.metod<3
		and pl.value>0
		and pl2.value>0
		and pl2.is_counter>0
		AND NOT EXISTS(SELECT 1  -- нет возвратов
			FROM View_added as ap WHERE ap.occ=pl.occ AND ap.service_id=pl.service_id AND ap.fin_id=pl.fin_id and ap.add_type=12 -- and ap.doc_no in ('888','889')
			)	
		AND NOT EXISTS(SELECT 1  -- нет закрытых ипу
			FROM Counter_list_all as ca
				JOIN Counters as c 
					ON ca.counter_id=c.id
			WHERE ca.occ=pl.occ 
			AND c.service_id=pl.service_id 
			AND ca.fin_id=pl2.fin_id 
			AND c.date_del is not null)

		AND NOT EXISTS(SELECT 1  -- нет показаний инспектора
			FROM Counter_list_all as ca
				JOIN Counter_inspector as ci ON 
					ca.counter_id=ci.counter_id
			WHERE ca.occ=pl.occ 
				AND ca.service_id=pl.service_id 
				AND ca.fin_id=pl2.fin_id 
				AND ci.tip_value=0
				)	
		
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--region Проверка-26. Проверка двойных лицевых поставщика
	SELECT @time1 = current_timestamp
		 , @name_test = N'Проверка-26. Проверка двойных лицевых поставщика'
	RAISERROR (@name_test, 10, 1) WITH NOWAIT;
	INSERT INTO #t_out (occ
					  , summa
					  , comments
					  , fin_id
					  , tip_id)
	
	SELECT TOP (100) os.occ_sup, 
			os.cnt,
			@name_test,
			tt.fin_id,
			tt.tip_id	
	FROM Occupations as o		
		JOIN #t_tip AS tt 
			ON o.tip_id = tt.tip_id 
			AND o.fin_id = tt.fin_id
		CROSS APPLY (
			SELECT occ_sup, COUNT(occ_sup) as cnt
			from Occ_Suppliers
			WHERE fin_id=o.fin_id
			GROUP BY occ_sup
			HAVING COUNT(occ_sup)>1
			) as os
	WHERE 
		o.status_id <> 'закр'
	
	SET @str = concat('Выполнено за ', dbo.Fun_GetTimeStr(@time1), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;
	--***********************************************************************
	--endregion

	--***********************************************************************
	SET @str = concat('Итог выполнения: ', dbo.Fun_GetTimeStr(@time1_begin), CHAR(13), CHAR(10))
	RAISERROR (@str, 10, 1) WITH NOWAIT;

	--************ Выдаем результат *******************
	-- Выбираем по 3 ошибки для каждого типа фонда

	IF @debug = 1
		SELECT *
		FROM #t_out

	DROP TABLE IF EXISTS Errors_occ_all; 
	SELECT * INTO Errors_occ_all FROM #t_out;

	SELECT DATA
		 , tip_id
		 , tip_name
		 , occ
		 , comments
		 , summa
		 , summa2
		 , fin_id
		 , toprank
		 , kol_error
		 , kol_error_itogo
	INTO #t
	FROM (
		SELECT t1.[DATA]
			 , t1.tip_id
			 , ot.[name] AS tip_name
			 , t1.occ
			 , t1.comments
			 , t1.summa
			 , t1.summa2
			 , t1.fin_id
			 , DENSE_RANK() OVER (PARTITION BY t1.tip_id, t1.comments ORDER BY occ) AS toprank
			 , COUNT(occ) OVER (PARTITION BY t1.tip_id, t1.comments) AS kol_error
			 , COUNT(occ) OVER () AS kol_error_itogo
		FROM #t_out AS t1
			JOIN Occupation_Types ot ON 
				t1.tip_id = ot.id
	) AS t
	WHERE toprank <= 3;

	IF @in_table = 0
		SELECT *
		FROM #t

	ELSE
	BEGIN
		RAISERROR (N'Заносим результат в таблицу', 10, 1) WITH NOWAIT;
		TRUNCATE TABLE Errors_occ;
		INSERT INTO Errors_occ (DATA
								  , occ
								  , summa
								  , summa2
								  , comments
								  , fin_id
								  , tip_id
								  , kol_error
								  , kol_error_itogo)
		SELECT DATA
			 , occ
			 , summa
			 , summa2
			 , comments
			 , fin_id
			 , tip_id
			 , kol_error
			 , kol_error_itogo
		FROM #t;

		IF EXISTS (SELECT 1 FROM #t)
		BEGIN
			DECLARE @msg VARCHAR(MAX)
			SET @msg = N'База: ' + RTRIM(DB_NAME()) + N',Дата:' + CONVERT(CHAR(20), current_timestamp, 113) +
			CHAR(13) + CHAR(10)
			--',Дата:' + CONVERT(CHAR(10), DATA, 104)
			SELECT @msg = @msg +
				CONCAT(N'Лиц: ', occ,',tip_id: ',tip_id,'(',tip_name,'), ',comments,',(',kol_error,')',CHAR(13) , CHAR(10) )				
			FROM #t
			--  select @msg
			EXEC adm_send_mail @msg
		END

	END

END
go

