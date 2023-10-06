CREATE   PROCEDURE [dbo].[adm_info_basa]
(
	@tip_id1 SMALLINT = NULL
   ,@fin_id1 SMALLINT = NULL
   ,@fin_all BIT	  = 0  -- обновить все фин.периоды
   ,@debug	 BIT	  = 0
)
AS
	/*
	 Процедура получения общей информации по базе

	exec adm_info_basa @tip_id1=28,@fin_all=1,@debug=1
	exec adm_info_basa @tip_id1=null

	*/
	SET NOCOUNT ON
	--SET ANSI_WARNINGS OFF  -- чтобы не выдавалось: Внимание! Значение NULL исключено в статистических или других операциях SET

	-- 30 сек ждем блокировку  в этой сесии пользователя
	SET LOCK_TIMEOUT 30000

	IF dbo.Fun_GetRejimAdm() = N'стоп'
		RETURN 0

	DECLARE @KolLic				   INT
		   ,@KolBuilds			   INT
		   ,@KolFlats			   INT
		   ,@KolPeople			   INT
		   ,@StrFinPeriod		   VARCHAR(15)
		   ,@start_date			   SMALLDATETIME
		   ,@SumOplata1			   DECIMAL(15, 2) -- сумма к оплате в текущем периоде
		   ,@SumValue1			   DECIMAL(15, 2) -- сумма начислений в текущем периоде
		   ,@SumLgota1			   DECIMAL(15, 2) -- сумма льгот в текущем периоде
		   ,@SumSubsidia1		   DECIMAL(15, 2) -- сумма субсидий в текущем периоде
		   ,@SumAdded1			   DECIMAL(15, 2) -- сумма разовых в текущем периоде
		   ,@SumPaymAccount1	   DECIMAL(15, 2) -- сумма платежей в текущем периоде
		   ,@SumPaymAccount_Peny1  DECIMAL(15, 2) -- из них оплачено пени
		   ,@SumPaymAccountCounter DECIMAL(15, 2) -- оплачено по счетчикам
		   ,@SumPenalty1		   DECIMAL(15, 2) -- сумма пени в текущем периоде
		   ,@SumSaldo1			   DECIMAL(15, 2) -- сумма сальдо в текущем периоде
		   ,@SumOplataMes1		   DECIMAL(15, 2)
		   ,@SumTotal_SQ		   DECIMAL(15, 2) -- Общая площадь
		   ,@SumDolg			   DECIMAL(15, 2) -- сумма долга
		   ,@SumPaid_old		   DECIMAL(15, 2) -- Начисление предыдущего месяца
		   ,@ProcentOplata		   DECIMAL(15, 4)  -- Процент оплаты 
		   ,@sup_id1			   INT
		   ,@sup_name1			   VARCHAR(50)

	DECLARE curs CURSOR FOR


		SELECT DISTINCT
			vt.fin_id
		   ,ot.id AS tip_id
		   ,0 AS sup_id
		   ,'' AS sup_name
		FROM dbo.OCCUPATION_TYPES ot 
		JOIN dbo.VOCC_TYPES_ALL_LITE vt
			ON vt.id = ot.id
		WHERE 
			(ot.id = @tip_id1 OR @tip_id1 IS NULL)
			AND 
			(vt.fin_id = @fin_id1 
			 OR (@fin_id1 IS NULL AND vt.fin_id = ot.fin_id) 
			 OR @fin_all = 1
			)
		UNION
		SELECT DISTINCT
			vt.fin_id
		   ,ot.id AS tip_id
		   ,COALESCE(vds.sup_id, 0) AS sup_id
		   ,COALESCE(vds.sup_name, '') AS sup_name
		FROM dbo.OCCUPATION_TYPES ot 
		JOIN dbo.VOCC_TYPES_ALL_LITE vt
			ON vt.id = ot.id
		LEFT JOIN View_DOG_SUP vds
			ON vt.id = vds.tip_id
		WHERE 
			(ot.id = @tip_id1 OR @tip_id1 IS NULL)
			AND (
			vt.fin_id = @fin_id1 
			OR (@fin_id1 IS NULL AND vt.fin_id = ot.fin_id)
			OR @fin_all = 1
			)
		ORDER BY 1, 2, 3

	OPEN curs
	FETCH NEXT FROM curs INTO @fin_id1, @tip_id1, @sup_id1, @sup_name1
	WHILE (@@fetch_status = 0)
	BEGIN
		IF @debug = 1
			RAISERROR ('@fin_id1=%d, @tip_id1=%d, @sup_id1=%d, @sup_name1=%s', 10, 1, @fin_id1, @tip_id1, @sup_id1, @sup_name1) WITH NOWAIT;

		SELECT
			@StrFinPeriod = gv.StrMes
		FROM dbo.GLOBAL_VALUES gv
		WHERE gv.fin_id = @fin_id1

		SELECT
			@SumOplata1 = 0
		   ,@SumSaldo1 = 0
		   ,@SumPaymAccount1 = 0
		   ,@SumPaymAccount_Peny1 = 0
		   ,@SumValue1 = 0
		   ,@SumLgota1 = 0
		   ,@SumSubsidia1 = 0
		   ,@SumAdded1 = 0
		   ,@SumPaid_old = 0
		   ,@SumOplataMes1 = 0
		   ,@SumDolg = 0
		   ,@SumPenalty1 = 0

		--IF @debug = 1  PRINT 'Находим суммы'

		IF @sup_id1 = 0
			SELECT
				@KolLic = COALESCE(COUNT(o.occ), 0)
			   ,@KolFlats = COALESCE(COUNT(DISTINCT o.flat_id), 0)
			   ,@KolPeople = SUM(COALESCE(o.kol_people, 0))
			   ,@KolBuilds = COALESCE(COUNT(DISTINCT o.build_id), 0)
			   ,@SumOplata1 = COALESCE(SUM(o.Whole_payment), 0)
			   ,@SumSaldo1 = COALESCE(SUM(o.SALDO), 0)
			   ,@SumPaymAccount1 = COALESCE(SUM(o.paymaccount), 0)
			   ,@SumPaymAccount_Peny1 = COALESCE(SUM(o.paymaccount_peny), 0)
			   ,@SumValue1 = COALESCE(SUM(o.value), 0)
			   ,@SumAdded1 = COALESCE(SUM(o.Added), 0)
			   ,@SumPaid_old = COALESCE(SUM(o.Paid_old), 0)
			   ,@SumOplataMes1 = COALESCE(SUM(o.Paid + o.Paid_minus), 0)
			   ,@SumDolg = COALESCE(SUM(o.SALDO - o.Paymaccount_Serv), 0)
			   ,@SumPenalty1 = COALESCE(SUM(o.penalty_value + o.Penalty_old_new), 0)
			   ,@SumTotal_SQ = COALESCE(SUM(o.TOTAL_SQ), 0)
			FROM dbo.View_OCC_ALL AS o 
			WHERE 
				o.tip_id = @tip_id1
				AND o.status_id <> N'закр'
				AND o.fin_id = @fin_id1
		ELSE
			SELECT
				@KolLic = COALESCE(COUNT(os.occ_sup), 0)
			   ,@KolFlats = COALESCE(COUNT(DISTINCT o.flat_id), 0)
			   ,@KolPeople = SUM(COALESCE(o.kol_people, 0))
			   ,@KolBuilds = COALESCE(COUNT(DISTINCT o.build_id), 0)
			   ,@SumOplata1 = COALESCE(SUM(os.Whole_payment), 0)
			   ,@SumSaldo1 = COALESCE(SUM(os.SALDO), 0)
			   ,@SumPaymAccount1 = COALESCE(SUM(os.paymaccount), 0)
			   ,@SumPaymAccount_Peny1 = COALESCE(SUM(os.paymaccount_peny), 0)
			   ,@SumValue1 = COALESCE(SUM(os.value), 0)
			   ,@SumAdded1 = COALESCE(SUM(os.Added), 0)
			   ,@SumPaid_old = COALESCE(SUM(COALESCE(os.Paid_old, 0)), 0)
			   ,@SumOplataMes1 = COALESCE(SUM(os.Paid), 0)
			   ,@SumDolg = COALESCE(SUM(os.SALDO - os.paymaccount - os.paymaccount_peny), 0)
			   ,@SumPenalty1 = COALESCE(SUM(os.penalty_value + os.Penalty_old_new), 0)
			   ,@SumTotal_SQ = COALESCE(SUM(o.TOTAL_SQ), 0)
			FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.VOcc_Suppliers AS os 
				ON o.occ = os.occ
				AND o.fin_id = os.fin_id
			WHERE 
				o.tip_id = @tip_id1
				AND o.status_id <> N'закр'
				AND o.fin_id = @fin_id1
				AND os.sup_id = @sup_id1

		--print '@SumPaymAccount1 '+ str(@SumPaymAccount1,15,2) 
		--print '@SumPaid_old '+ str(@SumPaid_old,15,2)

		--SELECT
		--	@ProcentOplata =
		--		CASE
		--			WHEN @SumPaid_old = 0 THEN 100
		--			WHEN (@SumPaymAccount1 = 0 OR
		--			@SumPaid_old = 0) THEN 0
		--			ELSE CONVERT(DECIMAL(15, 4), @SumPaymAccount1 * 100 / @SumPaid_old)
		--		END
		SELECT
			@ProcentOplata = 0
		--print @ProcentOplata

		SELECT
			@SumPaymAccountCounter = COALESCE(SUM(cp.paymaccount), 0)
		FROM dbo.COUNTER_PAYM2 AS cp 
		JOIN dbo.OCCUPATIONS AS o 
			ON cp.occ = o.occ
		WHERE cp.fin_id = @fin_id1
		AND tip_value = 0
		AND tip_id = @tip_id1
		AND status_id <> N'закр'

		IF @debug = 1
			PRINT CONCAT('@KolLic=', @KolLic,' @SumSaldo1=', LTRIM(STR(@SumSaldo1, 12, 2)),' @SumDolg=', @SumDolg)

		IF EXISTS (SELECT
					1
				FROM dbo.INFO_BASA 
				WHERE fin_id = @fin_id1
				AND tip_id = @tip_id1
				AND sup_name = @sup_name1)
		BEGIN
			UPDATE dbo.INFO_BASA
			SET StrFinId			  = @StrFinPeriod
			   ,KolLic				  = @KolLic
			   ,KolBuilds			  = @KolBuilds
			   ,KolFlats			  = @KolFlats
			   ,KolPeople			  = @KolPeople
			   ,SumOplata			  = @SumOplata1
			   ,SumOplataMes		  = @SumOplataMes1
			   ,SumValue			  = @SumValue1
			   ,SumLgota			  = @SumLgota1
			   ,SumSubsidia			  = @SumSubsidia1
			   ,SumAdded			  = @SumAdded1
			   ,SumPaymAccount		  = @SumPaymAccount1
			   ,SumPaymAccount_peny	  = @SumPaymAccount_Peny1
			   ,SumPaymAccountCounter = @SumPaymAccountCounter
			   ,SumPenalty			  = @SumPenalty1
			   ,SumSaldo			  = @SumSaldo1
			   ,SumTotal_SQ			  = @SumTotal_SQ
			   ,SumDolg				  = @SumDolg
			   ,ProcentOplata		  = @ProcentOplata
			WHERE fin_id = @fin_id1
			AND tip_id = @tip_id1
			AND sup_name = @sup_name1
		END

		ELSE
		BEGIN
			INSERT INFO_BASA
			(fin_id
			,tip_id
			,sup_name
			,StrFinId
			,KolLic
			,KolBuilds
			,KolFlats
			,KolPeople
			,SumOplata
			,SumOplataMes
			,SumValue
			,SumLgota
			,SumSubsidia
			,SumAdded
			,SumPaymAccount
			,SumPaymAccount_peny
			,SumPaymAccountCounter
			,SumPenalty
			,SumSaldo
			,SumTotal_SQ
			,SumDolg
			,ProcentOplata)
			VALUES (@fin_id1
				   ,@tip_id1
				   ,@sup_name1
				   ,@StrFinPeriod
				   ,@KolLic
				   ,@KolBuilds
				   ,@KolFlats
				   ,@KolPeople
				   ,@SumOplata1
				   ,@SumOplataMes1
				   ,@SumValue1
				   ,@SumLgota1
				   ,@SumSubsidia1
				   ,@SumAdded1
				   ,@SumPaymAccount1
				   ,@SumPaymAccount_Peny1
				   ,@SumPaymAccountCounter
				   ,@SumPenalty1
				   ,@SumSaldo1
				   ,@SumTotal_SQ
				   ,@SumDolg
				   ,@ProcentOplata)
		END

		FETCH NEXT FROM curs INTO @fin_id1, @tip_id1, @sup_id1, @sup_name1
	END
	CLOSE curs
	DEALLOCATE curs
go

