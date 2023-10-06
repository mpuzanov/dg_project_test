CREATE   PROCEDURE [dbo].[k_intPrint_basa_history]
/*
 Процедура обновления информации для печати счетов-квитанций в истории
 exec dbo.k_intPrint_basa_history 62,750000086,139,1
 exec dbo.k_intPrint_basa_history 2,null,230,1
*/
(
	  @tip_id1 SMALLINT = NULL -- Тип жилого фонда
	, @occ1 INT = NULL -- Лицевой
	, @fin_id SMALLINT
	, @debug BIT = 0
	, @build_id INT = NULL
)
AS
	SET NOCOUNT ON

	DECLARE @SumPaym DECIMAL(9, 2)
		  , @Initials_owner_id INT

	DECLARE @start_date SMALLDATETIME
		  , @StrFinPeriod VARCHAR(20)
		  , @DateCurrent SMALLDATETIME
		  , @StrLgota VARCHAR(20)
		  , @rasschet VARCHAR(20)

	DECLARE @PersonStatus1 VARCHAR(50)

	DECLARE @saldo1 DECIMAL(9, 2)
		  , @saldoAll DECIMAL(9, 2)
		  , @paymaccount1 DECIMAL(9, 2)
		  , @PaymAccountStorno1 DECIMAL(9, 2)
		  , @paymaccountAll DECIMAL(9, 2)
		  , @paid1 DECIMAL(9, 2)
		  , @AddedAll DECIMAL(9, 2)

	DECLARE @Penalty_value1 DECIMAL(9, 2)
		  , @Penalty_period1 DECIMAL(9, 2)
		  , @Penalty_calc1 BIT

	DECLARE @PaymAccount DECIMAL(9, 2)

	DECLARE @StrFinPeriodRod VARCHAR(12) -- Период в род.падеже

	DECLARE @KolMesDolg DECIMAL(5, 1)
		  , @KolMesDolgAll DECIMAL(5, 1)

	-- для посылки сообщения об ошибке 
	DECLARE @msg VARCHAR(8000)
		  , @strerror VARCHAR(300)
		  , @i INT = 0
		  , @DB_NAME VARCHAR(20)

	IF @tip_id1 = 0
		SET @tip_id1 = NULL

	DECLARE @t TABLE (
		  occ INT PRIMARY KEY
		, whole_payment DECIMAL(9, 2)
		, fin_id SMALLINT
	)

	-- таблица для проверки обновления
	DECLARE @t2 TABLE (
		  occ INT PRIMARY KEY
		, whole_payment DECIMAL(9, 2)
		, SumPaym DECIMAL(9, 2)
	)

	DECLARE @ROWCOUNT1 INT
		  , @error1 INT

	--****************************************************************        
	BEGIN TRY

		IF (@tip_id1 IS NOT NULL
			OR @occ1 IS NOT NULL
			OR @build_id IS NOT NULL)
		BEGIN
			IF @debug = 1
				PRINT 'Выборка'
			INSERT INTO @t
				(occ
			   , whole_payment
			   , fin_id)
			SELECT occ
				 , whole_payment
				 , o.fin_id
			FROM dbo.View_occ_all AS o
			WHERE status_id <> 'закр'
				AND o.fin_id = @fin_id
				AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
				AND (@occ1 IS NULL OR o.occ = @occ1)
				AND (@build_id IS NULL OR o.bldn_id = @build_id)

		END


		IF (@tip_id1 IS NULL
			AND @occ1 IS NULL
			AND @build_id IS NULL)
		BEGIN
			IF @debug = 1
				PRINT 'Обновление всей базы'
			INSERT INTO @t
				(occ
			   , whole_payment
			   , fin_id)
			SELECT occ
				 , whole_payment
				 , o.fin_id
			FROM dbo.View_occ_all AS o
				JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.ID
			WHERE status_id <> 'закр'
				AND o.fin_id = @fin_id
				AND (ot.raschet_no IS NULL OR ot.raschet_no = 0)
		END

		--if @debug=1 select COUNT(*) from @t

		--******************************** 

		-- Дата формирования квитанции
		SELECT @DateCurrent = current_timestamp
			 , @DB_NAME = UPPER(DB_NAME())

		--********************************


		IF @debug = 1
		BEGIN
			SELECT @i = COUNT(occ)
			FROM @t
			PRINT 'Отобрано: ' + STR(@i) + ', фин.период: ' + STR(@fin_id, 3)
		END

		SET @i = 0

		DECLARE table_curs CURSOR LOCAL FOR
			SELECT occ
				 , gv.start_date
				 , gv.StrMes
				 , gv.StrMes2
			FROM @t AS t
				JOIN dbo.Global_values AS gv ON t.fin_id = gv.fin_id

		OPEN table_curs
		FETCH NEXT FROM table_curs INTO @occ1, @start_date, @StrFinPeriod, @StrFinPeriodRod

		WHILE (@@fetch_status = 0)
		BEGIN
			SET @i = @i + 1

			IF @debug = 1
				RAISERROR ('№ %d, л/сч: %d', 10, 1, @i, @occ1) WITH NOWAIT;

			SELECT @Penalty_value1 = 0
				 , @Initials_owner_id = NULL
				 , @rasschet = NULL

			-- Кол-во человек в текущем фин. периоде
			--SELECT @people_finperiod=dbo.Fun_GetKolPeopleOccStatus(@occ1)

			SELECT @SumPaym = COALESCE(whole_payment, 0)
				 , @saldo1 = SALDO
				 , @paymaccount1 = COALESCE(PaymAccount, 0)
				 , @saldoAll = COALESCE(SaldoAll, 0)
				 , @paymaccountAll = COALESCE(Paymaccount_ServAll, 0)
				 , @AddedAll = COALESCE(AddedAll, 0)
				 , @paid1 = Paid
				 , @PaymAccount = PaymAccount
				 , @Penalty_value1 = o.Penalty_old_new + o.Penalty_added + o.Penalty_value
				 , @Penalty_period1 = Penalty_value + o.Penalty_added
				 , @Penalty_calc1 = Penalty_calc
			FROM dbo.View_occ_all AS o 
			WHERE o.occ = @occ1
				AND o.fin_id = @fin_id

			SELECT @SumPaym =
							 CASE
								 WHEN @SumPaym >= 0 THEN @SumPaym
								 ELSE 0
							 END
				 , @StrLgota = '' --dbo.Fun_LgotaStr(@occ1)

			-- Формируем последнюю строку
			SELECT @KolMesDolg = 0
				 , @KolMesDolgAll = 0

			IF (@saldoAll - @paymaccountAll + @AddedAll) > 100 -- если более 100 руб.
			BEGIN
				SET @KolMesDolgAll = dbo.Fun_DolgMesCalAll(@fin_id, @occ1)
			END

			IF (@saldo1 - @paymaccount1 + @AddedAll) > 100 -- если более 100 руб.
			BEGIN
				SET @KolMesDolg = dbo.Fun_DolgMesCal(@fin_id, @occ1) --Fun_DolgMes

				IF @KolMesDolg > 999
					SET @KolMesDolg = 999

				IF @debug = 1
					PRINT 'Кол-во мес. долга: ' + STR(@KolMesDolg, 6, 1)
			--if @debug=1 print @StrLast1 --'Кол-во мес. долга: '+str(@KolMesDolg)

			END

			SELECT @PaymAccountStorno1 = dbo.Fun_GetPaymAccountStorno(@fin_id, @occ1, 0)
			-- Строка со статусами прописки
			SET @PersonStatus1 = dbo.Fun_PersonStatusStrFin(@occ1, @fin_id);

			-- Ответственный в квитанцию
			SELECT @Initials_owner_id = p.ID
			FROM dbo.People AS p 
				JOIN dbo.People_history ph ON p.occ = ph.occ
					AND p.ID = ph.owner_id
			WHERE p.occ = @occ1
				AND ph.fin_id = @fin_id
				AND p.Fam_id = 'отвл'
				AND p.Del = CAST(0 AS BIT);

			SELECT @rasschet = rasschet
			FROM dbo.Fun_GetAccount_ORG(@occ1, NULL)

			MERGE dbo.Intprint AS ip USING (
				SELECT oc.*
				FROM dbo.View_occ_all AS oc 
				WHERE oc.occ = @occ1
					AND oc.fin_id = @fin_id
			) AS p1
			ON ip.occ = p1.occ
				AND ip.fin_id = p1.fin_id
			WHEN MATCHED
				THEN UPDATE
					SET total_people = COALESCE(p1.kol_people, 0)
					  , SumPaym = @SumPaym
					  , SALDO = p1.SALDO
					  , PaymAccount = @PaymAccount
					  , PaymAccount_storno = @PaymAccountStorno1
					  , PaymAccount_peny = p1.PaymAccount_peny
					  , Debt = p1.Debt
					  , Penalty_value = @Penalty_value1
					  , Penalty_period = @Penalty_period1
					  , KolMesDolg = @KolMesDolg
					  , KolMesDolgAll = @KolMesDolgAll
					  , PersonStatus = @PersonStatus1
					  , Initials = CASE
                                       WHEN ip.Initials = '' THEN '-'
                                       ELSE ip.Initials
                        END
					  , Initials_owner_id = CASE
                                                WHEN Initials_owner_id IS NULL THEN @Initials_owner_id
                                                ELSE Initials_owner_id
                        END
					  , rasschet = @rasschet
					  , LastDayPaym = CASE
                                          WHEN ip.LastDayPaym > @start_date THEN @start_date
                                          ELSE ip.LastDayPaym
                        END
			;

			--****************************************************************   
			FETCH NEXT FROM table_curs INTO @occ1, @start_date, @StrFinPeriod, @StrFinPeriodRod
		END

		CLOSE table_curs
		DEALLOCATE table_curs

		IF @debug = 1
			RAISERROR ('Обновляем кол-во месяцев долга у поставщиков по отдельной квитанции', 10, 1) WITH NOWAIT;

		UPDATE os
		SET [KolMesDolg] =
						  CASE
							  WHEN (SALDO - PaymAccount) > 100 THEN dbo.Fun_DolgMesCalSup(os.fin_id, os.occ, sup_id)
							  ELSE 0
						  END
		  , PaymAccount_storno = dbo.Fun_GetPaymAccountStorno(os.fin_id, os.occ, sup_id)
		FROM [dbo].[Occ_Suppliers] AS os
			JOIN @t AS t ON os.occ = t.occ
				AND os.fin_id = t.fin_id

	/***************************/

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ1))
		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		EXEC dbo.k_adderrors_card @strerror

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

