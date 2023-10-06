CREATE   PROCEDURE [dbo].[adm_CloseFinPeriod]
AS
	--
	-- Закрытие Финансового периода
	--
	-- Сохраняем историю за текущий месяц в таблицы  с историей (_HISTORY) 
	--
	SET NOCOUNT ON
	SET XACT_ABORT ON;

	DECLARE @fin_current SMALLINT
		  , @fin_new INT
		  , @PaymClosed1 BIT
		  , @err INT
		  , @start_date1 SMALLDATETIME
		  , @end_date1 SMALLDATETIME
		  , @start_date2 SMALLDATETIME
		  , @end_date2 SMALLDATETIME
		  , @msg VARCHAR(100)

	DECLARE @host VARCHAR(30) = HOST_NAME()
	DECLARE @date1 DATETIME = current_timestamp

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL);

	SELECT @start_date1 = [start_date]
		 , @end_date1 = end_date
		 , @PaymClosed1 = PaymClosed
	FROM dbo.Global_values
	WHERE fin_id = @fin_current;

	IF @PaymClosed1 = 0
	BEGIN
		RAISERROR ('Закройте платежный период за предыдущий месяц!', 16, 1)
		RETURN 1
	END

	DELETE FROM dbo.Progress_proces
	WHERE comp = @host -- Чистим таблицу прогресса

	SELECT @fin_new = @fin_current + 1;

	SELECT @start_date2 = DATEADD(MONTH, 1, @start_date1)
	SELECT @end_date2 = DATEADD(MINUTE, -1, DATEADD(MONTH, 2, @start_date1))

	--select '@fin_new'=@fin_new, '@start_date2'=@start_date2, '@end_date2'=@end_date2

	-- Удаляем временные данные из таблиц
	TRUNCATE TABLE dbo.Comp_serv_tmp;
	DELETE FROM dbo.Compensac_tmp;
	TRUNCATE TABLE dbo.Paym_add;

	SET @msg = 'Обновляем сводную информацию'
	RAISERROR (@msg, 10, 1) WITH NOWAIT;
	INSERT INTO dbo.Progress_proces (comp, Descriptions)
	VALUES(@host, @msg)

	EXEC rep_svod

	----********************************************************* 
	---- Запоминаем сводные данные по базе в этом фин. периоде
	----
	--set @msg='Запоминаем сводные данные по базе'
	--RAISERROR (@msg, 10, 1) WITH NOWAIT;
	--INSERT INTO dbo.PROGRESS_PROCES(comp,Descriptions) VALUES(@host,@msg)

	--EXEC adm_info_basa


	BEGIN TRY

		--*********************************************************
		SET @msg = 'Сохраняем разовые'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions)
		VALUES(@host, @msg);

		DELETE FROM dbo.Added_Payments_History
		WHERE fin_id = @fin_current;

		INSERT INTO dbo.Added_Payments_History (occ
											  , fin_id
											  , service_id
											  , add_type
											  , Value
											  , doc
											  , data1
											  , data2
											  , Hours
											  , add_type2
											  , manual_bit
											  , Vin1
											  , Vin2
											  , doc_no
											  , doc_date
											  , user_edit
											  , dsc_owner_id
											  , fin_id_paym
											  , comments
											  , tnorm2
											  , kol)
		SELECT occ
			 , @fin_current
			 , service_id
			 , add_type
			 , Value
			 , doc
			 , data1
			 , data2
			 , Hours
			 , add_type2
			 , manual_bit
			 , Vin1
			 , Vin2
			 , doc_no
			 , doc_date
			 , user_edit
			 , dsc_owner_id
			 , fin_id_paym
			 , comments
			 , tnorm2
			 , kol
		FROM dbo.Added_Payments
		WHERE Value <> 0
		SELECT @err = @@error
		IF @err <> 0
		BEGIN
			RAISERROR ('Ошибка (Added_payments)', 11, 1)
			RETURN @err
		END

		--********************************************************* 
		-- 3. Сохраняем историю начислений
		--

		SET @msg = 'Сохраняем историю начислений'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg)

		DELETE FROM dbo.Paym_history
		WHERE fin_id = @fin_current;

		INSERT INTO dbo.Paym_history (fin_id
									, occ
									, service_id
									, subsid_only
									, tarif
									, saldo
									, Value
									, Discount
									, Added
									, Compens
									, Paid
									, PaymAccount
									, PaymAccount_peny
									, account_one
									, kol
									, unit_id
									, metod
									, is_counter)
		SELECT @fin_current
			 , p.occ
			 , service_id
			 , subsid_only
			 , tarif
			 , p.saldo
			 , p.Value
			 , 0
			 , -- discount
			   p.Added
			 , 0
			 , -- compens
			   p.Paid
			 , p.PaymAccount
			 , p.PaymAccount_peny
			 , account_one
			 , kol
			 , unit_id
			 , metod
			 , is_counter
		FROM dbo.Paym_list AS p
			JOIN dbo.Occupations AS o ON 
				p.occ = o.occ
		WHERE (p.Value <> 0 OR p.Added <> 0 OR p.Paid <> 0 OR p.PaymAccount <> 0 OR p.saldo <> 0 OR is_counter <> 0 OR p.metod>0)

		--*********************************************
		SET @msg = 'Сохраняем историю счетчиков по лицевым'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg)

		DELETE FROM dbo.Counter_list_all
		WHERE fin_id = @fin_new;

		DELETE cl
		FROM dbo.Counter_list_all AS cl
			JOIN dbo.Occupations AS o ON 
				cl.occ = o.occ
		WHERE o.status_id = 'закр'
			AND cl.fin_id = @fin_current

		INSERT INTO dbo.Counter_list_all (fin_id
										, counter_id
										, occ
										, service_id
										, occ_counter
										, internal)
		SELECT @fin_new
			 , counter_id
			 , cl.occ
			 , service_id
			 , occ_counter
			 , internal
		FROM dbo.Counter_list_all AS cl
		WHERE cl.fin_id = @fin_current

		--********************************************************
		-- 4. Сохраняем историю лиц.счета
		--
		SET @msg = 'Сохраняем историю лиц.счета'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg)

		DELETE FROM dbo.Occ_history
		WHERE fin_id = @fin_current;

		INSERT INTO dbo.Occ_history (fin_id
								   , occ
								   , jeu
								   , tip_id
								   , flat_id
								   , roomtype_id
								   , proptype_id
								   , status_id
								   , living_sq
								   , total_sq
								   , teplo_sq
								   , norma_sq
								   , socnaim
								   , saldo
								   , saldo_serv
								   , saldo_edit
								   , Value
								   , Discount
								   , Compens
								   , Added
								   , PaymAccount
								   , PaymAccount_peny
								   , Paid
								   , Paid_minus
								   , Paid_old
								   , Penalty_calc
								   , Penalty_value
								   , Penalty_old_new
								   , penalty_old
								   , Penalty_old_edit
								   , comments
								   , comments2
								   , kol_people
								   , id_jku_gis
								   , id_els_gis)
		SELECT @fin_current
			 , occ
			 , jeu
			 , tip_id
			 , flat_id
			 , roomtype_id
			 , proptype_id
			 , status_id
			 , living_sq
			 , total_sq
			 , teplo_sq
			 , norma_sq
			 , socnaim
			 , saldo
			 , saldo_serv
			 , saldo_edit
			 , Value
			 , Discount
			 , Compens
			 , Added
			 , PaymAccount
			 , PaymAccount_peny
			 , Paid
			 , Paid_minus
			 , Paid_old
			 , Penalty_calc
			 , Penalty_value
			 , Penalty_old_new
			 , penalty_old
			 , Penalty_old_edit
			 , comments
			 , comments2
			 , kol_people
			 , id_jku_gis
			 , id_els_gis
		FROM dbo.Occupations AS o

		--*********************************************************
		--
		SET @msg = 'Подготавливаем историю по людям'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg);

		DECLARE @occ1 INT

		CREATE TABLE #p1 (
			  fin_id SMALLINT
			, occ INT
			, owner_id INT
		    , people_uid UNIQUEIDENTIFIER
			, lgota_id SMALLINT
			, status_id TINYINT
			, status2_id VARCHAR(10) COLLATE database_default
			, birthdate SMALLDATETIME
			, doxod DECIMAL(9,2)
			, KolDayLgota TINYINT
			, data1 SMALLDATETIME
			, data2 SMALLDATETIME
			, kol_day TINYINT
			, DateEnd SMALLDATETIME
		)

		DECLARE curs CURSOR LOCAL FOR
			SELECT occ
			FROM dbo.Occupations
			ORDER BY occ
		OPEN curs
		FETCH NEXT FROM curs INTO @occ1

		WHILE (@@fetch_status = 0)
		BEGIN
			INSERT INTO #p1 EXEC k_PeopleFin @occ1
										   , @fin_current
			--   print str(@occ1)
			FETCH NEXT FROM curs INTO @occ1
		END

		CLOSE curs
		DEALLOCATE curs;

		--********************************************************* 
		SET @msg = N'Сохраняем историю по людям'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions)VALUES(@host, @msg);

		DELETE FROM dbo.People_history
		WHERE fin_id = @fin_current;

		INSERT INTO dbo.People_history (occ
									  , fin_id
									  , owner_id
									  , lgota_id
									  , status_id
									  , status2_id
									  , kol_day
									  , KolDayLgota
									  , data1
									  , data2
									  , lgota_kod)
		SELECT p.occ
			 , p.fin_id
			 , p.owner_id
			 , p.lgota_id
			 , p.status_id
			 , p.status2_id
			 , p.kol_day
			 , p.KolDayLgota
			 , p.data1
			 , p.data2
			 , p1.lgota_kod
		FROM #p1 AS p
			JOIN dbo.People AS p1 ON p.owner_id = p1.id

		/*************************************/
		SET @msg = 'Сохраняем режимы потребления'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Consmodes_history
		WHERE fin_id = @fin_current

		INSERT INTO dbo.Consmodes_history (fin_id
										 , occ
										 , service_id
										 , source_id
										 , mode_id
										 , Koef
										 , subsid_only
										 , is_counter
										 , account_one
										 , sup_id)
		SELECT @fin_current
			 , cl.occ
			 , cl.service_id
			 , cl.source_id
			 , cl.mode_id
			 , COALESCE(cl.koef, 1) AS koef
			 , COALESCE(cl.subsid_only, 0) AS subsid_only
			 , cl.is_counter
			 , cl.account_one
			 , cl.sup_id
		FROM dbo.Consmodes_list AS cl
			JOIN dbo.Paym_list AS pl ON cl.occ = pl.occ
				AND cl.service_id = pl.service_id
		WHERE (Value <> 0 OR Added <> 0 OR Paid <> 0 OR PaymAccount <> 0 OR saldo <> 0 OR cl.is_counter > 0) -- добавил 18.04.06
		-- ((MODE_ID % 1000) !=0) and ((source_id % 1000)!=0 )

		/*************************************/
		SET @msg = 'Сохраняем список режимов потребления'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Cons_modes_history
		WHERE fin_id = @fin_current

		INSERT INTO dbo.Cons_modes_history (fin_id
										  , mode_id
										  , service_id
										  , name
										  , comments
										  , unit_id)
		SELECT @fin_current
			 , id
			 , service_id
			 , name
			 , comments
			 , unit_id
		FROM dbo.Cons_modes AS cl


		--********************************************************* 
		SET @msg = 'Сохраняем историю по видам платежей по банкам'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Paycoll_orgs
		WHERE fin_id = @fin_new

		INSERT INTO dbo.Paycoll_orgs (fin_id
									, Bank
									, vid_paym
									, comision
									, ext
									, description)
		SELECT @fin_new
			 , Bank
			 , vid_paym
			 , comision
			 , ext
			 , description
		FROM dbo.Paycoll_orgs
		WHERE fin_id = @fin_current

		--********************************************************
		SET @msg = 'Добавляем новые тарифы'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		IF EXISTS (
				SELECT id
				FROM dbo.Rates
				WHERE finperiod = @fin_new
			)
		BEGIN  -- Если существуют уже тарифы за этот период то удаляем их
			DELETE FROM dbo.Rates
			WHERE finperiod = @fin_new
			DELETE FROM dbo.Rates_counter
			WHERE fin_id = @fin_new
		END

		INSERT INTO dbo.Rates (finperiod
							 , tipe_id
							 , service_id
							 , mode_id
							 , source_id
							 , status_id
							 , proptype_id
							 , Value
							 , full_value
							 , extr_value)
		SELECT @fin_new
			 , tipe_id
			 , service_id
			 , mode_id
			 , source_id
			 , status_id
			 , proptype_id
			 , Value
			 , full_value
			 , extr_value
		FROM dbo.Rates AS r
		WHERE finperiod = @fin_current
			AND  -- только существующие режимы потребления 
			EXISTS (
				SELECT id
				FROM dbo.Cons_modes AS cm
				WHERE cm.service_id = r.service_id
					AND id = r.mode_id
			)
			AND  -- и поставщики
			EXISTS (
				SELECT id
				FROM dbo.View_suppliers AS cm
				WHERE cm.service_id = r.service_id
					AND id = r.source_id
			)

		-- Тарифы по счетчикам 
		INSERT INTO dbo.Rates_counter (fin_id
									 , tipe_id
									 , service_id
									 , unit_id
									 , mode_id
									 , source_id
									 , tarif)
		SELECT @fin_new
			 , tipe_id
			 , service_id
			 , unit_id
			 , mode_id
			 , source_id
			 , tarif
		FROM dbo.Rates_counter AS r
		WHERE fin_id = @fin_current

		--*********************************************************  
		SET @msg = 'Добавляем пени в новый период'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Peny_all
		WHERE fin_id = @fin_new

		INSERT INTO dbo.Peny_all (fin_id
								, occ
								, dolg
								, dolg_peny
								, paid_pred
								, peny_old
								, PaymAccount
								, PaymAccount_peny
								, peny_old_new
								, Penalty_added
								, kolday
								, Penalty_value
								, occ1
								, sup_id)
		SELECT @fin_new
			 , occ
			 , dolg
			 , dolg_peny
			 , paid_pred
			 , peny_old
			 , PaymAccount
			 , PaymAccount_peny
			 , peny_old_new
			 , Penalty_added
			 , kolday
			 , Penalty_value
			 , occ1
			 , sup_id
		FROM dbo.Peny_all pa
		WHERE fin_id = @fin_current

		--*********************************************************
		SET @msg = 'Сохраняем историю домов'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Buildings_history
		WHERE fin_id = @fin_current

		INSERT INTO dbo.Buildings_history (fin_id
										 , bldn_id
										 , street_id
										 , sector_id
										 , div_id
										 , tip_id
										 , nom_dom
										 , old
										 , standart_id
										 , dog_bit
										 , penalty_calc_build)
		SELECT @fin_current
			 , 'build_id' = id
			 , street_id
			 , sector_id
			 , div_id
			 , tip_id
			 , nom_dom
			 , old
			 , standart_id
			 , dog_bit
			 , penalty_calc_build
		FROM dbo.Buildings

		--*********************************************************
		SET @msg = 'Сохраняем историю единиц измерения'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Service_units
		WHERE fin_id = @fin_new

		INSERT INTO dbo.Service_units (fin_id
									 , service_id
									 , roomtype_id
									 , tip_id
									 , unit_id)
		SELECT @fin_new
			 , service_id
			 , roomtype_id
			 , tip_id
			 , unit_id
		FROM dbo.Service_units
		WHERE fin_id = @fin_current

		--********************************************************* 

		SET @msg = 'Сохраняем историю по типам фонда'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		DELETE FROM dbo.Occupation_Types_History
		WHERE fin_id = @fin_current

		INSERT INTO dbo.Occupation_Types_History (fin_id
												, id
												, name
												, payms_value
												, id_accounts
												, adres
												, fio
												, telefon
												, id_barcode
												, bank_account
												, laststr1
												, penalty_calc_tip
												, Counter_metod
												, counter_votv_ras
												, laststr2
												, penalty_metod)

		SELECT @fin_current
			 , id
			 , name
			 , payms_value
			 , id_accounts
			 , adres
			 , fio
			 , telefon
			 , id_barcode
			 , bank_account
			 , laststr1
			 , penalty_calc_tip
			 , Counter_metod
			 , counter_votv_ras
			 , laststr2
			 , penalty_metod
		FROM dbo.Occupation_Types

		--********************************************************* 
		BEGIN TRAN

		--********************************************************* 
		--
		SET @msg = 'Создаем новый фин. период'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		INSERT INTO dbo.Global_values (fin_id
									 , start_date
									 , end_date
									 , StrMes
									 , closed
									 , ExtSubsidia
									 , Mes_nazn
									 , SubNorma
									 , procent
									 , SubClosedData
									 , Minzpl
									 , Prmin
									 , Srok
									 , Metod2
									 , LiftFloor
									 , LiftYear1
									 , LiftYear2
									 , PenyRas
									 , lastpaym
									 ,
									   --PenyProc,
									   PaymClosed
									 , PaymClosedData
									 , fincloseddata
									 , State
									 , region
									 , Town
									 , Norma1
									 , Norma2
									 , NormaSub
									 , SumLgotaAntena
									 , AddGvrProcent
									 , AddGvrDays
									 , AddOtpProcent
									 , POPserver
									 , GKAL
									 , NormaGKAL
									 , StrMes2
									 , LgotaRas
									 , msg_timeout
									 , counter_block_value
									 , web_reports
									 , filenamearhiv
									 , dir_new_version
									 , procSubs12
									 , settings_json
									 , settings_developer
									 , heat_summer_start
									 , heat_summer_end)
		SELECT TOP (1) @fin_new as fin_id
					 , @start_date2 as 'start_date'
					 , @end_date2 as end_date
					 , '' as StrMes
					 , closed
					 , ExtSubsidia
					 , Mes_nazn
					 , SubNorma
					 , procent
					 , SubClosedData = NULL
					 , Minzpl
					 , Prmin
					 , Srok
					 , Metod2
					 , LiftFloor
					 , LiftYear1
					 , LiftYear2
					 , PenyRas
					 , lastpaym
					 , 0 AS PaymClosed
					 , NULL AS PaymClosedData
					 , NULL AS FinClosedData
					 , State
					 , region
					 , Town
					 , Norma1
					 , Norma2
					 , NormaSub
					 , SumLgotaAntena
					 , AddGvrProcent
					 , AddGvrDays
					 , AddOtpProcent
					 , POPserver
					 , GKAL
					 , NormaGKAL
					 , StrMes2 = ''
					 , LgotaRas
					 , msg_timeout
					 , 0 AS counter_block_value
					 , web_reports
					 , filenamearhiv
					 , dir_new_version
					 , procSubs12
					 , settings_json
					 , settings_developer
					 , heat_summer_start
					 , heat_summer_end
		FROM dbo.Global_values
		ORDER BY fin_id DESC

		UPDATE dbo.Global_values
		SET StrMes = dbo.Fun_NameFinPeriod(@fin_new)
		  , StrMes2 = (
				SELECT name_pred
				FROM dbo.View_Month
				WHERE id = DATEPART(MONTH, @start_date2)
			) + ' ' + DATENAME(YEAR, @start_date2)
		WHERE fin_id = @fin_new

		--********************************************************
		SET @msg = 'Создаем новый фин. период для субсидий'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg)

		DELETE FROM dbo.Subsidia12tarif
		WHERE fin_id = @fin_current

		INSERT INTO dbo.Subsidia12tarif(fin_id, service_id, tarif) 
		SELECT @fin_new AS fin_id,service_id, tarif
		FROM dbo.Subsidia12tarif
		WHERE fin_id=@fin_current

		--********************************************************
		-- Определяем новое начальное сальдо на следующий месяц
		--
		SET @msg = 'Определяем новое начальное сальдо на следующий месяц'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)

		UPDATE dbo.Occupations
		SET saldo = Debt
		  , penalty_old = Penalty_old_new + Penalty_value
		  , Paid_old = Paid
		FROM dbo.Occupations AS o
		WHERE status_id <> 'закр'


		-- *******************************************************
		-- Проставляем новый фин. период в домах
		UPDATE dbo.Buildings
		SET fin_current = @fin_new

		UPDATE dbo.Occupation_Types
		SET fin_id = @fin_new

		--********************************************************
		-- Окончание закрытия фин. периода
		SET @msg = 'Окончание закрытия фин. периода'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		UPDATE dbo.Global_values
		SET closed = 1
		  , fincloseddata = current_timestamp
		  , SubClosedData = COALESCE(SubClosedData, current_timestamp)
		WHERE fin_id = @fin_current

		COMMIT TRAN

		--*********************************************************
		SET @msg = 'Подготавливаем таблицы к расчётам в новом периоде'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;

		TRUNCATE TABLE dbo.Added_Payments

		UPDATE dbo.Occupations
		SET saldo_edit = 0
		  , PaymAccount = 0
		  , PaymAccount_peny = 0
		  , Paid = 0
		  , Paid_minus = 0
		  , Penalty_old_new = 0
		  , Penalty_value = 0
		  , Added = 0
		  , Added_ext = 0
		FROM dbo.Occupations AS o
		WHERE status_id <> 'закр'

		DELETE FROM dbo.Paym_list
		WHERE (Value = 0
			AND Added = 0
			AND Paid = 0
			AND PaymAccount = 0
			AND saldo = 0)

		UPDATE pl
		SET saldo = Debt
		  , Value = 0
		  , Added = 0
		  , PaymAccount = 0
		  , PaymAccount_peny = 0
		FROM dbo.Paym_list AS pl

		SET @date1 = current_timestamp - @date1
		SET @msg = 'Фин.период ЗАКРЫТ! Поздравляем! За ' + CONVERT(VARCHAR(25), @date1, 108)
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp
									   , Descriptions)
		VALUES(@host
			 , @msg)


	-- посылаем сводную информацию администраторам
	--exec dbo.adm_mail_send @fin_id1

	--print 'Удаляем информацию старше 5 лет'
	--EXEC [dbo].[adm_del_history]

	END TRY

	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

