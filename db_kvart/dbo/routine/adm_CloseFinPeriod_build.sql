CREATE   PROCEDURE [dbo].[adm_CloseFinPeriod_build]
(
	  @build_id INT
	, @debug BIT = 0
)
AS
BEGIN
	/*
	  Закрытие Финансового периода по дому
	
	  Сохраняем историю за текущий месяц в таблицы  с историей (_HISTORY) 
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON;

	DECLARE @tran_count INT, @tran_name varchar(50) = 'adm_CloseFinPeriod_build'
	SET @tran_count = @@trancount;

	DECLARE @fin_current INT 
		  , @fin_new INT
		  , @PaymClosed1 BIT
		  , @err INT
		  , @start_date1 SMALLDATETIME
		  , @end_date1 SMALLDATETIME
		  , @start_date2 SMALLDATETIME
		  , @end_date2 SMALLDATETIME
		  , @msg VARCHAR(100)
		  , @name_tip VARCHAR(100)
		  , @tip_id SMALLINT
		  , @name_build VARCHAR(100)
		  , @fin_current_str VARCHAR(20)		  

	DECLARE @strerror VARCHAR(4000) = ''
		  , @host VARCHAR(30) = HOST_NAME()
		  , @date1 DATETIME = current_timestamp
		  , @KolOcc INT = 0
		  , @user_fio varchar(50)

	SELECT
		@user_fio = u.Initials
	FROM dbo.USERS AS u 
	WHERE login = system_user

	SELECT @PaymClosed1 = ot.PaymClosed
		 , @fin_current = b.fin_current
		 , @tip_id = b.tip_id
		 , @name_tip = CONCAT(LTRIM(STR(ot.id)) , '. <' , ot.name , '>. ')
		 , @name_build = CONCAT(LTRIM(STR(ot.id)) , '. Дом:' , LTRIM(STR(b.id)) , ' ' , s.Name , ' д.' , b.nom_dom)
	FROM dbo.Buildings AS b 
		JOIN dbo.Streets AS s ON b.street_id=s.id
		JOIN dbo.Occupation_Types as ot ON b.tip_id=ot.id
	WHERE b.id = @build_id

	IF @fin_current IS NULL
		RETURN

	--IF @PaymClosed1 = 0
	--BEGIN
	--	RAISERROR (N'Закройте платежный период по %s!', 11, 1, @name_tip)
	--END

	-- После расчёта пени не сделан перерасчёт
	IF EXISTS (
			SELECT 1
			FROM dbo.Occupations O 
				JOIN dbo.Occupation_Types OT  ON OT.id = O.tip_id
				JOIN dbo.Flats AS f ON o.flat_id=f.id
				JOIN dbo.Buildings AS b  ON f.bldn_id=b.id				
				LEFT JOIN dbo.Peny_all PS ON O.occ = PS.occ
					AND b.fin_current = PS.fin_id
			WHERE O.data_rascheta < PS.data_rascheta
				AND b.id = @build_id
				AND O.status_id <> 'закр'
				AND b.is_paym_build = cast(1 as bit)
				AND b.is_finperiod_owner=cast(1 as bit)
		)
	BEGIN
		RAISERROR (N'После расчёта пени не сделан перерасчёт по %s!', 16, 1, @name_tip)
	END

	-- квитанции не обновлены
	IF EXISTS (
			SELECT 1
			FROM dbo.Occupations O 
				JOIN dbo.Flats AS f  ON o.flat_id=f.id
				JOIN dbo.Buildings AS b  ON f.bldn_id=b.id	
				JOIN dbo.Intprint PS  ON O.occ = PS.occ
					AND b.fin_current = PS.fin_id
			WHERE O.data_rascheta > PS.DateCreate
				AND b.id = @build_id
				AND O.status_id <> 'закр'
				AND b.is_paym_build = cast(1 as bit)
				AND b.is_finperiod_owner=cast(1 as bit)
		)
	BEGIN
		--RAISERROR ('Квитанции не обновлены по %s!', 11, 1, @name_tip)
		--RETURN 1

		SET @msg = @name_tip + N' - обновляем квитанции'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		EXEC k_intPrint_basa @build_id=@build_id
	END

	SET @fin_new = @fin_current + 1
	IF @debug = 1
		PRINT @fin_current

	SELECT @start_date1 = start_date
		 , @end_date1 = end_date
		 , @fin_current_str = StrMes
	FROM dbo.Global_values
	WHERE fin_id = @fin_current

	SELECT @start_date2 = DATEADD(MONTH, 1, @start_date1)  -- начало следущего периода
		 , @end_date2 = DATEADD(MINUTE, -1, DATEADD(MONTH, 2, @start_date1)) -- конец следующего периода

	DECLARE @tabl_occ TABLE (
		  occ INT
		, fin_id SMALLINT
		, fin_new SMALLINT
		, build_id INT
		, PRIMARY KEY (occ, fin_id)
	)

	INSERT INTO @tabl_occ (occ
						 , fin_id
						 , fin_new
						 , build_id)
	SELECT occ
		 , @fin_current
		 , @fin_new
		 , f.bldn_id
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f ON o.flat_id = f.id
		JOIN dbo.Buildings B ON f.bldn_id = B.id
	WHERE B.id = @build_id
		AND b.is_finperiod_owner=1
	SELECT @KolOcc = @@rowcount

	if @KolOcc=0
	BEGIN
		RAISERROR (N'Лицевых для закрытия периода нет по %s!', 11, 1, @name_build)
	END

	SET @msg = @name_tip + N'Начинаем в ' + CONVERT(VARCHAR(10), @date1, 108)
	RAISERROR (@msg, 10, 1) WITH NOWAIT;
	INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
	VALUES(@host, @msg, @user_fio)

	SET @msg = CONCAT(@name_build,' Кол-во лицевых: ',  STR(@KolOcc))
	RAISERROR (@msg, 10, 1) WITH NOWAIT;
	INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
	VALUES(@host, @msg, @user_fio)

	SET @msg = @name_tip + N'Удаляем перерасчёты у закрытых лицевых счетов'
	RAISERROR (@msg, 10, 1) WITH NOWAIT;
	INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
	VALUES(@host, @msg, @user_fio)
	
	DELETE ap
	FROM dbo.Added_Payments AS ap
		JOIN dbo.Occupations AS o ON 
			ap.occ = o.occ 
			AND ap.fin_id=o.fin_id
		JOIN dbo.Flats as f ON 
			o.flat_id=f.id
	WHERE f.bldn_id= @build_id
		AND o.status_id = 'закр';

	--====================================================================

	-- Открываем транзакцию 
	IF @tran_count = 0
		BEGIN TRANSACTION
	ELSE
		SAVE TRANSACTION @tran_name;

	--====================================================================

	BEGIN TRY

		--*********************************************************
		SET @msg = @name_tip + N'Сохраняем разовые'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Added_Payments_History AS t1 
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_id
				AND t1.occ = t.occ

		INSERT INTO dbo.Added_Payments_History (fin_id
											  , occ
											  , service_id
											  , sup_id
											  , add_type
											  , value
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
											  , repeat_for_fin
											  , date_edit)
		SELECT @fin_current
			 , t1.occ
			 , t1.service_id
			 , t1.sup_id
			 , add_type
			 , value
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
			 , repeat_for_fin
			 , date_edit
		FROM dbo.Added_Payments AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ 
				AND t1.fin_id = t.fin_id
		WHERE t1.value <> 0 OR t1.kol<>0

		--********************************************************* 
		SET @msg = @name_tip + N'Сохраняем историю начислений'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Paym_history AS t1
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_id
				AND t1.occ = t.occ;

		INSERT INTO dbo.Paym_history (fin_id
									, occ
									, service_id
									, subsid_only
									, tarif
									, saldo
									, value
									, Discount
									, Added
									, Compens
									, Paid
									, paymaccount
									, paymaccount_peny
									, account_one
									, kol
									, unit_id
									, metod
									, is_counter
									, kol_norma
									, metod_old
									, sup_id
									, Penalty_old
									, penalty_serv
									, build_id
									, kol_norma_single
									, source_id
									, mode_id
									, koef
									, occ_sup_paym
									, date_start
									, date_end
									, kol_added
									, koef_day
									, penalty_prev)
		SELECT @fin_current
			 , p.occ
			 , p.service_id
			 , p.subsid_only
			 , p.tarif
			 , p.saldo
			 , p.value
			 , 0 -- discount
			 , p.Added
			 , 0 -- compens
			 , p.Paid
			 , p.paymaccount
			 , p.paymaccount_peny
			 , p.account_one
			 , p.kol
			 , p.unit_id
			 , p.metod
			 , p.is_counter
			 , p.kol_norma
			 , p.metod_old
			 , p.sup_id
			 , p.Penalty_old
			 , p.penalty_serv
			 , p.build_id
			 , p.kol_norma_single
			 , p.source_id
			 , p.mode_id
			 , p.koef
			 , p.occ_sup_paym
			 , p.date_start
			 , p.date_end
			 , p.kol_added
			 , P.koef_day
			 , penalty_prev
		FROM dbo.Paym_list AS p
			JOIN @tabl_occ AS t ON 
				p.occ = t.occ 
				AND p.fin_id = t.fin_id
			LEFT JOIN dbo.Services_build sb ON 
				t.build_id = sb.build_id
				AND p.service_id = sb.service_id  -- добавляем выделенные услуги по дому, даже без начислений
		WHERE (
			p.value <> 0 OR p.Added <> 0 OR p.Paid <> 0 OR p.paymaccount <> 0 OR p.saldo <> 0 OR p.kol <> 0 OR p.Penalty_old <> 0 OR p.penalty_serv <> 0 
			OR (p.tarif > 0 AND p.is_counter > 0) 
			OR sb.VYDEL = 1 OR p.metod>0
			)

		--*********************************************
		SET @msg = @name_tip + N'Сохраняем историю счетчиков по лицевым'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		-- создаем табличку со счётчиками для соединений
		DECLARE @tabl_counter_id TABLE (
			  fin_id SMALLINT
			, counter_id INT
			, occ INT
			, PRIMARY KEY (fin_id, counter_id, occ)
		)
		INSERT INTO @tabl_counter_id (fin_id
									, counter_id
									, occ)
		SELECT @fin_new
			 , t1.counter_id
			 , t1.occ
		FROM dbo.Counter_list_all AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ
				AND t1.fin_id = t.fin_id;

		DELETE t1
		FROM dbo.Counter_list_all AS t1 
			JOIN @tabl_counter_id AS t ON 
				t1.fin_id = t.fin_id
				AND t1.counter_id = t.counter_id
				AND t1.occ = t.occ;

		DELETE t1 
		FROM dbo.Counter_list_all AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ
				AND t1.fin_id = t.fin_id
			JOIN dbo.Occupations AS o ON 
				t1.occ = o.occ
		WHERE o.status_id = 'закр';

		INSERT INTO dbo.Counter_list_all (fin_id
										, counter_id
										, occ
										, service_id
										, occ_counter
										, internal)
		SELECT @fin_new
			 , t1.counter_id
			 , t1.occ
			 , t1.service_id
			 , t1.occ_counter
			 , t1.internal
		FROM dbo.Counter_list_all AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ
				AND t1.fin_id = t.fin_id
			JOIN dbo.Counters c ON 
				t1.counter_id = c.id
		WHERE c.date_del IS NULL -- в новый период переносим только не закрытые счётчики  13.10.2015

		--********************************************************
		SET @msg = @name_tip + N'Сохраняем историю лиц.счета'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Occ_history AS t1
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_id
				AND t1.occ = t.occ;

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
								   , value
								   , Discount
								   , Compens
								   , Added
								   , paymaccount
								   , paymaccount_peny
								   , Paid
								   , Paid_minus
								   , Paid_old
								   , Penalty_calc
								   , penalty_added
								   , penalty_value
								   , Penalty_old_new
								   , Penalty_old
								   , Penalty_old_edit
								   , comments
								   , comments2
								   , kol_people
								   , SaldoAll
								   , Paymaccount_ServAll
								   , PaidAll
								   , AddedAll
								   , id_jku_gis
								   , KolMesDolg
								   , comments_print
								   , kol_people_reg
								   , kol_people_all
								   , id_els_gis
								   , kol_people_owner
								   , Data_rascheta
								   , date_start
								   , date_end)
		SELECT @fin_current
			 , t1.occ
			 , jeu
			 , tip_id
			 , flat_id
			 , roomtype_id
			 , proptype_id
			 , t1.status_id
			 , living_sq
			 , total_sq
			 , teplo_sq
			 , norma_sq
			 , socnaim
			 , saldo
			 , saldo_serv
			 , saldo_edit
			 , value
			 , Discount
			 , Compens
			 , Added
			 , paymaccount
			 , paymaccount_peny
			 , Paid
			 , Paid_minus
			 , Paid_old
			 , Penalty_calc
			 , penalty_added
			 , penalty_value
			 , Penalty_old_new
			 , Penalty_old
			 , Penalty_old_edit
			 , comments
			 , comments2
			 , kol_people
			 , SaldoAll
			 , Paymaccount_ServAll
			 , PaidAll
			 , AddedAll
			 , id_jku_gis
			 , KolMesDolg
			 , comments_print
			 , kol_people_reg
			 , kol_people_all
			 , id_els_gis
			 , kol_people_owner
			 , Data_rascheta
			 , date_start
			 , date_end
		FROM dbo.Occupations AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ 
				AND t1.fin_id = t.fin_id;

		--********************************************************
		SET @msg = @name_tip + N'Создаём новый период по лицевым поставщика'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Occ_Suppliers AS t1
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_new
				AND t1.occ = t.occ;

		INSERT INTO dbo.Occ_Suppliers (fin_id
									 , occ
									 , sup_id
									 , occ_sup
									 , saldo
									 , value
									 , Added
									 , Paid
									 , paymaccount
									 , paymaccount_peny
									 , penalty_added
									 , penalty_value
									 , Penalty_old_new
									 , Penalty_old
									 , KolMesDolg
									 , Penalty_old_edit
									 , Penalty_calc
									 , Paid_old
									 , dog_int
									 , cessia_dolg_mes_old
									 , cessia_dolg_mes_new
									 , id_jku_gis
									 , rasschet
									 , occ_sup_uid
									 , schtl_old)
		SELECT @fin_new
			 , t1.occ
			 , sup_id
			 , occ_sup
			 , saldo
			 , 0 AS value
			 , 0 AS Added
			 , 0 AS Paid
			 , 0 AS paymaccount
			 , 0 AS paymaccount_peny
			 , 0 AS Penalty_added
			 , 0 AS penalty_value
			 , 0 AS Penalty_old_new
			 , 0 AS Penalty_old
			 , 0 AS KolMesDolg
			 , Penalty_old_edit
			 , Penalty_calc
			 , Paid_old
			 , dog_int
			 , cessia_dolg_mes_old
			 , cessia_dolg_mes_new
			 , id_jku_gis
			 , rasschet
			 , occ_sup_uid
			 , schtl_old
		FROM dbo.Occ_Suppliers AS t1
			JOIN @tabl_occ AS t ON t1.occ = t.occ
				AND t1.fin_id = t.fin_id

		--*********************************************************
		SET @msg = @name_tip + N'Сохраняем историю по людям'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DECLARE @occ1 INT

		DECLARE @p1 TABLE (
			  fin_id SMALLINT
			, occ INT
			, owner_id INT
		    , people_uid UNIQUEIDENTIFIER
			, lgota_id SMALLINT
			, status_id TINYINT
			, status2_id VARCHAR(10)
			, birthdate SMALLDATETIME
			, doxod DECIMAL(9, 2)
			, KolDayLgota TINYINT
			, data1 SMALLDATETIME
			, data2 SMALLDATETIME
			, kol_day TINYINT
			, DateEnd SMALLDATETIME
		)

		DECLARE curs CURSOR LOCAL FOR
			SELECT occ
			FROM @tabl_occ
			ORDER BY occ
		OPEN curs
		FETCH NEXT FROM curs INTO @occ1

		WHILE (@@fetch_status = 0)
		BEGIN
			INSERT INTO @p1 EXEC k_PeopleFin @occ1
										   , @fin_current
			--   print str(@occ1)
			FETCH NEXT FROM curs INTO @occ1
		END

		CLOSE curs
		DEALLOCATE curs

		--********************************************************* 
		SET @msg = @name_tip + N'Соединяем таблицы по людям'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.People_history AS t1 
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_id
				AND t1.occ = t.occ;

		INSERT INTO dbo.People_history (fin_id
									  , occ
									  , owner_id
									  , lgota_id
									  , status_id
									  , status2_id
									  , kol_day
									  , KolDayLgota
									  , data1
									  , data2
									  , lgota_kod
									  , DateEnd)
		SELECT p.fin_id
			 , p.occ
			 , p.owner_id
			 , p.lgota_id
			 , p.status_id
			 , p.status2_id
			 , p.kol_day
			 , p.KolDayLgota
			 , p.data1
			 , p.data2
			 , p1.lgota_kod
			 , p1.DateEnd
		FROM @p1 AS p
			JOIN dbo.People AS p1 ON 
				p.owner_id = p1.id

		/*************************************/
		SET @msg = @name_tip + N'Сохраняем режимы потребления'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Consmodes_history AS t1 
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_id
				AND t1.occ = t.occ;

		INSERT INTO dbo.Consmodes_history (fin_id
										 , occ
										 , service_id
										 , source_id
										 , mode_id
										 , koef
										 , subsid_only
										 , is_counter
										 , account_one
										 , sup_id
										 , dog_int
										 , occ_serv_kol
										 , date_end
										 , date_start)
		SELECT @fin_current
			 , cl.occ
			 , cl.service_id
			 , cl.source_id
			 , cl.mode_id
			 , COALESCE(cl.koef, 1) AS koef
			 , cl.subsid_only AS subsid_only
			 , cl.is_counter
			 , cl.account_one
			 , cl.sup_id
			 , cl.dog_int
			 , occ_serv_kol
			 , cl.date_end
			 , cl.date_start
		FROM dbo.Consmodes_list AS cl
			JOIN @tabl_occ AS t ON 
				cl.occ = t.occ 
				AND cl.fin_id = t.fin_id
			JOIN dbo.Paym_list AS pl ON 
				cl.occ = pl.occ
				AND cl.service_id = pl.service_id
				AND cl.sup_id = pl.sup_id
				AND pl.fin_id = t.fin_id
		WHERE (pl.value <> 0 OR pl.Added <> 0 OR pl.Paid <> 0 OR pl.paymaccount <> 0 OR pl.saldo <> 0 OR cl.is_counter > 0 -- добавил 18.04.06
			OR cl.account_one = 1 -- добавил 22.11.12
			OR pl.tarif > 0 -- добавил 04.03.16
			OR pl.kol <> 0
			OR pl.Penalty_old <> 0 OR pl.penalty_serv <> 0
			)
		-- ((MODE_ID % 1000) !=0) and ((source_id % 1000)!=0 )

		/*************************************/
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Cons_modes_history
				WHERE fin_id = @fin_current
			)
		BEGIN
			SET @msg = @name_tip + N'Сохраняем список режимов потребления'
			RAISERROR (@msg, 10, 1) WITH NOWAIT;
			INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
			VALUES(@host, @msg, @user_fio)

			DELETE FROM dbo.Cons_modes_history
			WHERE fin_id = @fin_current;

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
		END

		--*********************************************************
		SET @msg = @name_tip + N'Добавляем пени в новый период'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Peny_all AS t1 
			JOIN @tabl_occ AS t ON 
				t1.fin_id = t.fin_new
				AND t1.occ = t.occ;

		INSERT INTO dbo.Peny_all (fin_id
								, occ
								, dolg
								, dolg_peny
								, paid_pred
								, peny_old
								, paymaccount
								, paymaccount_peny
								, peny_old_new
								, penalty_added
								, kolday
								, penalty_value
								, metod
								, data_rascheta
								, occ1
								, sup_id
								, penalty_calc)
		SELECT @fin_new
			 , t1.occ
			 , t1.dolg
			 , t1.dolg_peny
			 , t1.paid_pred
			 , t1.peny_old
			 , t1.paymaccount
			 , t1.paymaccount_peny
			 , t1.peny_old_new
			 , t1.penalty_added
			 , t1.kolday
			 , t1.penalty_value
			 , t1.metod
			 , t1.data_rascheta
			 , t1.occ1
			 , t1.sup_id
			 , t1.penalty_calc
		FROM dbo.Peny_all AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ 
				AND t1.fin_id = t.fin_id;

		-- по поставщику
		INSERT INTO dbo.Peny_all (fin_id
										 , occ
										 , dolg
										 , dolg_peny
										 , paid_pred
										 , peny_old
										 , paymaccount
										 , paymaccount_peny
										 , peny_old_new
										 , penalty_added
										 , kolday
										 , penalty_value
										 , metod
										 , data_rascheta
										 , occ1
										 , sup_id
										 , penalty_calc)
		SELECT @fin_new
			 , s.occ_sup
			 , t1.dolg
			 , t1.dolg_peny
			 , t1.paid_pred
			 , t1.peny_old
			 , t1.paymaccount
			 , t1.paymaccount_peny
			 , t1.peny_old_new
			 , t1.penalty_added
			 , t1.kolday
			 , t1.penalty_value
			 , t1.metod
			 , t1.data_rascheta
			 , t1.occ1
			 , t1.sup_id
			 , t1.penalty_calc
		FROM dbo.Peny_all AS t1
			JOIN dbo.Occ_Suppliers AS s ON 
				t1.occ = s.occ_sup
				AND t1.fin_id = s.fin_id 
				AND t1.fin_id = s.fin_id
			JOIN @tabl_occ AS t ON 
				s.occ = t.occ 
				AND t1.fin_id = t.fin_id
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Peny_all AS PSH 
				WHERE PSH.fin_id = @fin_new
					AND PSH.occ = s.occ_sup
			);

		--*********************************************************
		SET @msg = @name_tip + N'Переносим в новый период информацию по с/х животным'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE t1
		FROM dbo.Agriculture_Occ AS t1 
			JOIN @tabl_occ AS t ON 
				t1.fin_id = @fin_new
				AND t1.occ = t.occ

		INSERT INTO dbo.Agriculture_Occ (fin_id
									   , occ
									   , ani_vid
									   , kol
									   , kol_day
									   , value)
		SELECT @fin_new
			 , t1.occ
			 , ani_vid
			 , kol
			 , kol_day
			 , value
		FROM dbo.Agriculture_Occ AS t1
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ
				 AND t1.fin_id = t.fin_id
		WHERE (kol <> 0 OR kol_day <> 0 OR value <> 0)

		--*********************************************************
		SET @msg = @name_tip + N'Сохраняем историю домов'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE FROM bh 
		FROM dbo.Buildings_history AS bh
			JOIN @tabl_occ AS o ON 
				bh.bldn_id = o.build_id
		WHERE bh.fin_id = @fin_current;

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
										 , penalty_calc_build
										 , arenda_sq
										 , dog_num
										 , dog_date
										 , is_paym_build
										 , dog_date_sobr
										 , dog_date_protocol
										 , dog_num_protocol
										 , opu_sq
										 , opu_sq_elek
										 , opu_sq_otop
										 , build_total_sq
										 , build_total_area
										 , norma_gkal
										 , build_type
										 , norma_gkal_gvs
										 , norma_gaz_gvs
										 , norma_gaz_otop
										 , account_rich)
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
			 , arenda_sq
			 , dog_num
			 , dog_date
			 , is_paym_build
			 , dog_date_sobr
			 , dog_date_protocol
			 , dog_num_protocol
			 , opu_sq
			 , opu_sq_elek
			 , opu_sq_otop
			 , build_total_sq
			 , build_total_area
			 , norma_gkal
			 , build_type
			 , norma_gkal_gvs
			 , norma_gaz_gvs
			 , norma_gaz_otop
			 , account_rich
		FROM dbo.Buildings AS b
			JOIN (SELECT DISTINCT build_id FROM @tabl_occ) AS o ON b.id = o.build_id

		--*********************************************************
		SET @msg = @name_tip + N'Создаём комментарии по домам в новом периоде'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE FROM bh 
		FROM dbo.Buildings_comments AS bh
		WHERE 
			bh.fin_id = @fin_new 
			AND bh.build_id=@build_id;

		INSERT INTO dbo.Buildings_comments (fin_id
										  , build_id
										  , sup_id
										  , avto
										  , comments
										  , fin_id_end)
		SELECT @fin_new
			 , bc.build_id
			 , bc.sup_id
			 , bc.avto
			 , bc.comments
			 , bc.fin_id_end
		FROM dbo.Buildings_comments AS bc
			JOIN Buildings AS b 
				ON bc.build_id = b.id
		WHERE 
			bc.fin_id = @fin_current 
			AND bc.build_id=@build_id
			AND (bc.avto = 1 OR b.comments_add_fin = 1 OR bc.fin_id_end >= @fin_new
			)

		--*********************************************************
		SET @msg = @name_tip + N'Создаём информацию по нежелым в новом периоде (Build_arenda)'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		DELETE FROM bh 
		FROM dbo.Build_arenda AS bh
		WHERE bh.fin_id = @fin_new AND bh.build_id=@build_id
		
		-- переносим в новый период только площади
		INSERT INTO dbo.Build_arenda ([build_id], [fin_id], [service_id], [kol], [kol_dom], [arenda_sq], [opu_sq], [volume_gvs])
		SELECT 
			ba.[build_id], @fin_new, ba.[service_id]
			,0
			,0 
			,ba.[arenda_sq]   
			,ba.[opu_sq]
			,0
		FROM dbo.Build_arenda AS ba
		WHERE ba.fin_id = @fin_current 
			AND ba.build_id=@build_id
			AND (COALESCE(ba.[arenda_sq],0)<>0 OR COALESCE(ba.[opu_sq],0)<>0)

		--********************************************************
		SET @msg = @name_tip + N'Добавляем новые тарифы'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions) VALUES(@host, @msg)
		
		;MERGE dbo.Rates AS r
		USING (SELECT * FROM dbo.Rates AS r2 
			WHERE r2.finperiod = @fin_current
			AND r2.tipe_id = @tip_id
			AND -- только существующие режимы потребления по этому типу фонда
			(EXISTS (
				SELECT 1
				FROM @tabl_occ AS o
					JOIN dbo.Consmodes_list AS cl 
						ON o.occ = cl.occ
				WHERE cl.service_id = r2.service_id
					AND cl.mode_id = r2.mode_id
					AND cl.source_id = r2.source_id
			) OR EXISTS (
				SELECT 1
				FROM @tabl_occ AS o
					JOIN dbo.Counters c 
						ON o.build_id = c.build_id
				WHERE c.service_id = r2.service_id
					AND c.mode_id > 0
					AND c.mode_id = r2.mode_id
			))
			) AS source
			ON 
			r.finperiod = @fin_new
			AND r.tipe_id = @tip_id
			AND (r.service_id=source.service_id 
			AND r.mode_id=source.mode_id
			AND r.source_id=source.source_id
			AND r.status_id=source.status_id
			AND r.proptype_id=source.proptype_id)
		WHEN MATCHED THEN 
			UPDATE SET 
				[value] = source.[value]
				,full_value = source.full_value
				,extr_value = source.extr_value
		WHEN NOT MATCHED THEN
		INSERT (finperiod
				, tipe_id
				, service_id
				, mode_id
				, source_id
				, status_id
				, proptype_id
				, value
				, full_value
				, extr_value
				, user_edit)
		VALUES (@fin_new
			 , source.tipe_id
			 , source.service_id
			 , source.mode_id
			 , source.source_id
			 , source.status_id
			 , source.proptype_id
			 , source.[value]
			 , source.full_value
			 , source.extr_value
			 , source.user_edit);		

		-- Тарифы по счетчикам 
		;MERGE dbo.Rates_counter AS r
		USING (SELECT * FROM dbo.Rates_counter AS r2 
			WHERE r2.fin_id = @fin_current
			AND r2.tipe_id = @tip_id
			AND -- только существующие режимы потребления по этому типу фонда
			(EXISTS (
				SELECT 1
				FROM @tabl_occ AS o
					JOIN dbo.Consmodes_list AS cl 
						ON o.occ = cl.occ
				WHERE cl.service_id = r2.service_id
					AND cl.mode_id = r2.mode_id
					AND cl.source_id = r2.source_id
			) OR EXISTS (
				SELECT 1
				FROM @tabl_occ AS o
					JOIN dbo.Counters c 
						ON o.build_id = c.build_id
				WHERE c.service_id = r2.service_id
					AND c.mode_id > 0
					AND c.mode_id = r2.mode_id
			))
			) AS source
			ON 
			r.fin_id = @fin_new
			AND r.tipe_id = @tip_id
			AND (r.service_id=source.service_id 
			AND r.mode_id=source.mode_id
			AND r.source_id=source.source_id)
		WHEN MATCHED THEN 
			UPDATE SET tarif = source.tarif
		WHEN NOT MATCHED THEN
		INSERT (fin_id
				, tipe_id
				, service_id
				, unit_id
				, mode_id
				, source_id
				, tarif)
		VALUES (@fin_new
			 , source.tipe_id
			 , source.service_id
			 , source.unit_id
			 , source.mode_id
			 , source.source_id
			 , source.tarif);			

		--*********************************************************
		SET @msg = @name_tip + N'Сохраняем историю по договорам'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces(comp, Descriptions, user_fio) VALUES(@host, @msg, @user_fio)

		DELETE db
		FROM dbo.Dog_build AS db 
			JOIN dbo.Buildings AS b ON 
				db.build_id = b.id
		WHERE fin_id = @fin_new
			AND b.id = @build_id;

		INSERT INTO dbo.Dog_build (dog_int
								 , fin_id
								 , build_id)
		SELECT dog_int
			 , @fin_new
			 , db.build_id
		FROM dbo.Dog_build AS db
			JOIN dbo.Buildings AS b ON db.build_id = b.id
		WHERE fin_id = @fin_current
			AND b.id = @build_id

		--****************************************************
		SET @msg = @name_tip + N'Сохраняем историю поставщиков по домам'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)	VALUES(@host, @msg, @user_fio)

		DELETE sbh
		FROM [Suppliers_build_history] sbh 
			JOIN @tabl_occ t ON 
				sbh.fin_id = t.fin_id
				AND sbh.build_id = t.build_id
		WHERE sbh.fin_id = @fin_current;

		INSERT INTO [dbo].[Suppliers_build_history] (fin_id
												   , build_id
												   , sup_id
												   , paym_blocked
												   , service_id
												   , add_blocked
												   , lastday_without_peny
												   , is_peny
												   , start_date_work
												   , penalty_metod
												   , print_blocked
												   , gis_blocked)
		SELECT DISTINCT @fin_current
					  , sb.build_id
					  , sb.[sup_id]
					  , sb.[paym_blocked]
					  , sb.[service_id]
					  , sb.[add_blocked]
					  , sb.lastday_without_peny
					  , sb.is_peny
					  , sb.start_date_work
					  , sb.penalty_metod
					  , sb.print_blocked
					  , sb.gis_blocked
		FROM [dbo].[Suppliers_build] AS sb
			JOIN @tabl_occ t ON sb.build_id = t.build_id

		--********************************************************
		-- Определяем новое начальное сальдо на следующий месяц
		--
		SET @msg = @name_tip + N'Определяем новое начальное сальдо на следующий месяц'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		--ALTER TABLE dbo.Occupations DISABLE TRIGGER ALL

		UPDATE o
		SET saldo = Debt
		  , Penalty_old = ((penalty_old_new+penalty_added)+penalty_value)
		  , Penalty_old_new = ((penalty_old_new+penalty_added)+penalty_value)
		  , Paid_old = Paid
		  , Penalty_old_edit = 0
		FROM dbo.Occupations AS o
			JOIN @tabl_occ AS t
				ON o.occ = t.occ
		WHERE o.status_id <> 'закр';

		UPDATE dbo.Occupations
		SET fin_id = @fin_new
		  , saldo_edit = 0
		  , paymaccount = 0
		  , paymaccount_peny = 0
			--,Debt				= 0
		  , Paid = 0
		  , Paid_minus = 0
			--,Penalty_old_new	= 0
		  , penalty_value = 0
		  , Added = 0
		  , Added_ext = 0
		  , comments_print = NULL
		  , AddedAll = 0
		FROM dbo.Occupations AS o
		JOIN @tabl_occ AS t
			ON o.occ = t.occ
		WHERE o.status_id <> 'закр';


		--ALTER TABLE dbo.Occupations ENABLE TRIGGER ALL

		UPDATE os
		SET Penalty_old_edit = 0
		FROM dbo.Occ_Suppliers AS os
			JOIN @tabl_occ AS t ON os.occ = t.occ
				AND os.fin_id = t.fin_new

		--********************************************************
		SET @msg = @name_tip + N'Окончание закрытия фин. периода'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		--********************************************************* 
		-- Проставляем новый фин. период в домах
		UPDATE b
		SET fin_current = @fin_new
		FROM dbo.Buildings AS b
			JOIN @tabl_occ AS o ON 
				b.id = o.build_id;

		--====================================================================

		SET @msg = @name_tip + N'Подготавливаем таблицы к расчётам в новом периоде'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		-- таблицу перерасчётов
		DELETE t1
		FROM dbo.Added_Payments AS t1 
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ
		WHERE repeat_for_fin IS NULL -- повторяющиеся разовые
			OR repeat_for_fin < @fin_new;

		UPDATE t1
		SET fin_id = @fin_new
		FROM dbo.Added_Payments AS t1 
			JOIN @tabl_occ AS t ON 
				t1.occ = t.occ 
				AND t1.fin_id=t.fin_id
		WHERE repeat_for_fin IS NOT NULL
			OR repeat_for_fin >= @fin_new;

		--********************************************

		DELETE pl
		FROM dbo.Paym_list AS pl 
			JOIN @tabl_occ AS t ON pl.occ = t.occ AND pl.fin_id=t.fin_id
		WHERE (pl.[value] = 0
			AND pl.Added = 0
			AND pl.Paid = 0
			AND pl.paymaccount = 0
			AND pl.saldo = 0
			AND pl.penalty_serv=0)

		DELETE pl
		FROM dbo.Paym_list AS pl 
			JOIN @tabl_occ AS t ON 
				pl.occ = t.occ 
				AND pl.fin_id=t.fin_new;

		UPDATE pl
		SET saldo = Debt
		  , value = 0
		  , Added = 0
		  , paid = 0
		  , paymaccount = 0
		  , paymaccount_peny = 0
		  , fin_id = @fin_new
		  , Penalty_old = Penalty_old + pl.penalty_serv
		FROM dbo.Paym_list AS pl 
			JOIN @tabl_occ AS t ON 
				pl.occ = t.occ 
				AND pl.fin_id=t.fin_id;

		SET @date1 = current_timestamp - @date1
		SET @msg = @name_tip + N'Фин.период ' + UPPER(@fin_current_str) + N' ЗАКРЫТ! Поздравляем! За ' + CONVERT(VARCHAR(25), @date1, 108)
		RAISERROR (@msg, 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Progress_proces (comp, Descriptions, user_fio)
		VALUES(@host, @msg, @user_fio)

		IF @tran_count = 0
			COMMIT TRANSACTION;

	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @tran_name;


		SET @strerror = @strerror + CONCAT('Тип фонда: ', @name_tip)
		--EXEC dbo.k_err_messages

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT
		IF @debug = 1
			PRINT @strerror

		RAISERROR (@strerror, 16, 1);

	END CATCH

END
go

