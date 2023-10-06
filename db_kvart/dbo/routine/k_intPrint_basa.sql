CREATE   PROCEDURE [dbo].[k_intPrint_basa]
(
	  @tip_id1 SMALLINT = NULL -- Тип жилого фонда
	, @occ1 INT = NULL -- Лицевой
	, @debug BIT = 0
	, @build_id INT = NULL
	, @group_id INT = NULL
)
/*
 Процедура подготовки информации для печати счетов-квитанций
 exec k_intPrint_basa null,330477,1
 exec k_intPrint_basa null,700040266,0
 exec k_intPrint_basa 28,null,1,1037
 
*/
AS
	SET NOCOUNT ON;

	IF @occ1 = 0
		SET @occ1 = NULL;
	IF @build_id = 0
		SET @build_id = NULL;
	IF @group_id = 0
		SET @group_id = NULL;

	DECLARE @Initials VARCHAR(120)
		  , @InitialsPrivat VARCHAR(120)
		  , @Initials_owner_id INT
		  , @SumPaym DECIMAL(15, 4)
		  , @PROPTYPE_ID VARCHAR(10)
		  , @jeu SMALLINT
		  , @is_PrintFioPrivat BIT
		  , @start_date SMALLDATETIME
		  , @StrFinPeriod VARCHAR(20)
		  , @DateCurrent SMALLDATETIME
		  , @StrLgota VARCHAR(20)
		  , @rasschet VARCHAR(20)

	DECLARE @LastDayPaymPred SMALLDATETIME
		  , @PaymClosedDataPred SMALLDATETIME
		  , @LastDayPaymCurrent SMALLDATETIME
		  , @PersonStatus1 VARCHAR(50)
		  , @set_start_day_period_dolg BIT -- устанавливать первый день месяца - как ДЕНЬ ДОЛГА

	DECLARE @saldo1 DECIMAL(15, 4)
		  , @saldoAll DECIMAL(15, 4)
		  , @paymaccount1 DECIMAL(9, 2)
		  , @PaymAccountStorno1 DECIMAL(9, 2)
		  , @paymaccountAll DECIMAL(9, 2)
		  , @paidAll DECIMAL(15, 4)
		  , @value DECIMAL(15, 4)
		  , @AddedAll DECIMAL(9, 2)
		  , @Penalty_value1 DECIMAL(9, 2)
		  , @Penalty_period1 DECIMAL(9, 2)
		  , @Penalty_old1 DECIMAL(9, 2)
		  , @Penalty_calc1 BIT
		  , @Epd_dolg DECIMAL(15, 2)= 0  -- Сумма долга без учёта переплаты на конец периода
		  , @Epd_overpayment DECIMAL(15, 2) = 0  -- Сумма переплаты без учета долга на конец периода
		  , @Epd_saldo_dolg DECIMAL(15, 2)= 0  -- Сумма долга без учёта переплаты на начало периода
		  , @Epd_saldo_overpayment DECIMAL(15, 2) = 0  -- Сумма переплаты без учета долга на начало периода
		  , @is_epd_saldo BIT = 0

	DECLARE @StrSub1 VARCHAR(100)
		  , @StrSub2 VARCHAR(100)
		  , @StrSub3 VARCHAR(100) = ''
		  , @dateNazn SMALLDATETIME
		  , @SummaEE DECIMAL(9, 2)
		  , @SummaGAZ DECIMAL(9, 2)
		  , @SummaCompens DECIMAL(9, 2)
		  , @Added DECIMAL(9, 2)
		  , @PaymAccount DECIMAL(9, 2);

	DECLARE @Fin_id1 SMALLINT -- текущий фин. период
		  , @Fin_pred1 SMALLINT -- предыдущий фин. период
		  , @StrFinPeriodRod VARCHAR(12) -- Период в род.падеже
		  , @StrLast1 VARCHAR(100) -- для последней строки
		  , @StrLast2 VARCHAR(20)
		  , @KolMesDolg DECIMAL(5, 1)
		  , @KolMesDolgAll DECIMAL(5, 1);

	-- для посылки сообщения об ошибке 
	DECLARE @strerror VARCHAR(300)
		  , @i INT = 0
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME());

	IF @tip_id1 = 0
		SET @tip_id1 = NULL;

	SET @strerror = N'Ошибка! Не все квитанции обновились! База: ' + DB_NAME() + STR(@occ1, 10);

	CREATE TABLE #t (
		  occ INT PRIMARY KEY
		, fin_id SMALLINT-- тек.фин. период на лицевом
	);

	--****************************************************************        

	BEGIN TRY

		IF (@occ1 IS NULL)
			AND (@tip_id1 IS NOT NULL
			OR @build_id IS NOT NULL
			OR @group_id IS NOT NULL)
		BEGIN
			-- Обновление по типу жилого фонда или дому или группе
			INSERT INTO #t (occ
						  , fin_id)
			SELECT DISTINCT o.occ
						  , b.fin_current
			FROM dbo.Occupations AS o 
				JOIN dbo.Flats F ON F.ID = o.flat_id
				JOIN dbo.Buildings AS b ON f.bldn_id=b.id
				LEFT JOIN dbo.Print_occ AS po ON o.occ = po.occ  -- лицевой может быть в нескольких группах поэтому нужен DISTINCT
			WHERE o.status_id <> 'закр'
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND (@build_id IS NULL OR F.bldn_id = @build_id)
				AND (@group_id IS NULL OR po.group_id = @group_id)
		END
		ELSE
		IF (@occ1 IS NOT NULL)
		BEGIN
			-- Обновление лицевого счета
			INSERT INTO #t (occ
						  , fin_id)
			SELECT DISTINCT occ
						  , b.fin_current
			FROM dbo.Occupations AS o 
				JOIN dbo.Flats F ON F.ID = o.flat_id
				JOIN dbo.Buildings AS b ON f.bldn_id=b.id
			WHERE o.occ = @occ1
				AND status_id <> 'закр';

		END
		ELSE
		IF (@tip_id1 IS NULL)
			AND (@occ1 IS NULL)
			AND (@build_id IS NULL)
		BEGIN
			IF @debug = 1
				PRINT N'Обновление всей базы';
			INSERT INTO #t (occ
						  , fin_id)
			SELECT DISTINCT occ
						  , b.fin_current
			FROM dbo.Occupations AS o 
				JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.ID
				JOIN dbo.Flats F ON F.ID = o.flat_id
				JOIN dbo.Buildings AS b ON f.bldn_id=b.id
			WHERE status_id <> 'закр'
				AND (ot.raschet_no IS NULL OR ot.raschet_no = 0);
		END;

		--if @debug=1 select COUNT(*) from @t

		--******************************** 

		-- Дата формирования квитанции
		SELECT @DateCurrent = current_timestamp; --dbo.Fun_GetOnlyDate(current_timestamp)

		--********************************


		IF @debug = 1
		BEGIN
			SELECT @i = COUNT(occ)
			FROM #t;
			PRINT N'Отобрано: ' + STR(@i) + N' фин.период: ' + STR(@Fin_id1)
		END

		SET @i = 0;

		DECLARE table_curs CURSOR LOCAL FOR
			SELECT occ
				 , t.fin_id
				 , gv.start_date
				 , gv.StrMes
				 , gv.StrMes2
			FROM #t AS t
				JOIN dbo.Global_values AS gv ON t.fin_id = gv.fin_id;

		OPEN table_curs;
		FETCH NEXT FROM table_curs INTO @occ1, @Fin_id1, @start_date, @StrFinPeriod, @StrFinPeriodRod;

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT @i = @i + 1
				 , @Fin_pred1 = @Fin_id1 - 1;

			IF @debug = 1
				RAISERROR (N'№ %d, л/сч: %d', 10, 1, @i, @occ1) WITH NOWAIT;

			--******* для субсидии *******************
			SELECT @StrSub1 = ''
				 , @StrSub2 = ''
				 , @StrSub3 = ''
				 , @dateNazn = NULL
				 , @SummaEE = NULL
				 , @SummaGAZ = NULL
				 , @SummaCompens = NULL
				 , @Added = NULL
				 , @Penalty_value1 = 0
				 , @Penalty_old1 = 0
				 , @InitialsPrivat = '-'
				 , @Initials_owner_id = NULL
				 , @rasschet = NULL

			-- Кол-во человек в текущем фин. периоде
			--SELECT @people_finperiod=dbo.Fun_GetKolPeopleOccStatus(@occ1)

			SELECT @SumPaym = Whole_payment
				 , @saldo1 = SALDO
				 , @paymaccount1 = PaymAccount
				 , @saldoAll = SaldoAll
				 , @paymaccountAll = coalesce(Paymaccount_ServAll,0)
				 , @AddedAll = AddedAll
				 , @paidAll = PaidAll
				 , @value = o.Value
				 , @PROPTYPE_ID = o.proptype_id
				 , @tip_id1 = o.tip_id
				 , @PaymAccount = PaymAccount
				 , @LastDayPaymCurrent = ot.LastPaymDay
				 , @Penalty_old1 = o.Penalty_old
				 , @Penalty_value1 = o.Penalty_old_new + o.Penalty_added + o.Penalty_value
				 , @Penalty_period1 = Penalty_value + o.Penalty_added
				 , @Penalty_calc1 = Penalty_calc
				 , @jeu = b.sector_id
				 , @is_PrintFioPrivat = ot.is_PrintFioPrivat
				 , @build_id = b.ID
				 , @set_start_day_period_dolg = ot.set_start_day_period_dolg
				 , @is_epd_saldo = ot.is_epd_saldo
			FROM dbo.VOcc AS o
				JOIN dbo.Flats AS f ON 
					o.flat_id = f.ID
				JOIN dbo.Buildings AS b ON 
					f.bldn_id = b.ID
				JOIN dbo.Occupation_Types AS ot ON 
					o.tip_id = ot.ID
			WHERE o.occ = @occ1
				AND o.fin_id = @Fin_id1

			SELECT @PaymAccountStorno1 = dbo.Fun_GetPaymAccountStorno(@Fin_id1, @occ1, 0)

			-- инициалы квартиросьемщика
			IF (@DB_NAME IN ('KVART', 'ARX_KVART')
				AND @tip_id1 IN (27))
				OR (@DB_NAME IN ('KOMP', 'ARX_KOMP')
				AND @tip_id1 IN (137))
				OR (@DB_NAME IN ('KR1', 'ARX_KR1')
				AND @tip_id1 IN (28))
				SET @Initials = [dbo].[Fun_InitialsFull](@occ1);
			ELSE
				SET @Initials = dbo.Fun_Initials_All(@occ1);
			--IF @debug=1 SELECT @Initials,@DB_NAME,@tip_id1

			IF @PROPTYPE_ID <> N'непр'
				AND @is_PrintFioPrivat = 1
			BEGIN
				SET @InitialsPrivat = dbo.Fun_InitialsPrivat(@occ1, 1);
				IF @InitialsPrivat <> '-'
					SET @Initials = @InitialsPrivat;
			END;

			-- находим код гражданина для квитанции(штрих-кода)
			SELECT @Initials_owner_id = p.ID
			FROM dbo.People AS p 
			WHERE p.occ = @occ1
				AND Fam_id = N'отвл'
				AND Del = 0;

			IF (@Initials_owner_id IS NULL)
				SELECT TOP 1 @Initials_owner_id = p.ID
				FROM dbo.People AS p 
				WHERE p.occ = @occ1
					AND (Dola_priv1 > 0 OR Status2_id = N'влпр'
					)
					AND Del = 0
				ORDER BY Dola_priv1 DESC;

			--SELECT
			--	@Initials = fio
			--FROM dbo.PEOPLE
			--WHERE id = @Initials_owner_id;

			--IF @debug = 1
			--	SELECT
			--		@Initials
			--		,@build_id
			--		,@DB_NAME

			SELECT @LastDayPaymPred = LastPaymDay
				 , @PaymClosedDataPred = PaymClosedData
			FROM dbo.Occupation_Types_History
			WHERE ID = @tip_id1
				AND fin_id = @Fin_pred1;

			--if @debug=1 print @LastDayPaymPred

			IF (@LastDayPaymPred > @start_date
				OR @LastDayPaymPred IS NULL)
				OR @set_start_day_period_dolg=1
				SET @LastDayPaymPred = dbo.Fun_GetOnlyDate(@start_date);
			
			IF (@DB_NAME IN ('KVART'))
				SELECT @LastDayPaymPred = @start_date;
				
			--if @debug=1 print @LastDayPaymPred	

			IF @PaymClosedDataPred > @start_date
				SET @PaymClosedDataPred = @start_date;

			IF @PaymClosedDataPred > @LastDayPaymPred
				SET @LastDayPaymPred = dbo.Fun_GetOnlyDate(@PaymClosedDataPred);
			--print @LastDayPaymPred

			IF @LastDayPaymCurrent < @start_date
				OR @LastDayPaymCurrent IS NULL
				SET @LastDayPaymCurrent = dbo.Fun_GetOnlyDate(@start_date);


			SELECT @SumPaym = CASE
                                  WHEN @SumPaym >= 0 THEN @SumPaym
                                  ELSE 0
                END
				 , @StrLgota = ''; --dbo.Fun_LgotaStr(@occ1)

			IF @is_epd_saldo=1
			BEGIN
				SELECT @Epd_dolg=SUM(CASE WHEN vp.Debt+vp.Penalty_old+vp.penalty_serv>0 THEN vp.Debt+vp.Penalty_old+vp.penalty_serv ELSE 0 END)  -- Наверно надо ещё пени суммировать
				    , @Epd_saldo_dolg=SUM(CASE WHEN vp.saldo+vp.penalty_prev>0 THEN vp.saldo+vp.penalty_prev ELSE 0 END)
					, @Epd_overpayment=SUM(CASE WHEN vp.Debt+vp.Penalty_old+vp.penalty_serv<0 THEN vp.Debt+vp.Penalty_old+vp.penalty_serv ELSE 0 END)
					, @Epd_saldo_overpayment=SUM(CASE WHEN vp.saldo+vp.penalty_prev<0 THEN vp.saldo+vp.penalty_prev ELSE 0 END)
				FROM dbo.Paym_list vp
				WHERE vp.fin_id=@Fin_id1
					AND vp.Occ=@occ1
					AND vp.sup_id=0
			END
			ELSE
				SELECT @Epd_dolg=@SumPaym, @Epd_overpayment=0, @Epd_saldo_dolg=@saldo1+@Penalty_old1, @Epd_saldo_overpayment=0

			-- Формируем последнюю строку
			SELECT @KolMesDolg = 0
				 , @KolMesDolgAll = 0
				 , @StrLast1 = ''
				 , @StrLast2 = '';

			IF (@saldoAll - @paymaccountAll + @AddedAll) > 100 -- если более 100 руб.
			BEGIN
				SET @KolMesDolgAll = dbo.Fun_DolgMesCalAll(@Fin_id1, @occ1);
			END;

			IF (@saldo1 - @paymaccount1 + @AddedAll) > 100 -- если более 100 руб.
			BEGIN

				SELECT @KolMesDolg = dbo.Fun_DolgMesCal(@Fin_id1, @occ1); --Fun_DolgMes
				IF @KolMesDolg > 999
					SET @KolMesDolg = 999;
			END;

			--*****************************************************************************************
			-- Строка со статусами прописки
			SET @PersonStatus1 = dbo.Fun_PersonStatusStr(@occ1);

			SELECT @rasschet = rasschet
			FROM dbo.Fun_GetAccount_ORG(@occ1, NULL)

			MERGE dbo.Intprint AS ip USING (
				SELECT oc.occ
					 , oc.schtl
					 , oc.flat_id
					 , oc.tip_id
					 , oc.roomtype_id
					 , oc.proptype_id
					 , oc.status_id
					 , oc.living_sq
					 , oc.total_sq
					 , oc.norma_sq
					 , oc.SALDO
					 , oc.PaymAccount_peny
					 , oc.Debt
					 , oc.kol_people
					 , @Fin_id1 AS fin_id
				FROM dbo.Occupations AS oc
					JOIN dbo.Occupation_Types AS ot ON oc.tip_id = ot.ID
				WHERE oc.occ = @occ1
			) AS p1
			ON ip.occ = p1.occ
				AND ip.fin_id = p1.fin_id
			WHEN MATCHED
				THEN UPDATE
					SET Initials = COALESCE(@Initials, '')
					  , Lgota = @StrLgota
					  , total_people = COALESCE(p1.kol_people, 0)
					  , total_sq = p1.total_sq
					  , living_sq = p1.living_sq
					  , FinPeriod = @start_date
					  , SumPaym = @SumPaym
					  , SALDO = p1.SALDO
					  , PaymAccount = @PaymAccount
					  , PaymAccount_storno = @PaymAccountStorno1
					  , PaymAccount_peny = p1.PaymAccount_peny
					  , Debt = p1.Debt
					  , LastDayPaym = @LastDayPaymPred
					  , LastDayPaym2 = @LastDayPaymCurrent
					  , PersonStatus = @PersonStatus1
					  , Penalty_old = @Penalty_old1
					  , Penalty_value = @Penalty_value1
					  , Penalty_period = @Penalty_period1
					  , StrSubsidia1 = @StrSub1
					  , StrSubsidia2 = @StrSub2
					  , StrSubsidia3 = @StrSub3
						--,StrLast			= @StrLast1
					  , KolMesDolg = @KolMesDolg
					  , DateCreate = @DateCurrent
					  , KolMesDolgAll = @KolMesDolgAll
					  , Initials_owner_id = @Initials_owner_id
					  , rasschet = @rasschet
					  , Epd_dolg = @Epd_dolg
					  , Epd_overpayment = @Epd_overpayment
					  , Epd_saldo_dolg = @Epd_saldo_dolg
					  , Epd_saldo_overpayment = @Epd_saldo_overpayment
			WHEN NOT MATCHED
				THEN INSERT (fin_id
						   , occ
						   , SumPaym
						   , Initials
						   , Lgota
						   , total_people
						   , total_sq
						   , living_sq
						   , FinPeriod
						   , SALDO
						   , PaymAccount
						   , PaymAccount_storno
						   , PaymAccount_peny
						   , Debt
						   , LastDayPaym
						   , LastDayPaym2
						   , PersonStatus
						   , Penalty_old
						   , Penalty_value
						   , Penalty_period
						   , StrSubsidia1
						   , StrSubsidia2
						   , StrSubsidia3
							 --, StrLast
						   , KolMesDolg
						   , DateCreate
						   , KolMesDolgAll
						   , Initials_owner_id
						   , rasschet
						   , Epd_dolg
						   , Epd_overpayment
						   , Epd_saldo_dolg
						   , Epd_saldo_overpayment)
					VALUES(@Fin_id1
						 , p1.occ
						 , @SumPaym
						 , COALESCE(@Initials, '')
						 , @StrLgota
						 , COALESCE(p1.kol_people, 0)
						 , p1.total_sq
						 , p1.living_sq
						 , @start_date
						 , p1.SALDO
						 , @PaymAccount --PaymAccount
						 , @PaymAccountStorno1
						 , p1.PaymAccount_peny --PaymAccount_peny
						 , p1.Debt --Debt
						 , @LastDayPaymPred
						 , @LastDayPaymCurrent
						 , @PersonStatus1
						 , @Penalty_old1
						 , @Penalty_value1
						 , @Penalty_period1
						 , @StrSub1 -- StrSubsidia1
						 , @StrSub2 -- StrSubsidia2 
						 , @StrSub3 -- StrSubsidia3 
						   --, @StrLast1 -- StrLast 
						 , COALESCE(@KolMesDolg, 0)
						 , @DateCurrent
						 , COALESCE(@KolMesDolgAll, 0)
						 , @Initials_owner_id
						 , @rasschet
						 , @Epd_dolg
						 , @Epd_overpayment
						 , @Epd_saldo_dolg
						 , @Epd_saldo_overpayment);

			--****************************************************************   
			FETCH NEXT FROM table_curs INTO @occ1, @Fin_id1, @start_date, @StrFinPeriod, @StrFinPeriodRod;
		END;

		CLOSE table_curs;
		DEALLOCATE table_curs;

		IF @debug = 1
			RAISERROR (N'Обновляем кол-во месяцев долга у поставщиков по отдельной квитанции', 10, 1) WITH NOWAIT;

		UPDATE o 
		SET o.KolMesDolg = i.KolMesDolg
		FROM dbo.Occupations o
			JOIN #t t ON o.occ = t.occ
			JOIN Intprint i ON i.occ = t.occ
				AND i.fin_id = t.fin_id

		UPDATE os
		SET [KolMesDolg] =
            CASE
                WHEN (SALDO - PaymAccount) > 100 THEN dbo.Fun_DolgMesCalSup(os.fin_id, os.occ, sup_id)
                ELSE 0
                END
		  , PaymAccount_storno = dbo.Fun_GetPaymAccountStorno(os.fin_id, os.occ, sup_id)
		FROM [dbo].[Occ_Suppliers] AS os
			JOIN #t AS t ON os.occ = t.occ
				AND os.fin_id = t.fin_id;

		--IF @debug = 1
		RAISERROR (N'Обновление закончено', 10, 1) WITH NOWAIT;
	/***************************/

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + N'Лицевой: ' + LTRIM(STR(@occ1));
		EXECUTE dbo.k_GetErrorInfo @visible = @debug
								 , @strerror = @strerror OUT

		IF @@trancount > 0
			ROLLBACK TRAN;

		RAISERROR (@strerror, 16, 1);
	END CATCH;


	RETURN;
go

