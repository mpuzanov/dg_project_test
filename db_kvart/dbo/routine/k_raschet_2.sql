CREATE   PROCEDURE [dbo].[k_raschet_2]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL -- Код финансового периода за который надо сделать расчет
	, @added SMALLINT = 0  --  0 - расчет за текущий фин. период
	  --  1 - расчет за прошлые фин. периоды
	  --  2 - разовые (некачественное предоставление услуг и недопоставка) 
	  --  3 - для расчета субсидий как @added=0 только 
	  --  кидаем суммы в PAYM_ADD 
	, @data1 DATETIME = NULL    -- начальная дата
	, @data2 DATETIME = NULL    -- конечная дата для перерасчетов
	, @tnorm1 SMALLINT = 0       -- нормативная температура
	, @tnorm2 SMALLINT = 0       -- насколько градусов меньше
	, @alladd SMALLINT = 0       -- 1-общий перерасчет
	, @lgotadayno SMALLINT = 0	   -- Не использовать расчет льготы по дням
	, @people_list BIT = 0       -- заносить расширенную информацию по расчету в PEOPLE_LIST_RAS
	, @serv_one1 VARCHAR(10) = NULL -- если надо расчитать только эту услугу 
	, @mode_history BIT = 0       -- при перерасчетах режимы брать из истории
	, @total_sq_new DECIMAL(10, 4) = NULL    -- расчитать на эту площадь
	, @debug BIT = 0
)
AS
	/*
	
	Процедура расчета квартплаты по заданному лицевому счету
	

	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON

	--SET LOCK_TIMEOUT 5000 
	--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	EXEC dbo.k_people_delete_status @occ = @occ1;

	--ALTER TABLE dbo.consmodes_list DISABLE TRIGGER ALL

	DECLARE @FinPeriodCurrent SMALLINT    -- Текущий фин. период
	SELECT @FinPeriodCurrent = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)
	--print @FinPeriodCurrent
	IF @fin_id1 IS NULL
		SET @fin_id1 = @FinPeriodCurrent

	-- Подготавливаем параметры
	IF @added IS NULL
		SET @added = 0
	IF @serv_one1 = '0'
		SET @serv_one1 = NULL
	IF @tnorm1 IS NULL
		SET @tnorm1 = 0
	IF @tnorm2 IS NULL
		SET @tnorm2 = 0

	IF @alladd IS NULL
		SET @alladd = 0
	IF @lgotadayno IS NULL
		SET @lgotadayno = 0
	IF @people_list IS NULL
		SET @people_list = 0
	IF @mode_history IS NULL
		SET @mode_history = 0
	-- ===================================
	IF @serv_one1 IS NOT NULL
	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Services
				WHERE id = @serv_one1
			)
			RAISERROR (N'код услуги <%s> не найден в БД', 16, 1, @serv_one1)
	END
	-- ***********************************  

	DECLARE @tip_id1 SMALLINT        -- Тип жилого фонда на лицевом
		  , @payms_tip1 BIT             -- Признак начисления по типу жилого фонда
		  , @is_paym_build BIT			    -- Признак начисления по дому
		  , @serv1 VARCHAR(10)     -- Услуга
		  , @mode1 INT             -- код режима потребления
		  , @source1 INT             -- код поставщика   
		  , @koef1 DECIMAL(10, 4)      -- коэффициент
		  , @is_koef1 BIT             -- использовать при расчете коэффициент или нет
		  , @is_norma1 BIT             -- рассчитывать норму на услугу или нет
		  , @is_subs1 BIT             -- рассчитывать субсидию на услугу или нет
		  , @tar1 DECIMAL(10, 4)  -- Тариф на услугу  по норме 
		  , @tar_counter1 DECIMAL(10, 4)  -- Тариф на услугу  по счётчику
		  , @extr_tar DECIMAL(10, 4)  -- Тариф на услугу  сверх нормы              
		  , @full_tar DECIMAL(10, 4)  -- Тариф на услугу  полный                       
		  , @FinPred SMALLINT        -- Предыдущий фин. период
		  , @FinPeriod SMALLINT        -- Финансовый период для расчета
		  , @flat_id1 INT				-- Код квартиры
		  , @CountOccFlats SMALLINT = 0     -- Количество лицевых в квартире
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @ras_subsid_only1 BIT				-- Расчет в базе только субсидий
		  , @LgotaRas1 BIT             -- Признак начисления льготы
		  , @serv_unit1 VARCHAR(10)     -- Ед. измерения услуги
		  , @roomtype1 VARCHAR(10)     -- Тип квартиры (отдельная или коммунальная) 
		  , @proptype1 VARCHAR(10)     -- Статус квартиры (неприв-ая, приват-ая, купленная)
		  , @status1 VARCHAR(10)     -- Статус лиц. счета
		  , @floor1 SMALLINT        -- Этаж
		  , @Start_date SMALLDATETIME   -- Начальная дата финансового  периода
		  , @End_date SMALLDATETIME   -- Конечная  дата финансового  периода
		  , @KolDayFinPeriod SMALLINT		-- Колличество дней в фин. периоде
		  , @KolDayAdd DECIMAL(10, 4)  -- Кол. дней для перерасчета
		  , @KoefAddSquare DECIMAL(10, 4)  -- 
		  , @SumSaldo DECIMAL(15, 4) = 0	-- Итоговое сальдо из файла OCCUPATIONS
		  , @SumSaldoAll DECIMAL(15, 4) = 0   -- Итоговое сальдо с учётом поставщиков
		  , @PaidAll DECIMAL(15, 4) = 0
		  , @AddedAll DECIMAL(15, 4) = 0
		  , @Saldo_edit SMALLINT            -- ручное изменение сальдо		  
		  , @SumSaldo_Serv DECIMAL(15, 4) = 0   -- 
		  , @Paymaccount1 DECIMAL(15, 4) = 0
		  , @Paymaccount_Serv DECIMAL(15, 4) = 0
		  , @Paymaccount_ServAll DECIMAL(15, 4) = 0
		  , @Paymaccount_peny1 DECIMAL(15, 4) = 0
		  , @Paymaccount_peny_serv1 DECIMAL(15, 4) = 0
		  , @build_id1 INT
		  , @koef_for_norma DECIMAL(5, 2) -- Повышающий коэффициент для нормативов
		  , @decimal_round INT = 2 -- кол-во знаков для округления начислений


	DECLARE @penalty_value1 DECIMAL(15, 4)
		  , @penalty_added1 DECIMAL(15, 4)
		  , @penalty_old_new1 DECIMAL(15, 4)
		  , @Penalty_old_edit SMALLINT            -- ручное изменение пени
		  , @Penalty_calc_glob1 BIT         -- 1-расчитывать пени в системе
		  , @Penalty_calc1 BIT         -- 1-расчитывать пени на лицевом
		  , @Penalty_calc_tip1 BIT         -- 1-расчитывать пени по типу жил.фонда
		  , @Penalty_calc_build1 BIT         -- 1-расчитывать пени по дому
		  , @Square DECIMAL(6, 2)   -- Площадь
		  , @kol_rooms SMALLINT        -- количество комнат
		  , @area_flat1 DECIMAL(6, 2)   -- Площадь помещения
		  , @Total_Sq1 DECIMAL(6, 2)   -- Общая площадь
		  , @Total_Sq_build DECIMAL(8, 2) = 0 -- Общая площадь жилых помещений в доме
		  , @Teplo_Sq1 DECIMAL(6, 2)   -- Отапливаемая площадь
		  , @Living_Sq1 DECIMAL(6, 2)   -- Жилая
		  , @SquareNorma DECIMAL(6, 2)   -- Площадь по соц. норме
		  , @NormaSingleBuild DECIMAL(12, 6)  -- Норматив по услуге по дому
		  , @NormaSingle DECIMAL(12, 6)  -- Соц.норма на одного
		  , @NormaSingleTmp DECIMAL(12, 6)  -- Соц.норма 
		  , @NormaMember DECIMAL(12, 6)  -- Соц.норма на семью из 3-х и более человек
		  , @NormaTwoSingle DECIMAL(12, 6)  -- Соц.норма на двоих
		  , @NormaThreeSingle DECIMAL(12, 6)  -- Соц.норма на троих
		  , @NormaFourSingle DECIMAL(12, 6)  -- Соц.норма на четверых по электроэнергии
		  
		  , @Norma_extr_tarif DECIMAL(12, 6)  -- норма для расчета по сверх нормативному
		  , @Norma_full_tarif DECIMAL(12, 6)  -- норма для расчете по 100% тарифу

		  , @Total_peopleReg SMALLINT     -- Общее кол-во проживающих которые участвуют в регистрации
		  , @Total_people1 SMALLINT     -- Общее кол-во проживающих на которых начислять услугу
		  , @Total_people_flats SMALLINT -- Общее кол-во проживающих в квартире на которых начислять услугу
		  , @Total_people_ee1 SMALLINT -- количество человек на которые расчитывается электричество
		  , @PeopleNetSocNorma SMALLINT -- Кол-во проживающих  для которых не расчитывать соц.норму

		  , @PeopleSocNorma SMALLINT    -- Кол-во проживающих  для которых расчитывать соц.норму
		  , @PeopleSocNormaAll SMALLINT -- Используется для корректировки нормы по льготам и субсидиям
		  , @PeopleSocNormaOwn SMALLINT    -- Кол-во проживающих  для которых расчитывать соц.норму

		  , @Sown DECIMAL(8, 2)
		  , @Sdola DECIMAL(8, 2)  -- Площадь по доле
		  , @SubsidTrue BIT            -- признак существования компенсации
		  , @SumLgotaAntena1 DECIMAL(15, 4)
		  , @AddGvrProcent1 DECIMAL(10, 4)
		  , @AddOtpProcent1 DECIMAL(10, 4)
		  , @NormaOb1 DECIMAL(5, 2)
		  , @NormaOb2 DECIMAL(5, 2)
		  , @NormaSub DECIMAL(5, 2)
		  , @NormaGKAL DECIMAL(10, 4)
		  , @subsid_only1 BIT  -- начисляется только субсидия т.е. value_subsid
		  , @is_counter1 SMALLINT -- 0 - нет счетчика; 1 - отдельная квитанция по счетчикам; 2 - начисляем в единую квитанцю
		  , @counter_metod SMALLINT -- метод расчета по счетчикам когда нет показаний
			--(0-не начислять,1-по норме,2-по среднему,3-по счетчику, 4-по общедомовому счётчику, 
			-- 5 - на основании другой услуги, 6 - не брать в расчет ППУ, 7 - начислять на 1 в своб л/сч, 8-ручной из карточки режимов)
		  , @counter_metod_global SMALLINT -- метод расчета по счетчикам когда нет показаний по умолчанию
		  , @counter_metod_kol DECIMAL(12, 6) -- На какое количество начислять по услуге если показаний нет или нет людей
		  , @counter_votv_ras1 BIT   -- ввести расчет за водоотведение по счётчикам
		  , @counter_votv_norma BIT   -- ввести расчет за водоотведение по норме
		  , @people0_counter_norma BIT -- Если нет людей использовать нормативы по счётчикам
		  , @raschet_agri BIT = 0
		  , @value_agri DECIMAL(15, 4) = 0
		  , @kol_agri DECIMAL(12, 6) = 0
		  , @counter_metod_service_kol VARCHAR(10)
		  , @avg_vday DECIMAL(12, 8) = 0
		  , @only_pasport BIT -- ведение только паспортного стола

	DECLARE @value1 DECIMAL(15, 4)      -- Начислено по услуге
		  , @discount1 DECIMAL(15, 4)      -- Льгота             
		  , @discount2 DECIMAL(15, 4)      -- Для проверки льготы по людям
		  , @kol DECIMAL(12, 6)      -- Количество едениц измерения на которые происходит начисление
		  , @kol_tmp DECIMAL(12, 6) = 0  -- Количество едениц измерения временная для расчётов
		  , @kol_norma DECIMAL(12, 6)      -- Нормативное Количество едениц измерения на которые происходит начисление
		  , @added1 DECIMAL(11, 4)      -- Разовые из PAYM_LIST
		  , @old_house BIT                 -- Ветхий дом
		  , @build_sup_out BIT = 0  -- в доме есть внешние услуги по поставщику
		  , @norma_gkal DECIMAL(9, 6)       -- норматив ГКал в доме на отопление
		  , @norma_gkal_gvs DECIMAL(9, 6)		-- норматив ГКал на подогрев гвс в доме        
		  , @norma_gaz_gvs DECIMAL(9, 6)		-- норматив газа на подогрев гвс в доме 
		  , @norma_gaz_otop DECIMAL(9, 6)		-- норматив газа на Отопление в доме
		  , @saldo_rascidka BIT					-- признак раскидки сальдо по услугам
		  , @service_house_votv VARCHAR(10) = N'канд' -- общедомовая услуга по водоотведению
		  , @Build_opu_sq DECIMAL(10, 4) = 0  -- общедомовая площадь
		  , @Build_opu_sq_elek DECIMAL(10, 4) = 0  -- общедомовая площадь по электроэнергии
		  , @Build_opu_sq_otop DECIMAL(10, 4) = 0  -- общедомовая площадь на отопление
		  , @Build_arenda_sq DECIMAL(10, 4) = 0  -- Площадь нежилых помещений в доме
		  , @Build_total_sq_old DECIMAL(10, 4) = 0  -- Площадь жилых помещений в доме
		  , @Build_total_area DECIMAL(10, 4) = 0  -- Площадь помещений в доме по паспорту
		  , @Build_total_area_soi DECIMAL(10, 4) = 0	-- Общая площадь дома для расчёта СОИ (ОДН)
		  , @Build_total_serv_soi DECIMAL(10, 4) = 0	-- Общая площадь дома для расчёта СОИ (ОДН) по услуге
		  , @serv_is_build BIT                 -- признак общедомовой услуги
		  , @occ_opu_sq DECIMAL(10, 4) = 0  -- доля общедомовой площади на лицевой счёт
		  , @is_counter_add_balance BIT = 0  -- Расчёт остатков по счётчикам и по норме
		  , @kol_saldo DECIMAL(12, 6) = 0
		  , @occ_serv_kol DECIMAL(12, 6) = 0	-- объём услуги из таблицы CONSMODES_LIST
		  , @ras_no_counter_poverka BIT					-- слежение за датой поверки
		  , @pkoef_rasch_dpoverka SMALLINT			-- Начислять ПовКоэф. если дата поверки истекла более X мес
		  , @occ_prefix_tip VARCHAR(3) = ''
		  , @is_only_quarter BIT					-- признак поквартального расчёта (март,июнь,сентябрь,декабрь)
		  , @opu_tepl_kol SMALLINT = 0	-- Количество ОПУ тепловой энергии
		  , @use_koef_build BIT = 0	-- Использовать коэффициенты для расчётов с домов
		  , @soi_metod_calc VARCHAR(10)			-- Метод расчета СОИ (@soi_metod_calc='CALC_TARIF', @soi_metod_calc='CALC_KOL')
		  , @soi_isTotalSq_Pasport BIT = 0  -- Брать для расчета СОИ площадь дома по паспорту
		  , @soi_votv_fact BIT = 0 -- Расчет Водоотведение СОИ по факту (ХВС сои + ГВС сои)
		  , @count_last_month_counter_value SMALLINT = 0 -- кол-во месяцев от последних показаний
		  , @count_min_month_for_avg_counter SMALLINT = 0 -- минимальное кол-во показаний(месяцев) для расчета по среднему
		  , @is_boiler BIT -- наличие бойлера в доме
	-- *************************************************************
	DECLARE @LiftFloor1 SMALLINT
		  , @LiftYear1 SMALLINT
		  , @LiftYear2 SMALLINT

	DECLARE @counter_id1 INT
		  , @date_ras_start SMALLDATETIME
		  , @date_ras_end SMALLDATETIME
		  , @kolDayRas SMALLINT
		  , @koefDayRas DECIMAL(10, 4)
		  , @date_start SMALLDATETIME
		  , @date_ras_occ_end SMALLDATETIME

	DECLARE @cessia_dolg_mes SMALLINT = 0
		  , @cessia_dolg_mes_start SMALLINT = 0
		  , @sup_id INT
		  , @collector_id SMALLINT
		  , @occ_sup INT
		  , @dog_int INT
	
	DECLARE @is_summer_period BIT = 0;  -- летний период (по отоплению)
	DECLARE @val_tmp DECIMAL(15,4)=0

	--*************************************
	SET @FinPred = @FinPeriodCurrent - 1
	IF @fin_id1 > @FinPeriodCurrent
		SET @fin_id1 = @FinPeriodCurrent

	IF @fin_id1 < @FinPeriodCurrent
	BEGIN
		SET @FinPeriod = @fin_id1
		IF (@added = 0)
			SET @added = 1
	END
	ELSE
		SET @FinPeriod = @FinPeriodCurrent

	SELECT @Start_date = start_date
		 , @End_date = end_date
		 , @LiftFloor1 = LiftFloor
		 , @LiftYear1 = LiftYear1
		 , @LiftYear2 = LiftYear2
		 , @NormaOb1 = Norma1
		 , @NormaOb2 = Norma2
		 , @NormaSub = NormaSub
		 , @SumLgotaAntena1 = SumLgotaAntena
		 , @AddGvrProcent1 = AddGvrProcent
		 , @AddOtpProcent1 = AddOtpProcent
		 , @Penalty_calc_glob1 = PenyRas
		 , @ras_subsid_only1 = ras_subsid_only
		 , @LgotaRas1 = LgotaRas
		 , @NormaGKAL = COALESCE(NormaGKAL, 0.016)
		 , @koef_for_norma = koef_for_norma
		 , @KolDayFinPeriod = KolDayFinPeriod
		 , @use_koef_build = use_koef_build
	FROM dbo.Global_values 
	WHERE fin_id = @FinPeriod

	--SELECT @KolDayFinPeriod=DATEDIFF(DAY, @start_date, DATEADD(MONTH, 1, @start_date) )

	-- Читаем начальные значения
	SELECT @SumSaldo = o.saldo
		 , @Saldo_edit = o.saldo_edit
		 , @tip_id1 = b.tip_id
		 , @payms_tip1 = ot.payms_value
		 , @is_paym_build = b.is_paym_build
		 , @area_flat1 = f.area
		 , @Total_Sq1 = o.total_sq
		 , @Teplo_Sq1 = o.TEPLO_SQ
		 , @Living_Sq1 = o.living_sq
		 , @floor1 = f.[floor]
		 , @status1 = o.status_id
		 , @roomtype1 = o.roomtype_id
		 , @Penalty_old_edit = o.Penalty_old_edit
		 , @Penalty_calc1 = o.Penalty_calc
		 , @penalty_value1 = o.penalty_value
		 , @penalty_added1 = o.penalty_added
		 , @penalty_old_new1 = o.Penalty_old_new
		 , @proptype1 = o.proptype_id
		 , @Paymaccount1 = o.paymaccount
		 , @Paymaccount_peny1 = o.paymaccount_peny
		 , @old_house = b.old
		 , @kol_rooms = o.Rooms
		 , @Penalty_calc_tip1 = ot.penalty_calc_tip
		 , @Penalty_calc_build1 = b.penalty_calc_build                                                       --  по умолчанию расчет пени по дому
		 , @counter_metod_global =  --  по умолчанию расчет по среднему
			CASE WHEN (ot.counter_metod IS NULL OR ot.counter_metod = -1) THEN 2 ELSE ot.counter_metod END 
		 , @counter_votv_ras1 = COALESCE(ot.counter_votv_ras, 0)                                             --  по умолчанию расчета нет
		 , @counter_votv_norma = CASE 
			WHEN b.counter_votv_norma=1 THEN 1
			ELSE COALESCE(ot.counter_votv_norma, 0)
		 END
		 , @build_id1 = b.id
		 , @norma_gkal = COALESCE(b.norma_gkal, @NormaGKAL)
		 , @norma_gkal_gvs = COALESCE(b.norma_gkal_gvs, 0)
		 , @norma_gaz_gvs = COALESCE(b.norma_gaz_gvs, 0)
		 , @norma_gaz_otop = COALESCE(b.norma_gaz_otop, 0)
		 , @saldo_rascidka = ot.saldo_rascidka
		 , @collector_id = b.collector_id
		 , @people0_counter_norma = ot.people0_counter_norma
		 , @date_ras_start = b.date_start
		 , @date_ras_end = b.date_end
		 , @date_start = o.date_start
		 , @date_ras_occ_end = o.date_end
		 , @flat_id1 = o.flat_id
		 , @Build_opu_sq = COALESCE(b.opu_sq, 0)
		 , @Build_opu_sq_elek = COALESCE(b.opu_sq_elek, 0)
		 , @Build_opu_sq_otop = COALESCE(b.opu_sq_otop, 0)
		 , @Build_arenda_sq = COALESCE(b.arenda_sq, 0)
		 , @Build_total_sq_old = COALESCE(b.build_total_sq, 0)
		 , @Build_total_area = COALESCE(b.build_total_area, 0)
		 , @raschet_agri = ot.raschet_agri
		 , @only_pasport = ot.only_pasport
		 , @is_counter_add_balance = ot.is_counter_add_balance
		 , @ras_no_counter_poverka =
		   CASE WHEN (b.ras_no_counter_poverka = 1) THEN b.ras_no_counter_poverka ELSE ot.ras_no_counter_poverka END
		 , @occ_prefix_tip = ot.occ_prefix_tip
		 , @is_only_quarter = COALESCE(ot.is_only_quarter, 0)
		 , @opu_tepl_kol = b.opu_tepl_kol
		 , @soi_metod_calc = COALESCE(b.soi_metod_calc, ot.soi_metod_calc)
		 , @soi_isTotalSq_Pasport = ot.soi_isTotalSq_Pasport
		 , @soi_votv_fact = CASE WHEN (ot.soi_votv_fact = 1) THEN ot.soi_votv_fact ELSE b.soi_votv_fact END -- если по типу фонда = истина то действует на все дома
		 , @decimal_round = COALESCE(b.decimal_round, ot.decimal_round)
		 , @count_min_month_for_avg_counter = ot.count_min_month_for_avg_counter
		 , @is_boiler = coalesce(b.is_boiler,0)
	FROM dbo.Occupations AS o 
		JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.id
		JOIN dbo.Flats AS f ON o.flat_id = f.id
		JOIN dbo.Buildings AS b ON f.bldn_id = b.id
	WHERE occ = @occ1

	--if @debug=1 print @norma_gkal
	-- проверку прописки уже сделали значит выходим
	IF @only_pasport = 1
	BEGIN
		UPDATE o
		SET kol_people = dbo.Fun_GetKolPeopleOccStatus(@occ1)
		  , [address] = [dbo].[Fun_GetAdres](@build_id1, o.flat_id, o.occ)
		  , value = 0
		  , paid = 0
		  , schtl = CASE WHEN (@occ_prefix_tip <> '') THEN dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) ELSE schtl END
		  , kol_people_reg = dbo.Fun_GetKolPeopleOccReg(@FinPeriodCurrent, o.occ)
		  , kol_people_all = dbo.Fun_GetKolPeopleOccAll(@FinPeriodCurrent, o.occ)
		  , kol_people_owner = [dbo].[Fun_GetKolPeopleOccOwner](o.occ)
		  , Paymaccount_ServAll = 0
		  , PaidAll = 0
		  , AddedAll = 0
		  , saldo_serv = 0
		  , fin_id = @FinPeriodCurrent
		FROM dbo.Occupations AS o
		WHERE occ = @occ1

		UPDATE pl
		SET value = 0
		  , paid = 0
		  , source_id = cl.source_id
		  , mode_id = cl.mode_id
		FROM dbo.Paym_list AS pl
			LEFT JOIN dbo.Consmodes_list cl ON pl.occ = cl.occ
				AND pl.service_id = cl.service_id
		WHERE pl.occ = @occ1
			AND pl.fin_id = @FinPeriod

		IF @debug = 1
			PRINT N'@only_pasport выходим не расчитывая'
		RETURN
	END
	-- *************************************************************
	--CREATE TABLE @people1
	DECLARE @people1 TABLE (
		  fin_id SMALLINT
		, occ INT
		, owner_id INT NOT NULL
		, people_uid UNIQUEIDENTIFIER NOT NULL
		, lgota_id SMALLINT
		, status_id TINYINT
		, status2_id VARCHAR(10) COLLATE database_default
		, birthdate SMALLDATETIME
		, doxod DECIMAL(9, 2)
		, KolDayLgota TINYINT
		, data1 SMALLDATETIME
		, data2 SMALLDATETIME
		, kolday TINYINT
		, DateEnd SMALLDATETIME
	)

	CREATE TABLE #people2
	--DECLARE #people2 TABLE  
	(
		  owner_id INT
		, service_id VARCHAR(10) COLLATE database_default
		, lgota_id SMALLINT
		, percentage DECIMAL(10, 4)
		, Snorm DECIMAL(10, 4)
		, owner_only BIT
		, norma_only BIT
		, nowork_only BIT
		, status_id TINYINT
		, is_paym BIT DEFAULT 1
		, is_lgota BIT
		, is_subs BIT
		, is_norma_all BIT
		, is_norma BIT
		, is_norma_sub BIT
		, is_rates TINYINT
		, birthdate SMALLDATETIME
		, tarif DECIMAL(10, 4) DEFAULT 0
		, data1 SMALLDATETIME
		, data2 SMALLDATETIME
		, kolday TINYINT DEFAULT 0
		, koefday DECIMAL(10, 4) DEFAULT 1
		, KolDayLgota TINYINT DEFAULT 0
		, KoefDayLgota DECIMAL(10, 4) DEFAULT 1
		, Sown_s DECIMAL(10, 4)
		, LgotaAll TINYINT DEFAULT 0
		, discount DECIMAL(10, 2) DEFAULT 0
		, owner_lgota INT DEFAULT 0
		, kol_day_fin AS (DATEDIFF(DAY, data1, data2) + 1)
		, is_kolpeople BIT DEFAULT 0
		, is_registration BIT DEFAULT 0  -- признак регистрации
		, is_owner_flat BIT DEFAULT 0 -- признак собственника
		, PRIMARY KEY (owner_id, service_id)
	)
	--CREATE INDEX SERV ON #people2 (SERVICE_ID)
	--CREATE INDEX percentage1 ON #people2 (percentage)

	DECLARE @paym_list1 TABLE
	--CREATE TABLE @paym_list1
	(
		  occ INT
		, service_id VARCHAR(10) COLLATE database_default
		, sup_id INT NOT NULL DEFAULT 0
		, subsid_only BIT NOT NULL DEFAULT 0
		, is_counter SMALLINT NOT NULL DEFAULT 0
		, account_one BIT NOT NULL DEFAULT 0
		, tarif DECIMAL(10, 4) NOT NULL DEFAULT 0
		, koef DECIMAL(10, 4) DEFAULT 1
		, kol DECIMAL(12, 6) NOT NULL DEFAULT 0	-- 27.02.09  08/09/2011
		, saldo DECIMAL(15, 4) NOT NULL DEFAULT 0
		, value DECIMAL(15, 4) NOT NULL DEFAULT 0
		, discount DECIMAL(15, 4) DEFAULT 0
		, added DECIMAL(15, 4) NOT NULL DEFAULT 0
		, paymaccount DECIMAL(15, 4) NOT NULL DEFAULT 0
		, paymaccount_peny DECIMAL(15, 4) NOT NULL DEFAULT 0
		, paid_h DECIMAL(15, 4) NOT NULL DEFAULT 0 -- за прошлый месяц
		, saldo_h DECIMAL(15, 4) NOT NULL DEFAULT 0
		, paid DECIMAL(15, 4) DEFAULT 0 --(VALUE-discount+added),
		, serv_unit VARCHAR(10) COLLATE database_default DEFAULT ''
		, metod SMALLINT DEFAULT NULL
		, mode_id INT DEFAULT NULL
		, source_id INT DEFAULT NULL
		, date_ras_start SMALLDATETIME DEFAULT NULL
		, date_ras_end SMALLDATETIME DEFAULT NULL
		, kol_norma DECIMAL(12, 6) NOT NULL DEFAULT 0
		, metod_old SMALLINT DEFAULT NULL
		, occ_sup INT DEFAULT NULL
		, paym_blocked BIT NOT NULL DEFAULT 0
		, add_blocked BIT NOT NULL DEFAULT 0
		, counter_metod SMALLINT NOT NULL DEFAULT 0
		, counter_metod_service_kol VARCHAR(10) NOT NULL DEFAULT ''
		, normaSingle DECIMAL(12, 6) NOT NULL DEFAULT 0
		, avg_vday DECIMAL(12, 8) NOT NULL DEFAULT 0
		, kol_saldo DECIMAL(12, 6) NOT NULL DEFAULT 0
		, kol_added DECIMAL(12, 6) NOT NULL DEFAULT 0
		, sup_id_all INT NOT NULL DEFAULT 0  -- заполняем по всем услугам
		, dog_int INT DEFAULT NULL
		, serv_counter VARCHAR(10) COLLATE database_default DEFAULT ''
		, koef_day DECIMAL(10, 4) DEFAULT NULL
		, penalty_prev DECIMAL(9, 2) NOT NULL DEFAULT 0
		, PRIMARY KEY (occ, service_id, sup_id)
		, UNIQUE (service_id, sup_id)
	)
	--CREATE UNIQUE INDEX SERV ON #paym_list1 (SERVICE_ID,sup_id) 
	--***********************************************************


	--*************************************
	-- Заносим текущую оплату по лицевому счету по единой квитанции  11.12.2007
	UPDATE dbo.Occupations
	SET paymaccount = COALESCE((
		SELECT SUM(p.value)
		FROM dbo.Payings AS p
		WHERE p.occ = @occ1
			AND p.fin_id = @FinPeriodCurrent
			AND p.sup_id = 0
			AND p.forwarded = 1
	), 0)
	WHERE occ = @occ1


	-- Оплата по поставщику
	--UPDATE oc
	--SET paymaccount = COALESCE((SELECT
	--		SUM(p.value)
	--	FROM dbo.PAYINGS AS p 
	--	JOIN dbo.PAYDOC_PACKS AS pd
	--		ON p.pack_id = pd.id
	--		AND pd.fin_id = @FinPeriodCurrent --oc.fin_id
	--		AND pd.forwarded = 1
	--	WHERE p.occ = oc.occ
	--	AND p.sup_id = oc.sup_id)
	--, 0)
	--FROM dbo.OCC_SUPPLIERS AS oc
	--WHERE oc.occ = @occ1
	--AND oc.fin_id = @FinPeriodCurrent

	UPDATE oc
	SET paymaccount = COALESCE(p.value, 0)
	FROM dbo.Occ_Suppliers AS oc
		LEFT JOIN (
			SELECT p.sup_id
				 , SUM(p.value) AS value
			FROM dbo.Payings AS p 
			WHERE p.occ = @occ1
				AND p.fin_id = @FinPeriodCurrent
				AND p.forwarded = 1
			GROUP BY p.sup_id
		) AS p ON oc.sup_id = p.sup_id
	WHERE oc.occ = @occ1
		AND oc.fin_id = @FinPeriodCurrent

	-- Заносим текущую оплату по лицевому счету по внутренним счётчикам  15.02.2011
	DECLARE @paymaccount_counter DECIMAL(9, 2)

	SELECT @paymaccount_counter =
		COALESCE((
			SELECT SUM(p.value)
			FROM dbo.Payings AS p 
				JOIN dbo.Consmodes_list AS cl ON p.occ = cl.occ
					AND p.service_id = cl.service_id
			WHERE p.occ = @occ1
				AND p.service_id IS NOT NULL
				AND p.fin_id = @FinPeriodCurrent
				AND p.forwarded = 1
				AND cl.is_counter = 2
		), 0)


	UPDATE dbo.Occupations
	SET paymaccount = paymaccount + @paymaccount_counter
	WHERE occ = @occ1

	--*************************************
	-- проверяем пени с прошлого месяца
	UPDATE O
	SET penalty_old = OH.Penalty_old_new + OH.penalty_value + OH.Penalty_added
	  , Penalty_old_new = OH.Penalty_old_new + OH.penalty_value + OH.Penalty_added
	FROM dbo.Occupations AS O
		JOIN dbo.Occ_history OH ON OH.occ = O.occ
	WHERE O.occ = @occ1
		AND OH.fin_id = @FinPred
		AND O.Penalty_old_edit = 0
		AND (O.penalty_old <> (OH.Penalty_old_new + OH.penalty_value + OH.Penalty_added))
		AND O.status_id <> 'закр'

	IF @status1 = 'закр'
	BEGIN
		--raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
		IF @FinPeriodCurrent = @fin_id1
		BEGIN  -- удаляем расчёт в текущем периоде
			DELETE dbo.Occ_Suppliers 
			WHERE occ = @occ1
				AND fin_id = @FinPeriodCurrent
			DELETE dbo.Paym_counter_all 
			WHERE occ = @occ1
				AND fin_id = @FinPeriodCurrent
			DELETE dbo.Added_Counters_All 
			WHERE occ = @occ1
				AND fin_id = @FinPeriodCurrent

			UPDATE dbo.Occupations
			SET saldo = 0
			  , saldo_serv = 0
			  , value = 0
			  , paymaccount = 0
			  , paymaccount_peny = 0
			  , penalty_value = 0
			  , Penalty_added = 0
			  , Penalty_old_new = 0
			  , Paymaccount_ServAll = 0
			  , PaidAll = 0
			  , AddedAll = 0
			  , SaldoAll = 0
			WHERE occ = @occ1
				AND (saldo <> 0 OR saldo_serv <> 0 OR value <> 0 OR paymaccount <> 0 OR penalty_value <> 0 OR Penalty_old_new <> 0 OR penalty_added <> 0 OR Paymaccount_ServAll <> 0)

			UPDATE o
			SET kol_people = COALESCE(p.kol_live, 0) --dbo.Fun_GetKolPeopleOccStatus(@occ1)
			  , kol_people_reg = COALESCE(p.kol_registration, 0) --dbo.Fun_GetKolPeopleOccReg(ot.fin_id, o.occ)
			  , kol_people_all = COALESCE(p.kol_itogo, 0) --dbo.Fun_GetKolPeopleOccAll(ot.fin_id, o.occ)
			  , kol_people_owner = COALESCE(p.kol_owner, 0) --dbo.Fun_GetKolPeopleOccOwner(o.occ)
			FROM dbo.Occupations AS o
				OUTER APPLY dbo.Fun_GetCountPeopleOcc(o.fin_id, o.occ) AS p
			WHERE o.occ = @occ1

			UPDATE dbo.Paym_list
			SET saldo = 0
			  , value = 0
			  , paymaccount = 0
			  , paymaccount_peny = 0
			  , penalty_prev = 0
			WHERE occ = @occ1

		END
		GOTO LABEL_END
	END

	--if @debug=1 select @added as added,@payms_tip1 as payms_tip1,@is_paym_build as is_paym_build,@fin_id1,@FinPeriodCurrent

	IF @is_only_quarter = 1
	BEGIN -- признак поквартального расчёта (март,июнь,сентябрь,декабрь)
		IF MONTH(@Start_date) NOT IN (3, 6, 9, 12)
			SET @payms_tip1 = 0
	END

	-- Текущий расчет и по дому или типу фонда не начисляем
	IF @added = 0
		AND (@payms_tip1 = 0
		OR @is_paym_build = 0)
		AND (@fin_id1 = @FinPeriodCurrent)
	BEGIN
		IF @debug = 1
			PRINT N'заполняем поля по услугам с предыдущего месяца и уходим на конец расчёта'

		INSERT INTO @paym_list1 (occ
							   , service_id
							   , sup_id
							   , account_one
							   , saldo
							   , value
							   , added
							   , paymaccount
							   , paymaccount_peny
							   , source_id
							   , mode_id
							   , penalty_prev)
		SELECT p2.occ
			 , p2.service_id
			 , COALESCE(cl.sup_id, p2.sup_id) AS sup_id
			 , COALESCE(cl.account_one, p2.account_one) AS account_one
			 , CASE WHEN (@Saldo_edit = 0) THEN p2.debt ELSE COALESCE(pl.saldo, 0) END AS saldo
			 , 0
			 , 0
			 , 0
			 , 0
			 , COALESCE(p2.source_id, cl.source_id) AS source_id
			 , COALESCE(p2.mode_id, cl.mode_id) AS mode_id
			 , COALESCE(p2.penalty_old + p2.penalty_serv, 0)
		FROM dbo.Paym_history p2 
			LEFT JOIN dbo.Consmodes_history ch 
				ON p2.fin_id = ch.fin_id
				AND p2.occ = ch.occ
				AND p2.service_id = ch.service_id
				AND p2.sup_id = ch.sup_id
			LEFT JOIN dbo.Consmodes_list cl 
				ON p2.occ = cl.occ
				AND p2.service_id = cl.service_id
				--AND p2.source_id = cl.source_id
				AND p2.sup_id = cl.sup_id   -- раскомментировал 09.12.17
			LEFT JOIN dbo.Paym_list pl ON pl.occ = p2.occ
				AND pl.service_id = p2.service_id
				AND pl.sup_id = p2.sup_id
				AND pl.fin_id = @fin_id1
		WHERE p2.occ = @occ1
			AND p2.fin_id = @FinPred
		OPTION (RECOMPILE)

		--IF @debug=1 SELECT 'PH',* FROM @paym_list1 ORDER BY service_id

		-- заполняем нулями остальные услуги
		INSERT INTO @paym_list1 (occ
							   , service_id
							   , sup_id
							   , subsid_only
							   , is_counter
							   , account_one
							   , tarif
							   , koef
							   , kol
							   , saldo
							   , value
							   , discount
							   , added
							   , paymaccount
							   , paymaccount_peny
							   , paid_h
							   , saldo_h
							   , serv_unit
							   , date_ras_start
							   , date_ras_end
							   , source_id
							   , mode_id
							   , dog_int)
		SELECT @occ1
			 , cl.service_id
			 , cl.sup_id
			 , 0
			 , 0
			 , cl.account_one
			 , 0
			 , 1
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , ''
			 , NULL
			 , NULL
			 , cl.source_id
			 , cl.mode_id
			 , dog_int
		FROM dbo.Consmodes_list cl 
		WHERE cl.occ = @occ1
			AND NOT EXISTS (
				SELECT 1
				FROM @paym_list1 p1
				WHERE p1.occ = cl.occ
					AND p1.service_id = cl.service_id
					AND p1.sup_id = cl.sup_id
			)
		--if @debug=1 SELECT 'CL',* FROM @paym_list1 ORDER BY service_id


		IF (@Saldo_edit = 1) OR (@Penalty_old_edit=1)
		BEGIN
			IF @debug = 1
				PRINT N'на лицевом было ручное изменение САЛЬДО берём его с текущего'

			UPDATE p
			SET saldo = CASE WHEN(@Saldo_edit = 1) THEN pl.saldo ELSE p.saldo END
			, penalty_prev = CASE WHEN (@Penalty_old_edit=1) THEN pl.penalty_prev ELSE p.penalty_prev END
			FROM @paym_list1 p
				JOIN dbo.Paym_list pl ON pl.occ = p.occ
					AND pl.service_id = p.service_id
					AND pl.sup_id = p.sup_id
					AND pl.fin_id = @fin_id1
		END

		--IF @debug=1 SELECT 'PL',* FROM @paym_list1 ORDER BY service_id

		GOTO LABEL_END_RASCHET;
	END


	IF (@added = 0)
		OR (@added = 3)
	BEGIN
		INSERT INTO @people1 EXEC k_PeopleFin @occ1
											, @FinPeriod
		SET @KoefAddSquare = 1
	--if @debug=1 select * from @people1
	END
	ELSE
	BEGIN  -- Перерасчет  
		IF (@data1 IS NULL
			OR @data2 IS NULL)
			OR (@data1 < @Start_date)
			OR (@data1 > @End_date)
			OR (@data2 < @data1)
			OR (@data2 > @End_date)
		BEGIN
			SELECT @data1 = @Start_date
				 , @data2 = @End_date
		END
		ELSE
		BEGIN
			SELECT @date_start = @data1
				 , @date_ras_end = @data2
		END
		SET @KolDayAdd = DATEDIFF(DAY, @data1, @data2) + 1

		--  **** было до 15.02.2005 для перерасчетов берем 30 дней в месяце 
		IF (@KolDayAdd >= @KolDayFinPeriod)
			SET @KoefAddSquare = 1
		ELSE
			SET @KoefAddSquare = @KolDayAdd / @KolDayFinPeriod --*0.0333
		--IF @debug=1 select @data1,@data2,@KolDayAdd,@KoefAddSquare
		-- 
		IF (@alladd = 0)
			--AND (@added <> 2)  -- 15/09/2021 -- не происходил перерасчет по людям за прошлые периоды
			INSERT INTO @people1 EXEC k_PeopleFin2 @occ1 = @occ1
												 , @fin_id1 = @FinPeriod
												 , @data1 = @data1
												 , @data2 = @data2
												 , @paym1 = 0
		ELSE -- при общем перерасчете надо поставить 1 на конце
			INSERT INTO @people1 EXEC k_PeopleFin2 @occ1 = @occ1
												 , @fin_id1 = @FinPeriod
												 , @data1 = @data1
												 , @data2 = @data2
												 , @paym1 = 1

		--if @debug=1 select * from @people1
		-- для возврата по отсутствующим и льготе
		IF (@added <> 2)
		BEGIN
			UPDATE @people1
			SET kolday = kol_day_add
			  , KolDayLgota = kol_day_add
			FROM @people1 AS p1
				JOIN People AS p ON p1.owner_id = p.id
			WHERE (p.kol_day_add BETWEEN 0 AND @KolDayFinPeriod)

			UPDATE @people1
			SET KolDayLgota = kol_day_lgota
			FROM @people1 AS p1
				JOIN People AS p ON p1.owner_id = p.id
			WHERE (p.kol_day_lgota BETWEEN 0 AND @KolDayFinPeriod)
				AND (p.kol_day_lgota <= kolday)
		END --if (@added<>2)
	--select * from @people1 
	END
	--if @debug=1 select * from @people1

	-- *** Подготовка к расчёту с учётом неполного месяца
	IF @date_start IS NOT NULL
		SET @date_ras_start = @date_start
	IF @date_ras_start IS NULL
		OR @date_ras_start < @Start_date
		SET @date_ras_start = @Start_date

	IF @date_ras_occ_end IS NOT NULL
		SET @date_ras_end = @date_ras_occ_end
	IF @date_ras_end IS NULL
		OR @date_ras_end > @End_date
		SET @date_ras_end = @End_date

	SET @kolDayRas = DATEDIFF(DAY, @date_ras_start, @date_ras_end) + 1
	IF @kolDayRas < 0
		SET @kolDayRas = 0
	--IF @debug=1 PRINT @kolDayRas
	-- *************************************************************

	-- Проверяем consmodes_list (есть ли все услуги)
	INSERT INTO dbo.Consmodes_list (occ
								  , service_id
								  , source_id
								  , fin_id
								  , mode_id
								  , sup_id
								  , subsid_only
								  , account_one
								  , is_counter)
	SELECT @occ1
		 , b1.service_id
		 , source_id
		 , @FinPeriodCurrent
		 , mode_id
		 , 0
		 , 0
		 , 0
		 , 0
	FROM dbo.Build_mode AS b1
		JOIN dbo.Build_source AS b2 ON b1.build_id = b2.build_id
			AND b1.service_id = b2.service_id
	WHERE b1.build_id = @build_id1
		AND (b1.mode_id % 1000 = 0)
		AND (b2.source_id % 1000 = 0)
		AND NOT EXISTS (
			SELECT *
			FROM dbo.Consmodes_list ct
			WHERE ct.occ = @occ1
				AND ct.service_id = b1.service_id
		)

	--**************************************************************

	SELECT *
	INTO #cl_temp
	FROM dbo.Consmodes_list 
	WHERE occ = @occ1

	CREATE INDEX serv_cl_temp ON #cl_temp (service_id)

	--IF @debug=1 SELECT * FROM #cl_temp ORDER BY service_id

	UPDATE #cl_temp
	SET subsid_only = 0
	FROM #cl_temp AS cm 
		JOIN dbo.Services AS s 
			ON cm.service_id = s.id
	WHERE cm.subsid_only = 1
		AND s.var_subsid_only = 0

	--DECLARE @t_serv_sup TABLE(serv VARCHAR(10) PRIMARY KEY, source_id INT, sup_id INT DEFAULT 0, dog_int INT)
	DECLARE @t_serv_sup TABLE (
		  serv VARCHAR(10)
		, source_id INT
		, sup_id INT DEFAULT 0
		, dog_int INT
		, PRIMARY KEY (serv, sup_id)
	)
	-- Задаем расчёты по поставщику 
	-- надо установить лицевые счета OCC_SERV, ACCOUNT_ONE
	--IF EXISTS(SELECT * FROM dbo.build_sup_out WHERE build_id=@build_id1)
	IF EXISTS (
			SELECT 1
			FROM dbo.View_dog_build 
			WHERE build_id = @build_id1
				AND fin_id = @fin_id1
				AND account_one = 1
		)
	BEGIN
		--IF @debug=1 PRINT 'находим услуги'
		--INSERT INTO @t_serv_sup
		--SELECT service_id, bs.sup_id
		--FROM dbo.BUILD_SUP_OUT AS bs
		--JOIN [dbo].[SUPPLIERS] AS s ON bs.sup_id=s.sup_id 	
		--WHERE build_id=@build_id1

		INSERT INTO @t_serv_sup (serv
							   , source_id
							   , sup_id
							   , dog_int)
		--SELECT DISTINCT bs.service_id, source_id, bs.sup_id, bs.id
		SELECT bs.service_id
			 , source_id
			 , bs.sup_id
			 , bs.id
		FROM dbo.View_dog_all AS bs 
		WHERE bs.build_id = @build_id1
			AND bs.fin_id = @fin_id1
			--AND bs.tip_id=@tip_id1
			AND bs.account_one = 1

		--IF @debug=1 SELECT * FROM @t_serv_sup ORDER BY 1

		--SELECT *	
		DELETE bs
		FROM @t_serv_sup AS bs
		WHERE EXISTS (
				SELECT 1
				FROM Suppliers_types st
				WHERE st.tip_id = @tip_id1
					AND bs.serv = st.service_id
					AND st.paym_blocked = 1
					AND st.sup_id = bs.sup_id
					AND EXISTS (
						SELECT 1
						FROM @t_serv_sup AS bs2
						WHERE bs2.serv = st.service_id
							AND st.sup_id <> bs2.sup_id
					--AND st.paym_blocked=0
					)
			)
		--IF @debug=1 SELECT * FROM @t_serv_sup ORDER BY 1

		--AND NOT EXISTS(select 1 FROM SUPPLIERS_TYPES st WHERE st.tip_id=bs.tip_id AND bs.service_id=st.service_id
		--AND st.paym_blocked=1 AND st.sup_id=bs.sup_id)	
		--AND NOT EXISTS(select 1 FROM SUPPLIERS_BUILD AS sb WHERE sb.build_id=bs.build_id AND bs.service_id=sb.service_id
		--AND sb.paym_blocked=1 AND sb.sup_id=bs.sup_id)		
		--AND tip_id=@tip_id1

		--IF EXISTS(SELECT * FROM @t_serv) SET @build_sup_out=1

		--UPDATE cm 
		--SET account_one=0
		--FROM dbo.consmodes_list AS cm
		--WHERE cm.occ=@occ1
		--IF @debug=1 SELECT * FROM consmodes_list WHERE occ=@occ1 ORDER BY service_id

		--UPDATE cm 
		--SET account_one=CASE WHEN sp.sup_id>0 THEN 1 ELSE cm.account_one END,
		--	sup_id=CASE WHEN sp.sup_id>0 THEN sp.sup_id ELSE cm.sup_id END,
		--	dog_int=CASE WHEN sp.dog_int>0 THEN sp.dog_int ELSE cm.dog_int END
		--FROM dbo.consmodes_list AS cm
		--LEFT JOIN @t_serv_sup AS sp ON cm.service_id=sp.serv AND cm.source_id=sp.source_id --AND cm.sup_id=sp.sup_id
		--WHERE cm.occ=@occ1

		UPDATE cm
		SET account_one =
						 CASE
							 WHEN sp.sup_id > 0 THEN 1
							 WHEN sp.sup_id IS NULL THEN cm.account_one
							 ELSE 0
						 END
		  , --cm.account_one END,
			sup_id =
					CASE
						WHEN sp.sup_id > 0 THEN sp.sup_id
						WHEN sp.sup_id IS NULL THEN cm.sup_id
						ELSE 0
					END
		  , --cm.sup_id END,
			dog_int =
					 CASE
						 WHEN sp.dog_int > 0 THEN sp.dog_int
						 WHEN sp.dog_int IS NULL THEN cm.dog_int
						 ELSE 0
					 END -- cm.dog_int END
		  , fin_id = @FinPeriodCurrent
		FROM #cl_temp AS cm
			LEFT JOIN @t_serv_sup AS sp ON cm.service_id = sp.serv
				AND cm.source_id = sp.source_id --AND cm.sup_id=sp.sup_id
		WHERE cm.occ = @occ1

		IF @@rowcount > 0
			SET @build_sup_out = 1
	--IF @debug=1 PRINT @build_sup_out
	--IF @debug=1 SELECT * FROM consmodes_list WHERE occ=@occ1

	--IF @build_sup_out=1
	--BEGIN
	--	UPDATE cm 
	--	SET account_one=1,
	--		sup_id=sp.sup_id,
	--		dog_int=sp.dog_int,
	--		source_id=sp.source_id
	--	FROM dbo.consmodes_list AS cm
	--		 JOIN @t_serv_sup AS sp ON cm.service_id=sp.serv AND cm.sup_id=sp.sup_id
	--	WHERE cm.occ=@occ1
	--	AND cm.service_id='гв2д'		
	--	--IF @debug=1 SELECT * FROM @t_serv_sup
	--end
	END
	ELSE
		UPDATE cm
		SET account_one = 0
		  , sup_id = 0
		  , fin_id = @FinPeriodCurrent
		FROM #cl_temp AS cm
		WHERE cm.occ = @occ1
			AND @added = 0  -- только в текущем периоде

	--IF @debug=1 select * from @t_serv_sup
	--IF @debug=1 select * from dbo.consmodes_list WHERE occ=@occ1
	-- ************************************************************* 

	IF @fin_id1 < @FinPeriodCurrent
	BEGIN
		SELECT @tip_id1 = o.tip_id
			 , @SumSaldo = saldo
			 , @status1 = status_id
			 , @proptype1 = proptype_id
			 , @Paymaccount1 = paymaccount
			 , @Paymaccount_peny1 = paymaccount_peny
			 , @old_house = b.old
			 , @norma_gkal = COALESCE(b.norma_gkal, @norma_gkal)
			 , @norma_gkal_gvs = COALESCE(b.norma_gkal_gvs, @norma_gkal_gvs)
			 , @norma_gaz_gvs = COALESCE(b.norma_gaz_gvs, @norma_gkal_gvs)
			 , @norma_gaz_otop = COALESCE(b.norma_gaz_otop, @norma_gkal_gvs)
		FROM dbo.Occ_history AS o 
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings_history AS b
				ON f.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
		WHERE o.fin_id = @fin_id1
			AND occ = @occ1

		IF (@added <> 0
			AND @mode_history <> 0)
			SELECT @Total_Sq1 = total_sq
				 , @Teplo_Sq1 =
							   CASE
								   WHEN @Teplo_Sq1 = 0 THEN total_sq
								   ELSE @Teplo_Sq1
							   END
			FROM dbo.Occ_history AS o 
			WHERE fin_id = @fin_id1
				AND occ = @occ1

	END

	--*************************************

	IF @Total_Sq1 IS NULL
	BEGIN
		-- Такого лицевого нет
		GOTO LABEL_END
	END

	--******************************************************
	SET @SubsidTrue = 0
	/*
	Расчёт субсидий сейчас не ведём
	IF EXISTS(SELECT * FROM dbo.View_COMPENSAC WHERE occ=@occ1 AND fin_id=@FinPeriodCurrent)
	   SET @SubsidTrue=1   -- Компенсация по этому лицевому есть 
	ELSE
	IF  @added>0 AND --и была субсидия
	    EXISTS(SELECT * FROM dbo.View_COMPENSAC WHERE occ=@occ1 AND fin_id=@fin_id1)
	    SET @SubsidTrue=1
	*/

	-- *** Подготовка к расчёту с учётом неполного месяца по людям   27/08/2012
	UPDATE @people1
	SET data1 = @date_ras_start
	WHERE data1 < @date_ras_start

	UPDATE @people1
	SET data2 = @date_ras_end
	WHERE data2 > @date_ras_end

	IF @added = 2
		AND @data1 IS NOT NULL
		AND @data2 IS NOT NULL
		SELECT @date_ras_start = @data1
			 , @date_ras_end = @data2

	UPDATE @people1
	SET kolday =
				CASE
					WHEN data2 < data1 THEN 0
					WHEN kolday < DATEDIFF(DAY, data1, data2) + 1 THEN kolday
					ELSE DATEDIFF(DAY, data1, data2) + 1
				END
	-- ************************************************************ 
	--if @debug=1 select * from @people1

	SELECT @Total_peopleReg = COUNT(p.owner_id)
	FROM @people1 AS p
		JOIN Person_statuses AS ps 
			ON p.status2_id = ps.id
	WHERE ps.is_registration = 1
	IF @Total_peopleReg IS NULL
		SET @Total_peopleReg = 0

	-- *************************************************************
	-- люди по которым проводится начисления по статусом прописки
	DELETE FROM @people1
	FROM @people1 AS p
		JOIN Person_statuses AS ps 
			ON p.status2_id = ps.id
	WHERE ps.is_paym <> 1
	-- *************************************************************

	-- Проверяем время действия льгот
	--UPDATE @people1
	--SET Lgota_id=0
	--FROM  dsc_owners AS dsc 
	--      JOIN @people1 AS p ON dsc.owner_id=p.owner_id AND dsc.dscgroup_id=p.lgota_id
	--WHERE  
	--      p.lgota_id>0
	--      AND dsc.active=1 
	--      AND dsc.expire_date<@start_date

	--if not exists(select owner_id from @people1) set @status1='своб'
	--if @debug=1 select * from @people1

	-- *************************************************************
	-- Список людей и услуг по которым проводиться начисления
	INSERT INTO #people2 (owner_id
						, service_id
						, lgota_id
						, percentage
						, Snorm
						, owner_only
						, norma_only
						, nowork_only
						, status_id
						, is_paym
						, is_lgota
						, is_subs
						, is_norma_all
						, is_norma
						, is_norma_sub
						, is_rates
						, birthdate
						, tarif
						, data1
						, data2
						, kolday
						, koefday
						, KolDayLgota
						, KoefDayLgota
						, Sown_s
						, LgotaAll
						, discount
						, owner_lgota
						, is_kolpeople
						, is_registration
					    , is_owner_flat)
	SELECT p.owner_id
		 , pc.service_id
		 , 0 AS lgota_id
		 , 0 AS percentage
		 , 0 AS Snorm
		 , 0 AS owner_only
		 , 0 AS norma_only
		 , 0 AS nowork_only
		 , p.status_id
		 , pc.have_paym
		 , ps.is_lgota
		 , ps.is_subs
		 , ps.is_norma_all
		 , ps.is_norma
		 , ps.is_norma_sub
		 , pc.is_rates
		 , p.birthdate
		 , 0 AS tarif
		 , p.data1
		 , p.data2
		 , p.kolday AS kolday
		 , CASE
			   -- разовые (недопоставка, некачественное) 
			   WHEN (@added = 2) AND
				   (pc.service_id IN (N'гвод', N'гвс2', N'гвсд', N'отоп')) THEN
				   --CAST(p.kolday AS DECIMAL(8,4))/30    убрал 22.05.13
				   CAST(p.kolday AS DECIMAL(8, 4)) / @KolDayFinPeriod
			   ELSE CAST(p.kolday AS DECIMAL(8, 4)) / @KolDayFinPeriod
		   END AS koefday
		 , p.koldaylgota AS koldaylgota
		 , 0 AS KoefDayLgota
		 , 0 AS Sown_s
		 , 0 AS LgotaAll
		 , 0 AS discount
		 , p.owner_id AS owner_lgota
		 , ps.is_kolpeople
		 , ps.is_registration
		 , p1.is_owner_flat -- признак собственника
	FROM @people1 AS p
		JOIN dbo.People as p1 
			ON p.owner_id=p1.id
		JOIN dbo.Person_statuses AS ps 
			ON p.status2_id = ps.id
		JOIN dbo.Person_calc AS pc 
			ON ps.id = pc.status_id
		JOIN dbo.Service_units AS su 
			ON pc.service_id = su.service_id
	--LEFT JOIN dbo.discounts AS dsc ON p.lgota_id=dsc.dscgroup_id AND pc.service_id=dsc.service_id AND dsc.proptype_id=@proptype1
	WHERE
		-- and pc.have_paym=1 
		su.roomtype_id = @roomtype1
		AND su.fin_id = @FinPeriod
		AND su.tip_id = @tip_id1

	--UPDATE #people2
	--SET koefdaylgota=1,
	--    koldaylgota=0
	--WHERE lgota_id=0

	--UPDATE #people2
	--SET LgotaAll=lgota_id
	--WHERE lgota_id>0 AND is_lgota=1

	--select @KolDayFinPeriod,@added
	--select * from @people1

	-- Если не начисляем по данному жилому фонду обнуляем основные параметры
	IF @is_paym_build = 0
		SET @payms_tip1 = 0
	IF @payms_tip1 = 0
		AND (@added <> 0)
		SET @payms_tip1 = 1 -- если перерасчёт то делаем расчёты
	IF (@payms_tip1 = 0)
		AND (@added = 0)
	BEGIN
		DELETE FROM @people1
		DELETE FROM #people2
		SET @Total_Sq1 = 0
		SET @Teplo_Sq1 = 0
		SET @Living_Sq1 = 0
	END

	IF NOT EXISTS (SELECT 1 FROM @people1)
		AND @fin_id1 = @FinPeriodCurrent
		AND @status1 = N'откр'
		AND @payms_tip1 = 1
	BEGIN
		SET @status1 = N'своб'
	END

	IF EXISTS (SELECT 1 FROM @people1)
		--AND @fin_id1=@FinPeriodCurrent -- 16/01/2014
		AND @status1 = N'своб'
		AND @payms_tip1 = 1
	BEGIN
		SET @status1 = N'откр'
	END

	--**************************************************************
	--if @debug=1 select * from @people1
	--if @debug=1 select * from #people2
	CREATE TABLE #services1 (
		  --DECLARE @services1 TABLE( 
		  id VARCHAR(10) COLLATE database_default
		, sup_id INT
		, is_paym BIT
		, is_koef BIT
		, is_norma BIT
		, is_subsid BIT
		, mode_id INT
		, source_id INT
		, koef DECIMAL(6, 4)
		, subsid_only BIT
		, unit_id VARCHAR(10) COLLATE database_default
		, is_counter SMALLINT
		, tar DECIMAL(10, 4)
		, extr_tar DECIMAL(10, 4)
		, full_tar DECIMAL(10, 4)
		, sort_no TINYINT DEFAULT 100
		, dog_int INT DEFAULT NULL
		, is_build BIT DEFAULT 0
		, sort_paym TINYINT DEFAULT 0
		, date_ras_start SMALLDATETIME DEFAULT NULL
		, date_ras_end SMALLDATETIME DEFAULT NULL
		, avg_vday DECIMAL(12, 8) DEFAULT 0
		, tar_counter DECIMAL(10, 4) DEFAULT 0
		, q_single DECIMAL(12, 6) DEFAULT 0
		, q_member DECIMAL(12, 6) DEFAULT 0
		, two_single DECIMAL(12, 6) DEFAULT 0
		, three_single DECIMAL(12, 6) DEFAULT 0
		, total_people_flats SMALLINT DEFAULT 0
		, counter_metod_kol DECIMAL(12, 6) DEFAULT 0
		, counter_metod SMALLINT DEFAULT NULL
		, counter_metod_service_kol VARCHAR(10) DEFAULT ''
		, pkoef_rasch_dpoverka SMALLINT DEFAULT -999
		, occ_serv_kol DECIMAL(12, 6) DEFAULT 0
		, is_counter_add_balance BIT DEFAULT 0
		, count_last_month_counter_value SMALLINT DEFAULT 0 NOT NULL
		  PRIMARY KEY (id, sup_id)
	)

	-- заполняем нулями
	INSERT INTO @paym_list1 (occ
						   , service_id
						   , sup_id
						   , account_one
						   , saldo
						   , value
						   , added
						   , paymaccount
						   , paymaccount_peny
						   , source_id
						   , mode_id
						   , penalty_prev)
	--SELECT p2.occ, p2.service_id, p2.sup_id,p2.account_one,p2.debt,0, 0, 0,0
	SELECT p2.occ
		 , p2.service_id
		 , COALESCE(cl.sup_id, p2.sup_id)
		 , COALESCE(cl.account_one, p2.account_one)
		 , CASE WHEN (@Saldo_edit = 1) THEN 0 ELSE p2.debt END AS Saldo
		 , 0
		 , 0
		 , 0
		 , 0
		 , source_id = COALESCE(p2.source_id, cl.source_id)
		 , mode_id = COALESCE(p2.mode_id, cl.mode_id)
		 , CASE 
			 WHEN (@Penalty_old_edit = 1) THEN COALESCE(pl.penalty_prev,0)
			 ELSE (p2.penalty_old + p2.penalty_serv) 
		   END AS penalty_prev
	FROM dbo.Paym_history p2
		LEFT JOIN dbo.Paym_list as pl ON pl.occ = p2.occ
				AND pl.service_id = p2.service_id
				AND pl.sup_id = p2.sup_id
		LEFT JOIN dbo.Consmodes_history ch ON p2.fin_id = ch.fin_id
			AND p2.occ = ch.occ
			AND p2.service_id = ch.service_id
			AND p2.sup_id = ch.sup_id
		LEFT JOIN #cl_temp cl
			ON ch.occ = cl.occ
			AND ch.service_id = cl.service_id
			AND ch.source_id = cl.source_id
			AND ch.sup_id = cl.sup_id
	WHERE p2.occ = @occ1
		AND p2.fin_id = @FinPred
	OPTION (RECOMPILE)

	--if @debug=1 SELECT * FROM @paym_list1
	-- заполняем нулями остальные услуги
	INSERT INTO @paym_list1 (occ
						   , service_id
						   , sup_id
						   , subsid_only
						   , is_counter
						   , account_one
						   , tarif
						   , koef
						   , kol
						   , saldo
						   , value
						   , discount
						   , added
						   , paymaccount
						   , paymaccount_peny
						   , paid_h
						   , saldo_h
						   , serv_unit
						   , date_ras_start
						   , date_ras_end)
	SELECT @occ1
		 , cl.service_id
		 , cl.sup_id
		 , 0 AS subsid_only
		 , 0 AS is_counter
		 , 0 AS account_one
		 , 0 AS tarif
		 , 1 AS koef
		 , 0 AS kol
		 , 0 AS saldo
		 , 0 AS value
		 , 0 AS discount
		 , 0 AS added
		 , 0 AS paymaccount
		 , 0 AS paymaccount_peny
		 , 0 AS paid_h
		 , 0 AS saldo_h
		 , '' AS serv_unit
		 , NULL AS date_ras_start
		 , NULL AS date_ras_end
	FROM #cl_temp cl
	WHERE NOT EXISTS (
			SELECT 1
			FROM @paym_list1 p1
			WHERE p1.occ = cl.occ
				AND p1.service_id = cl.service_id
				AND p1.sup_id = cl.sup_id
		)

	--if @debug=1 SELECT * FROM @paym_list1
	-- Проверяем счетчики  *******************************
	CREATE TABLE #t_counter (
		  counter_id INT
		, service_id VARCHAR(10) COLLATE database_default
		, internal BIT
		, unit_id VARCHAR(10) COLLATE database_default
	)

	INSERT INTO #t_counter (counter_id
						  , service_id
						  , internal
						  , unit_id)
	SELECT cl.counter_id
		 , cl.service_id
		 , cl.internal
		 , c.unit_id
	FROM dbo.Counter_list_all AS cl
		JOIN dbo.Counters c
			ON cl.counter_id = c.id
	WHERE cl.occ = @occ1
		AND cl.service_id = c.service_id
		AND cl.fin_id = @FinPeriod

	UPDATE #cl_temp
	SET is_counter =
					CASE
						WHEN cl.internal = 1 THEN 2
						ELSE 1
					END
	FROM #cl_temp AS cm 
		JOIN #t_counter AS cl 
			ON cm.service_id = cl.service_id

	UPDATE #cl_temp
	SET is_counter = 0
	FROM #cl_temp AS cm 
		JOIN dbo.Services AS s 
		ON cm.service_id = s.id
	WHERE s.is_counter = 1
		AND NOT EXISTS (
			SELECT 1
			FROM #t_counter AS cl 
			WHERE cl.service_id = cm.service_id
		)

	-- ****** Помечаем отдельные квитанции *****
	--UPDATE cl
	--SET account_one=sp.account_one
	--FROM dbo.consmodes_list AS cm 
	--     JOIN dbo.View_SUPPLIERS AS sp ON cm.source_id=sp.id
	--     JOIN #cl_temp AS cl ON cm.service_id=cl.service_id
	--WHERE cm.occ=@occ1

	-- 
	UPDATE #cl_temp
	SET occ_serv = NULL
	WHERE (sup_id = 0 AND subsid_only = 0)

	--UPDATE #cl_temp
	--SET  occ_serv=null
	--WHERE (coalesce(is_counter,0)=0 AND account_one=0)

	UPDATE #cl_temp
	SET occ_serv = dbo.Fun_GetService_Occ(occ, service_id)
	WHERE is_counter = 1 -- внешний счётчик
	--OR account_one=1

	--if @debug=1 SELECT * FROM #cl_temp ct

	-- если не перерасчёты то обновляем режимы
	IF @added = 0
	BEGIN
		UPDATE cl
		SET occ_serv = dbo.Fun_GetOccSUP(@occ1, cl.sup_id, sup.dog_int)
		  , dog_int =
					 CASE
						 WHEN (cl.sup_id > 0 AND cl.dog_int IS NULL) THEN (
								 SELECT TOP 1 id
								 FROM dbo.View_dog_all
								 WHERE fin_id = @fin_id1
									 AND build_id = @build_id1
									 AND sup_id = cl.sup_id
							 )
						 ELSE cl.dog_int
					 END
		FROM #cl_temp AS cl
			JOIN @t_serv_sup AS sup ON cl.service_id = sup.serv
				AND (cl.source_id = sup.source_id OR (cl.source_id % 1000) = 0) --AND cl.sup_id = sup.sup_id
		WHERE cl.occ = @occ1
			AND cl.sup_id > 0

		UPDATE cl
		SET dog_int =
					 CASE
						 WHEN (cl.dog_int IS NULL) THEN (
								 SELECT TOP 1 id
								 FROM dbo.View_dog_all vd
								 WHERE vd.fin_id = @fin_id1
									 AND vd.build_id = @build_id1
									 AND vd.sup_id = cl.sup_id
							 )
						 ELSE cl.dog_int
					 END
		  , occ_serv =
					  CASE
						  WHEN (occ_serv IS NULL) THEN dbo.Fun_GetOccSUP(@occ1, cl.sup_id, cl.dog_int)
						  ELSE occ_serv
					  END
		FROM #cl_temp AS cl
		WHERE cl.occ = @occ1
			AND cl.sup_id > 0

		UPDATE cm
		SET account_one = 0
		  , sup_id = 0
		FROM #cl_temp AS cm
		WHERE cm.occ = @occ1
			AND service_id = 'цеся'
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Cessia C 
				WHERE C.occ_sup = cm.occ_serv
					AND C.occ = cm.occ
			)
			AND @added = 0

		--UPDATE cl
		--SET  
		--  subsid_only=t.subsid_only,
		--  is_counter=t.is_counter,
		--  account_one=t.account_one,
		--  occ_serv=t.occ_serv,
		--  koef=CASE
		--  WHEN koef=1 AND t.service_id NOT IN ('наем','капр') THEN NULL
		--  ELSE koef
		--  end
		--  ,dog_int=T.dog_int
		--FROM #cl_temp AS t
		--	 JOIN dbo.consmodes_list AS cl ON cl.service_id=t.service_id
		--WHERE cl.occ=@occ1 

		DELETE FROM dbo.Consmodes_list
		WHERE occ = @occ1
		INSERT INTO dbo.Consmodes_list
		SELECT *
		FROM #cl_temp ct
	END

	--**************************************************************
	UPDATE p
	SET account_one =
					 CASE
						 WHEN cm.sup_id > 0 THEN 1
						 ELSE cm.account_one
					 END
	  , sup_id = cm.sup_id
	  , occ_sup = CASE WHEN(cm.occ_serv > 0) THEN cm.occ_serv ELSE NULL END
	  , source_id = cm.source_id
	  , dog_int = cm.dog_int
	FROM @paym_list1 AS p
		JOIN #cl_temp AS cm 
			ON p.occ = cm.occ
			AND p.service_id = cm.service_id
			AND p.sup_id = cm.sup_id
	--WHERE 
	--	p.account_one<>cm.account_one
	--	OR p.sup_id=cm.sup_id
	-- ******
	--if @debug=1 SELECT * FROM @t_serv_sup
	--if @debug=1 SELECT * FROM #cl_temp ct
	--if @debug=1 SELECT * FROM consmodes_list WHERE occ=@occ1
	--if @debug=1 SELECT * FROM @paym_list1

	--*** Заводим начальное сальдо ***-------------
	--if @debug=1 select * from @paym_list1 where occ=@occ1

	--IF @debug=1 PRINT @FinPred
	--IF @debug=1 PRINT @Saldo_edit

	IF @fin_id1 = @FinPeriodCurrent
	BEGIN
		-- Если нет начисления за предыдущий месяц
		IF @Saldo_edit = 1  -- или сальдо исправлено в ручную
			OR NOT EXISTS (
				SELECT 1
				FROM dbo.Paym_history 
				WHERE fin_id = @FinPred
					AND occ = @occ1
			)
		BEGIN
			--IF @debug=1  PRINT 'p2.saldo'
			UPDATE p1
			SET saldo = p2.saldo, penalty_prev = p2.penalty_prev
			FROM @paym_list1 AS p1
				JOIN dbo.Paym_list AS p2 
					ON p1.occ = p2.occ
					AND p1.service_id = p2.service_id
					AND p1.sup_id = p2.sup_id
			WHERE p2.fin_id = @fin_id1
		END

	-- ELSE  -- иначе берем конечное сальдо предыдущего месяца
	--BEGIN
	--	IF @debug=1  PRINT 'p2.debt '
	--	UPDATE p1
	--	SET saldo=p2.debt, sup_id=p2.sup_id--, account_one=p2.account_one
	--	FROM @paym_list1 AS p1
	--		 JOIN dbo.paym_history AS p2 ON p1.occ=p2.occ AND p1.service_id=p2.service_id AND p1.sup_id = p2.sup_id
	--	WHERE      
	--	 p2.fin_id=@FinPred

	--END
	END
	ELSE -- Прошлые периоды
	BEGIN
		--PRINT 'ELSE p2.saldo'
		UPDATE p1
		SET saldo = p2.saldo  -- берем то сальдо которое было в том месяце
			, penalty_prev = p2.penalty_prev
		FROM @paym_list1 AS p1
			JOIN dbo.Paym_history AS p2 
				ON p1.occ = p2.occ
				AND p1.service_id = p2.service_id
				AND p1.sup_id = p2.sup_id
				AND p2.fin_id = @fin_id1		
	END

	UPDATE p
	SET source_id = cm.source_id
	FROM @paym_list1 AS p
		JOIN #cl_temp AS cm 
			ON p.occ = cm.occ
			AND p.service_id = cm.service_id
	WHERE p.source_id IS NULL

	UPDATE cm
	SET account_one = 1 --p.account_one
	  , sup_id = p.sup_id
	  , occ_serv = dbo.Fun_GetOccSUP(@occ1, p.sup_id, cm.dog_int)
	FROM @paym_list1 AS p
		JOIN dbo.Consmodes_list AS cm 
			ON p.occ = cm.occ
			AND p.service_id = cm.service_id
			AND cm.source_id = p.source_id
	WHERE p.sup_id > 0
		AND @added = 0
		AND NOT EXISTS (
			SELECT 1
			FROM #cl_temp ct
			WHERE ct.occ = p.occ
				AND ct.service_id = p.service_id
				AND ct.source_id = p.source_id
				AND ct.sup_id = p.sup_id
		)

	--*******************************************************************************
	-- Отмечаем услуги по которым расчёт по типу фонда или по дому заблокирован
	UPDATE p1
	SET paym_blocked =
					  CASE
						  WHEN Sb.paym_blocked = 1 THEN 1
						  WHEN ST.paym_blocked = 1 THEN 1
						  ELSE 0
					  END
	FROM @paym_list1 AS p1
		LEFT JOIN dbo.Services_types AS ST ON p1.service_id = ST.service_id
			AND ST.tip_id = @tip_id1
		LEFT JOIN dbo.Services_build AS Sb ON p1.service_id = Sb.service_id
			AND Sb.build_id = @build_id1


	--SELECT * FROM @paym_list1

	UPDATE p1
	SET sup_id_all = S.sup_id
	FROM @paym_list1 AS p1
		JOIN dbo.Suppliers AS S ON S.id = p1.source_id

	IF @added = 0
	BEGIN
		-- Отмечаем услуги по которым расчёт по поставщику и типу фонда заблокирован
		UPDATE p1
		SET paym_blocked = ST.paym_blocked
		  , add_blocked = ST.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_types ST ON p1.sup_id_all = ST.sup_id
				AND ST.service_id = ''
		WHERE ST.tip_id = @tip_id1

		-- по конкретным услугам типа
		UPDATE p1
		SET paym_blocked = ST.paym_blocked
		  , add_blocked = ST.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_types ST ON p1.sup_id_all = ST.sup_id
				AND p1.service_id = ST.service_id
		WHERE ST.tip_id = @tip_id1

		-- Отмечаем услуги по которым расчёт по поставщику целиком
		UPDATE p1
		SET paym_blocked = sb.paym_blocked
		  , add_blocked = sb.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_build AS sb ON p1.sup_id_all = sb.sup_id
				AND sb.service_id = ''
		WHERE sb.build_id = @build_id1
		-- по конкретным услугам дома
		UPDATE p1
		SET paym_blocked = sb.paym_blocked
		  , add_blocked = sb.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_build AS sb ON p1.sup_id_all = sb.sup_id
				AND p1.service_id = sb.service_id
		WHERE sb.build_id = @build_id1

	--IF @Db_Name IN ('KVART','ARX_KVART')
	--	UPDATE p1
	--	SET  paym_blocked=1
	--	FROM @paym_list1 AS p1
	--	JOIN SUPPLIERS s ON p1.source_id=s.id 
	--	WHERE p1.sup_id=0
	--	AND p1.service_id IN ('гвод','гвсд','вотв','хвсд')
	--	AND @tip_id1=27
	--	AND s.sup_id=98 -- Водоканал

	END
	ELSE
	BEGIN
		UPDATE p1
		SET paym_blocked = ST.paym_blocked
		  , add_blocked = ST.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_types_history ST ON p1.sup_id_all = ST.sup_id
				AND ST.service_id = ''
		WHERE ST.tip_id = @tip_id1
			AND ST.fin_id = @fin_id1

		UPDATE p1
		SET paym_blocked = ST.paym_blocked
		  , add_blocked = ST.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_types_history ST ON p1.sup_id_all = ST.sup_id
				AND p1.service_id = ST.service_id
		WHERE ST.tip_id = @tip_id1
			AND ST.fin_id = @fin_id1

		-- по дому целиком
		UPDATE p1
		SET paym_blocked = sb.paym_blocked
		  , add_blocked = sb.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_build_history sb ON p1.sup_id_all = sb.sup_id
				AND sb.service_id = ''
		WHERE sb.build_id = @build_id1
			AND sb.fin_id = @fin_id1
		-- по дому по услугам
		UPDATE p1
		SET paym_blocked = sb.paym_blocked
		  , add_blocked = sb.add_blocked
		FROM @paym_list1 AS p1
			JOIN dbo.Suppliers_build_history sb ON p1.sup_id_all = sb.sup_id
				AND p1.service_id = sb.service_id
		WHERE sb.build_id = @build_id1
			AND sb.fin_id = @fin_id1
	END

	--
	UPDATE p1
	SET serv_counter =
					  CASE p1.service_id
						  WHEN N'хвс2' THEN N'хвод'
						  WHEN N'гвс2' THEN N'гвод'
						  WHEN N'гвс3' THEN N'гвод'
						  WHEN N'ото2' THEN N'отоп'
						  WHEN N'эле2' THEN N'элек'
						  --WHEN '' THEN ''
						  ELSE p1.service_id
					  END
	FROM @paym_list1 AS p1

	--IF @debug=1  select * from @paym_list1
	--IF @debug=1  select * from consmodes_list where occ=@occ1

	IF (@added <> 0)
		AND (@mode_history = 1)
	BEGIN
		-- берем режимы из истории
		INSERT INTO #services1 (id
							  , sup_id
							  , is_paym
							  , is_koef
							  , is_norma
							  , is_subsid
							  , mode_id
							  , source_id
							  , koef
							  , subsid_only
							  , unit_id
							  , is_counter
							  , tar
							  , extr_tar
							  , full_tar
							  , sort_no
							  , dog_int
							  , is_build
							  , sort_paym
							  , date_ras_start
							  , date_ras_end
							  , avg_vday
							  , tar_counter
							  , q_single
							  , q_member
							  , two_single
							  , three_single
							  , total_people_flats
							  , counter_metod_kol
							  , counter_metod
							  , counter_metod_service_kol
							  , occ_serv_kol)
		SELECT s.id
			 , cl.sup_id
			 , s.is_paym
			 , is_koef
			 , is_norma
			 , is_subsid
			 , cl.mode_id
			 , cl.source_id
			 , cl.koef
			 , subsid_only
			 , su.unit_id
			 , cl.is_counter
			 , 0 AS tarif
			 , 0 AS extr_tar
			 , 0 AS full_tar
			 , s.sort_no
			 , NULL AS dog_int
			 , s.is_build
			 , s.sort_paym
			 , @date_ras_start
			 , @date_ras_end
			 , 0 AS avg_vday
			 , 0 AS tar_counter
			 , 0 AS q_single
			 , 0 AS q_member
			 , 0 AS two_single
			 , 0 AS three_single
			 , 0 AS total_people_flats
			 , 0 AS counter_metod_kol
			 , NULL AS counter_metod
			 , '' AS counter_metod_service_kol
			 , cl.occ_serv_kol
		FROM dbo.Services AS s 
			JOIN dbo.Service_units AS su 
				ON s.id = su.service_id
			JOIN dbo.Consmodes_history AS cl
				ON s.id = cl.service_id
				AND su.fin_id = cl.fin_id
		WHERE cl.fin_id = @FinPeriod
			AND cl.occ = @occ1
			AND su.roomtype_id = @roomtype1
			AND su.tip_id = @tip_id1
			AND ((cl.mode_id % 1000) <> 0 OR (cl.source_id % 1000) <> 0)
			AND s.id = COALESCE(@serv_one1, s.id)
			AND s.is_paym = 1

		-- 20.11.2009    Если у режима есть своя еденица измерения обновляем
		UPDATE s
		SET unit_id = cm.unit_id
		FROM #services1 AS s
			JOIN dbo.Cons_modes_history AS cm ON s.mode_id = cm.mode_id
				AND s.id = cm.service_id
		WHERE cm.fin_id = @FinPeriod
			AND cm.unit_id IS NOT NULL

	END
	ELSE
	BEGIN

		-- берем текущие режимы
		INSERT INTO #services1 (id
							  , sup_id
							  , is_paym
							  , is_koef
							  , is_norma
							  , is_subsid
							  , mode_id
							  , source_id
							  , koef
							  , subsid_only
							  , unit_id
							  , is_counter
							  , tar
							  , extr_tar
							  , full_tar
							  , sort_no
							  , dog_int
							  , is_build
							  , sort_paym
							  , date_ras_start
							  , date_ras_end
							  , avg_vday
							  , tar_counter
							  , q_single
							  , q_member
							  , two_single
							  , three_single
							  , total_people_flats
							  , counter_metod_kol
							  , counter_metod
							  , counter_metod_service_kol
							  , occ_serv_kol)
		SELECT s.id
			 , cl.sup_id
			 , s.is_paym
			 , is_koef
			 , is_norma
			 , is_subsid
			 , cl.mode_id
			 , cl.source_id
			 , COALESCE(cl.koef, 1)
			 , subsid_only
			 , su.unit_id
			 , cl.is_counter
			 , 0 AS tarif
			 , 0 AS extr_tar
			 , 0 AS full_tar
			 , s.sort_no
			 , sup.dog_int
			 , s.is_build
			 , s.sort_paym
			 , CASE WHEN(@date_ras_start IS NULL OR cl.date_start > @date_ras_start) THEN cl.date_end ELSE @date_ras_start END
			 , CASE WHEN(@date_ras_end IS NULL OR cl.date_end < @date_ras_end) THEN cl.date_end ELSE @date_ras_end END
			 , 0 AS avg_vday
			 , 0 AS tar_counter
			 , 0 AS q_single
			 , 0 AS q_member
			 , 0 AS two_single
			 , 0 AS three_single
			 , 0 AS total_people_flats
			 , 0 AS counter_metod_kol
			 , NULL AS counter_metod
			 , '' AS counter_metod_service_kol
			 , cl.occ_serv_kol
		FROM dbo.Services AS s 
			JOIN #cl_temp AS cl ON s.id = cl.service_id
			JOIN dbo.Service_units AS su ON s.id = su.service_id
			LEFT JOIN @t_serv_sup AS sup ON s.id = sup.serv
				AND cl.sup_id = sup.sup_id
		WHERE cl.occ = @occ1
			AND su.roomtype_id = @roomtype1
			AND su.fin_id = @FinPeriod
			AND su.tip_id = @tip_id1
			AND ((cl.mode_id % 1000) <> 0 OR (cl.source_id % 1000) <> 0)
			AND s.id = COALESCE(@serv_one1, s.id)
			AND s.is_paym = 1

		-- 20.11.2009    Если у режима есть своя еденица измерения обновляем
		UPDATE s
		SET unit_id = cm.unit_id
		FROM #services1 AS s
			JOIN dbo.Cons_modes AS cm ON s.mode_id = cm.id
				AND s.id = cm.service_id
		WHERE cm.unit_id IS NOT NULL

	END

	--IF @debug=1 SELECT * FROM #services1 s

	-- включить с сентября 2021
	UPDATE s
	SET date_ras_start = dt.date_ras_start
	  , date_ras_end = dt.date_ras_end
	FROM #services1 AS s
		CROSS APPLY dbo.Fun_GetOccDataStartEnd(@occ1, @fin_id1, 1) AS dt
	WHERE s.id = dt.service_id

	-- обрабатываем даты по разовым
	IF @data1 IS NOT NULL
		AND @data2 IS NOT NULL
	BEGIN
		UPDATE s
		SET date_ras_start = CASE WHEN(@data1 < s.date_ras_start AND @data1 > @Start_date) THEN @data1 ELSE s.date_ras_start END
		  , date_ras_end = CASE WHEN(@data2 > s.date_ras_end AND @data2 < @End_date) THEN @data2 ELSE date_ras_end END
		FROM #services1 AS s
	END
	--IF @debug=1
	--	SELECT * FROM #services1 s WHERE id='площ'

	IF @use_koef_build = 1
		UPDATE s
		SET koef = kb.value  -- если берём коэф. из дома
		FROM #services1 AS s
			JOIN dbo.Koef_build kb ON s.id = kb.service_id
		WHERE kb.build_id = @build_id1
			AND @added <> 2
			AND kb.value IS NOT NULL


	--IF @debug=1 SELECT * FROM #services1 s
	--IF @fin_id1 = 160
	--	UPDATE s
	--	SET	date_ras_start	= '20150511'
	--		,date_ras_end	= '20150531 23:59'
	--	FROM #services1 AS s
	--	WHERE id IN ('хвпк', 'гвпк', 'вопк')

	UPDATE #services1
	SET tar = r.value
	  , extr_tar = r.extr_value
	  , full_tar = r.full_value
	FROM #services1 AS s
		JOIN dbo.Rates AS r 
			ON (s.id = r.service_id)
			AND (s.mode_id = r.mode_id)
			AND (s.source_id = r.source_id)
	WHERE (FinPeriod = @FinPeriod)
		AND (tipe_id = @tip_id1)
		AND (r.status_id = @status1)
		AND (r.proptype_id = @proptype1)

	UPDATE #services1
	SET tar_counter = r.tarif
	FROM #services1 AS s
		JOIN dbo.Rates_counter AS r ON (s.id = r.service_id)
			AND (s.mode_id = r.mode_id)
			AND (s.source_id = r.source_id)
			AND s.unit_id = r.unit_id
	WHERE (r.fin_id = @FinPeriod)
		AND (r.tipe_id = @tip_id1)

	-- если даже нет режимов пометка счетчика по уcлуге
	UPDATE p
	SET is_counter = t.is_counter
	FROM #cl_temp AS t
		JOIN @paym_list1 AS p ON t.service_id = p.service_id

	IF @payms_tip1 = 0
		AND @added1 = 0 -- 09/01/2013
		UPDATE #services1
		SET is_paym = 0

	--**********************************************************************************************
	----UPDATE #services1 SET avg_vday=dbo.Fun_GetAvgCounterValue(@occ1,id) WHERE is_counter>0
	--UPDATE s SET avg_vday=t.avg_vday
	--FROM #services1 s
	----CROSS APPLY dbo.Fun_GetAvgCounterValue(@occ1,s.id)
	--JOIN dbo.Fun_GetAvgCounterValueTable(@occ1,null) AS t ON s.id=t.service_id
	--WHERE is_counter>0

	UPDATE s
	SET avg_vday = COALESCE(cl.avg_vday, 0)
	FROM #services1 s
		JOIN dbo.Counter_list_all AS cl ON s.id = cl.service_id
	WHERE s.is_counter > 0
		AND cl.fin_id = @FinPeriod
		AND cl.occ = @occ1

	--**********************************************************************************************

	UPDATE s
	SET q_single = mu.q_single
	  , q_member = mu.q_member
	  , two_single = mu.two_single
	  , three_single = mu.three_single
	FROM #services1 s
		JOIN dbo.Measurement_units mu ON mu.unit_id = s.unit_id
			AND mu.mode_id = s.mode_id
			AND mu.is_counter = 0
			--AND mu.is_counter=(CASE WHEN s.is_counter>0 THEN 1 ELSE 0 END)
			AND mu.tip_id = @tip_id1
			AND mu.fin_id = @fin_id1

	-- Находим кол-во человек в квартире
	UPDATE s
	SET total_people_flats = (
		SELECT COUNT(P.id)
		FROM dbo.People P 
			JOIN dbo.Occupations O ON P.occ = O.occ
			JOIN dbo.Person_statuses AS ps ON P.status2_id = ps.id
			JOIN dbo.Person_calc AS pc ON ps.id = pc.status_id
		WHERE O.flat_id = @flat_id1
			AND ps.is_paym = 1
			AND pc.service_id = s.id
			AND pc.have_paym = 1
			AND (P.Del = 0 OR (P.DateDel >= @Start_date))
	)
	FROM #services1 s
	WHERE s.is_counter > 0

	UPDATE s
	SET counter_metod = CASE WHEN(COALESCE(st.counter_metod,-1) = -1) THEN 2 ELSE st.counter_metod END
	  , counter_metod_kol = st.kol
	  , counter_metod_service_kol = st.service_kol
	  , pkoef_rasch_dpoverka = COALESCE(st.pkoef_rasch_dpoverka, -999)
	  , koef = CASE WHEN(st.koef = 0) THEN 1 ELSE st.koef END
	  , is_counter_add_balance = CASE WHEN(@is_counter_add_balance = 1) THEN 1 ELSE st.is_counter_add_balance END
	FROM #services1 s
		JOIN dbo.Services_type_counters AS st ON st.tip_id = @tip_id1
			AND s.id = st.service_id

	UPDATE s
	SET counter_metod = CASE WHEN(COALESCE(sb.counter_metod,-1) = -1) THEN 2 ELSE sb.counter_metod END
	FROM #services1 s
		JOIN dbo.Services_build AS sb ON s.id = sb.service_id
	WHERE sb.build_id = @build_id1
		AND s.is_counter > 0

	--UPDATE s
	--SET	pkoef_rasch_dpoverka = (select COALESCE(st.pkoef_rasch_dpoverka,-999)
	--							FROM dbo.SERVICES_TYPE_COUNTERS AS st
	--							WHERE st.tip_id = @tip_id1
	--								AND st.service_id='хвод')
	--FROM #services1 s
	--WHERE id IN ('хвпк')

	--if @debug=1 select * from @paym_list1
	--if @debug=1 select * from #services1
	--if @debug=1 SELECT *  FROM #people2

	-- кол-во лицевых в квартире
	SELECT @CountOccFlats = COUNT(occ)
	FROM dbo.Occupations AS O
	WHERE O.flat_id = @flat_id1
		AND status_id <> 'закр'
		AND O.total_sq <> 0 -- 14.12.2015

	--***************************************************************
	-- Находим долю общедомовой площади приходящейся на лицевой счёт
	SELECT @Total_Sq_build = SUM(total_sq)
	FROM dbo.Occupations O 
		JOIN dbo.Flats F 
			ON F.id = O.flat_id
	WHERE F.bldn_id = @build_id1
		AND O.status_id <> 'закр'
	OPTION(RECOMPILE)

	--PRINT @Total_Sq_build
	--PRINT @Build_total_sq_old

	IF @Total_Sq_build > 0
		AND @Build_opu_sq > 0
		SELECT @occ_opu_sq = @Build_opu_sq * @Total_Sq1 / (@Total_Sq_build + @Build_arenda_sq)
	ELSE
		SELECT @occ_opu_sq = 0

	-- Вычисляем общую площадь дома для расчета СОИ (ОДН)
	SELECT @Build_total_area_soi = CASE 
			WHEN(@soi_isTotalSq_Pasport = 1 AND @Build_total_area>0)
			THEN @Build_total_area ELSE @Total_Sq_build + @Build_arenda_sq 
		END
	--***************************************************************

	IF @Build_total_sq_old <> @Total_Sq_build
		UPDATE dbo.Buildings 
		SET build_total_sq = @Total_Sq_build
		WHERE id = @build_id1

	UPDATE p2
	SET tarif =
			   CASE is_rates
				   WHEN 1 THEN s.tar
				   WHEN 2 THEN s.extr_tar
				   WHEN 3 THEN s.full_tar
				   ELSE s.tar
			   END
	FROM #people2 AS p2
		JOIN #services1 s ON p2.service_id = s.id

	-- Соединяем с таблицей по дому
	UPDATE s
	SET s.tar = CASE WHEN(bn.tarif > 0) THEN bn.tarif ELSE s.tar END
	  , s.occ_serv_kol = CASE WHEN(bn.kol > 0) THEN bn.kol ELSE s.occ_serv_kol END
	  , s.q_single = CASE WHEN(bn.kol_norma > 0) THEN bn.kol_norma ELSE s.q_single END
	FROM #services1 s
		JOIN dbo.Build_occ_norma bn ON s.id = bn.service_id
	WHERE bn.occ = @occ1
		AND bn.build_id = @build_id1;

	-- устанавливаем кол-во месяцев прошедших от последних показаний
	UPDATE s
	SET s.count_last_month_counter_value=coalesce(tt.last_month,99)
	FROM #services1 s
	LEFT JOIN (SELECT t.service_id, t.last_month FROM (
			SELECT service_id, 
				@fin_id1-fin_id AS last_month, 
				ROW_NUMBER() OVER (PARTITION BY service_id ORDER BY fin_id DESC) AS row_num
			FROM dbo.View_counter_inspector_lite 
			WHERE occ = @occ1 and tip_value=1
			GROUP BY service_id, fin_id
			) as t
			WHERE t.row_num=1) as tt ON s.id=tt.service_id
	WHERE s.is_counter>0

	-- если мало показаний для расчета по среднему ставим 55 чтобы не считать по среднему 11.09.23
	UPDATE s
	SET s.count_last_month_counter_value=55
	FROM #services1 s	
	WHERE s.is_counter>0
	and s.id in ('хвод','гвод','элек')
	and EXISTS(
		SELECT count(cla.counter_id) 
		  from Counter_list_all as cla 
			  JOIN Counter_inspector as ci ON ci.counter_id = cla.counter_id AND ci.fin_id = cla.fin_id
			  JOIN counters as c ON cla.counter_id=c.id 
		  WHERE cla.occ=@occ1 
		  and cla.service_id=s.id
		  AND c.date_del is NULL
		  GROUP BY cla.counter_id
		  HAVING count(cla.counter_id)<IIF(@count_min_month_for_avg_counter=0,-999,@count_min_month_for_avg_counter)
	)

	-- летний период по Отоплению ==================================================
	SELECT 
		@is_summer_period=1
	FROM Global_values as gv
	WHERE 
		gv.fin_id=@fin_id1
		and gv.start_date BETWEEN gv.heat_summer_start AND gv.heat_summer_end

	UPDATE s
	SET s.tar=0, s.tar_counter=0
	, s.count_last_month_counter_value=CASE 
		WHEN (s.count_last_month_counter_value - (DATEDIFF(MONTH,gv.heat_summer_start,gv.heat_summer_end)+1) ) < 0 THEN 0
		ELSE (s.count_last_month_counter_value - (DATEDIFF(MONTH,gv.heat_summer_start,gv.heat_summer_end)+1) )
	END
	FROM #services1 s
		,Global_values as gv
	WHERE gv.fin_id=@fin_id1
		and s.id='отоп'
		and s.date_ras_start BETWEEN gv.heat_summer_start AND gv.heat_summer_end
	
	--IF @debug=1 SELECT @is_summer_period as is_summer_period, * FROM #services1 WHERE id='отоп'
	--================================================================================

	--IF @debug=1 SELECT * FROM #services1 
	--IF @debug=1 SELECT * FROM @paym_list1 --WHERE paym_blocked=1
	--IF @debug=1 SELECT * FROM paym_list where occ=@occ1
	--IF @debug=1 SELECT * FROM #people2 p
	--IF @debug=1 SELECT @Penalty_old_edit AS Penalty_old_edit
	--*******************************************************************************

	DECLARE Cur_services CURSOR LOCAL FOR
		SELECT id
			 , is_koef
			 , is_norma
			 , is_subsid
			 , mode_id
			 , source_id
			 , koef
			 , subsid_only
			 , unit_id
			 , is_counter
			 , coalesce(tar,0) as tar
			 , coalesce(extr_tar,0) as extr_tar
			 , coalesce(full_tar,0) as full_tar
			 , sup_id
			 , dog_int
			 , is_build
			 , date_ras_start
			 , date_ras_end
			 , avg_vday
			 , tar_counter
			 , s.q_single
			 , s.q_member
			 , s.two_single
			 , s.three_single
			 , s.total_people_flats
			 , counter_metod
			 , counter_metod_kol
			 , counter_metod_service_kol
			 , pkoef_rasch_dpoverka
			 , occ_serv_kol
			 , count_last_month_counter_value
		FROM #services1 AS s
		WHERE s.is_paym = CAST(1 AS BIT)
			AND (s.mode_id % 1000) <> 0
			AND (s.source_id % 1000) <> 0
		ORDER BY sort_paym --, sort_no

	OPEN Cur_services
	FETCH NEXT FROM Cur_services
	INTO @serv1, @is_koef1, @is_norma1, @is_subs1, @mode1, @source1, @koef1, @subsid_only1,
	@serv_unit1, @is_counter1, @tar1, @extr_tar, @full_tar, @sup_id, @dog_int, @serv_is_build, @date_ras_start,
	@date_ras_end, @avg_vday, @tar_counter1, @NormaSingle, @NormaMember, @NormaTwoSingle, @NormaThreeSingle, @Total_people_flats,
	@counter_metod, @counter_metod_kol, @counter_metod_service_kol, @pkoef_rasch_dpoverka, @occ_serv_kol, @count_last_month_counter_value

	WHILE @@fetch_status = 0
	BEGIN
		--if @debug=1 PRINT @serv1+'  ед.изм:'+@serv_unit1+' тариф:'+str(@tar1,9,2) 
		--SET @NormaSingle=NULL 
		SET @kolDayRas = DATEDIFF(DAY, @date_ras_start, @date_ras_end) + 1
		IF @kolDayRas < 0
			SET @kolDayRas = 0
		IF @kolDayRas < @KolDayFinPeriod
			SET @koefDayRas = CAST(@kolDayRas AS DECIMAL(10, 4)) / @KolDayFinPeriod
		ELSE
			SET @koefDayRas = 1

		UPDATE #people2
		SET koefday = @koefDayRas
		WHERE service_id = @serv1
			AND koefday > @koefDayRas

		--IF @debug=1 PRINT @serv1+' '+CONVERT(VARCHAR(15),@date_ras_start,103)+' '+CONVERT(VARCHAR(15),@date_ras_end,103)+
		--	' '+STR(@kolDayRas)+' '+STR(@koefDayRas,9,4)

		-- метод расчёта по счётчикам по услугам
		-- нач.знач. иначе от предыдущего остаётся
		--SELECT @counter_metod_kol=NULL, @counter_metod=NULL, @counter_metod_service_kol=NULL

		--SELECT @counter_metod=counter_metod,
		--	@counter_metod_kol=kol,
		--	@counter_metod_service_kol=service_kol
		--FROM dbo.SERVICES_TYPE_COUNTERS
		--WHERE tip_id=@tip_id1 AND service_id=@serv1

		IF @counter_metod IS NULL
			SET @counter_metod = @counter_metod_global
		IF @counter_metod = -1 -- расчёт по умолчанию
			SET @counter_metod = 2 -- ставим по среднему

		--IF @debug = 1 PRINT @serv1 + '   ' + STR(@counter_metod) +' '+str(@counter_metod_global)

		IF @is_counter_add_balance = 1
			SELECT @kol_saldo = pob.kol_balance
			FROM dbo.Paym_occ_balance AS pob 
			WHERE pob.fin_id = @FinPred
				AND pob.occ = @occ1
				AND pob.service_id = @serv1
				AND pob.sup_id = @sup_id
		ELSE
			SET @kol_saldo = 0

		--select @added1=sum(value) from added_payments where occ=@occ1 and service_id=@serv1
		--select @serv1, @added1

		SELECT @value1 = 0
			 , @discount1 = 0
			 , @kol = 0
			 , @koef1 = CASE
							WHEN @is_koef1 = 0 THEN 1 -- Если не используем коэф.
							WHEN (@koef1 = 0 OR @koef1 IS NULL) THEN 1
							ELSE @koef1
						END
		--,@Total_people_flats = 0

		-- Проверяем ед. измерения услуги
		--select @serv_unit1=unit_id  from service_units as s where s.service_id=@serv1 and roomtype_id=@roomtype1
		-- *************************************************************

		--UPDATE @paym_list1  SET serv_unit=@serv_unit1 WHERE occ=@occ1 AND service_id=@serv1	and serv_unit<>@serv_unit1

		-- *************************************************************
		--SELECT @serv1,@is_counter1,@roomtype1

		--IF @debug=1 PRINT @serv1+' '+STR(@Total_people_flats)
		SELECT @Total_people1 = COALESCE(SUM(CASE WHEN(is_paym = 1) THEN 1 ELSE 0 END), 0)
			 , @Total_people_ee1 = COUNT(*)
		FROM #people2
		WHERE service_id = @serv1

		-- Когда прописан один человек
		-- берем тариф согласно статусу прописки
		IF @serv_unit1 = N'люди' and  @Total_people1 = 1
			SELECT @tar1 = tarif
			FROM #people2
			WHERE service_id = @serv1

		-- *************************************************************
		--SELECT @PeopleSocNorma=COUNT(*) FROM #people2 WHERE service_id=@serv1 AND is_norma=1 
		--SELECT @PeopleSocNormaAll=COUNT(*) FROM #people2 WHERE service_id=@serv1 AND is_norma_all=1
		--SELECT @PeopleSocNormaOwn=COUNT(*) FROM #people2 WHERE service_id=@serv1 AND is_lgota=1 --and is_norma=1 --9/11/2007

		--SELECT @PeopleSubsid=COUNT(*) FROM #people2 WHERE service_id=@serv1 AND is_subs=1
		--SELECT @PeopleSubsidNorma=COUNT(*) FROM #people2 WHERE service_id=@serv1 AND is_norma_sub=1


		SELECT @PeopleSocNorma = SUM(CASE
				   WHEN is_norma = 1 THEN 1
				   ELSE 0
			   END)
			 , @PeopleSocNormaAll = SUM(CASE
				   WHEN is_norma_all = 1 THEN 1
				   ELSE 0
			   END)
			 , @PeopleSocNormaOwn = SUM(CASE
				   WHEN is_lgota = 1 THEN 1
				   ELSE 0
			   END)
		FROM #people2
		WHERE service_id = @serv1

		-- *************************************************************
		SELECT @PeopleNetSocNorma = @Total_people1 - @PeopleSocNorma
		--if @serv1='отоп' select  @Total_people1, @PeopleSocNorma, @PeopleNetSocNorma
		-- *************************************************************
		--SELECT @KolLgotServ=COUNT(Lgota_id) FROM #people2 WHERE service_id=@serv1 
		--AND is_lgota=1 AND Lgota_id>0 --and is_paym=1
		-- *************************************************************
		--SELECT @KolNotLgotServ=COUNT(Lgota_id) FROM #people2 WHERE service_id=@serv1 AND Lgota_id=0 -- and is_lgota=1

		SELECT @Build_total_serv_soi = @Build_total_area_soi

		/*****************************************************************
		                                    РАСЧЕТ
		*****************************************************************
		    ед. изм. Площадь
		*****************************************************************/
		IF @serv_unit1 IN (N'оквм', N'жквм', N'ггкл', N'плот', N'гкоп')
		BEGIN
			IF @koefDayRas = 0 -- значит в этом периоде не начисляем по услуге
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			IF @added = 2
			BEGIN-- Определяем тариф для разовых по площади 
				--SET @tar1 =
				--	CASE
				--		WHEN @serv1 IN (N'отоп', N'ото2') THEN ROUND((@tar1 * (@AddOtpProcent1 * 0.01) * @koefDayRas), 4)
				--		--ELSE ROUND((@tar1 * @koefDayRas), 4)
				--		ELSE @tar1
				--	END

				IF (@serv1 IN (N'отоп', N'ото2'))
					AND (@tnorm1 > @tnorm2)
					AND (@tnorm2 > 0)
				BEGIN
					--  print '1 отоп'+str(@tar1,8,4)
					SET @tar1 = ROUND(@tar1 * @tnorm2 / @tnorm1, 4)
				--  print '2 отоп'+str(@tar1,8,4)
				END
			END -- @added=2

			--SELECT @NormaSingle=q_single,
			--  @NormaMember=q_member,
			--  @NormaTwoSingle=two_single,
			--  @NormaThreeSingle=three_single
			--FROM dbo.measurement_units 
			--WHERE unit_id=@serv_unit1 
			--AND  mode_id=@mode1
			--AND is_counter=0
			--AND tip_id=@tip_id1
			--AND fin_id=@fin_id1

			-- *************************************************************
			--IF @debug=1 select @serv1,@NormaSingle , @serv_unit1, @tip_id1, @fin_id1
			-- ед. изм. Площадь 
			SELECT @Square = @Total_Sq1
			IF @serv_unit1 = 'плот'
				SELECT @Square = @Teplo_Sq1
			ELSE
			IF @serv_unit1 = 'жквм'
				SELECT @Square = @Living_Sq1
			ELSE			
			IF @serv_unit1 = 'гкоп'  -- Гигакалории от отап.площади
				SELECT @Square = @Teplo_Sq1

			--IF @serv_unit1='оквм'  
			--BEGIN
			--  IF @serv1='отоп' 
			--    SELECT @Square=@Teplo_Sq1
			--  ELSE
			--    SELECT @Square=@Total_Sq1
			--END

			--IF @serv_unit1='жквм'  
			--BEGIN
			--  IF @serv1='отоп' 
			--    SELECT @Square=@Teplo_Sq1
			--  ELSE
			--    SELECT @Square=@Living_Sq1
			--END

			IF @total_sq_new > 0
				SET @Square = @total_sq_new

			-- *************************************************************

			-- Находим площадь по соц. норме
			SELECT @SquareNorma =
								 CASE @PeopleSocNorma
									 WHEN 0 THEN 0
									 WHEN 1 THEN @NormaSingle
									 WHEN 2 THEN (@NormaTwoSingle * @PeopleSocNorma)
									 ELSE (@NormaMember * @PeopleSocNorma)
								 END

			-- Находим площадь по соц. норме на одного
			SELECT @Sown =
						  CASE @PeopleSocNorma
							  WHEN 0 THEN 0
							  WHEN 1 THEN @NormaSingle
							  WHEN 2 THEN @NormaTwoSingle
							  ELSE @NormaMember
						  END

			-- Корректируем нормы для льготы когда проживающих людей больше
			IF @PeopleSocNorma = 1
				AND @PeopleSocNormaAll = 2
			BEGIN
				SET @SquareNorma = @NormaTwoSingle * @PeopleSocNorma
				SET @Sown = @NormaTwoSingle
			END

			IF @PeopleSocNorma <= 2
				AND @PeopleSocNormaAll > 2
			BEGIN
				SET @SquareNorma = @NormaMember * @PeopleSocNorma
				SET @Sown = @NormaMember
			END

			IF @PeopleSocNormaOwn = 0
				SELECT @Sdola = @Sown
			ELSE
				SELECT @Sdola = @Total_Sq1 / @PeopleSocNormaOwn

			-- Нормы не должна быть больше Общей площади
			IF @SquareNorma > @Square
			BEGIN
				SELECT @SquareNorma = @Square
			END
			IF @Sown > @SquareNorma
				SELECT @Sown = @SquareNorma
			IF @Sdola > @Square
				SELECT @Sdola = @Square


			--print str(@Sown,8,2)+' '+ str(@SquareNorma,8,2)+' '+ str(@Sdola,8,2)
			-- *************************************************************

			--****************************************************************
			IF @serv_unit1 IN (N'ггкл', N'гкоп')
			BEGIN
				IF (@serv1 = N'отоп')
					AND COALESCE(@NormaSingle, 0) = 0
					SET @kol = @Square * @norma_gkal
				ELSE
					SET @kol = @Square * @NormaSingle

				--IF @debug=1 SELECT @serv1, @tar1 as tar, @kol AS kol, @NormaSingle as NormaSingle, @Square as [Square]
				--SET @NormaSingle = NULL		
				--ELSE
				--BEGIN
				--	IF @counter_metod=5 and @counter_metod_service_kol<>''
				--	BEGIN
				--		IF @counter_metod_kol>0 
				--			SET @kol=@counter_metod_kol
				--		ELSE
				--			SELECT @kol=kol FROM @paym_list1 pl WHERE pl.occ=@occ1 AND pl.service_id=@counter_metod_service_kol
				--		--IF @debug=1 PRINT STR(@counter_metod)+' '+@serv1+' '+STR(@kol,9,4)
				--	END

				--	IF @norma_gkal_gvs>0
				--		SELECT @NormaSingle=@norma_gkal_gvs
				--	ELSE
				--		SELECT @NormaSingle=dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 0, @tip_id1, @fin_id1)

				--	SELECT @kol=@kol*@NormaSingle
				--END
				IF @occ_serv_kol > 0 -- если задан объем по услуге
					SELECT @kol = @occ_serv_kol, @counter_metod=8

				SET @kol = @koefDayRas * @kol  --25.02.2021
				SELECT @value1 = @tar1 * @kol

				--IF @debug=1 SELECT @serv1, @tar1 as tar, @kol AS kol, @norma_gkal AS norma_gkal,@NormaSingle as NormaSingle, @is_counter1 AS is_counter, @counter_metod as counter_metod, @value1 AS value
				-- ************************************************************************
				IF @is_counter1 = 2 -- внутренний счетчик   
				BEGIN
					--IF @debug=1 print 'внутренний счетчик по услуге: '+@serv1

					SELECT TOP (1) @serv_unit1 = cl.unit_id
							   , @counter_id1 = counter_id
					FROM #t_counter AS cl
					WHERE cl.internal = 1
						AND cl.service_id = @serv1

					IF @counter_metod IN (2, 9) -- начисляем по среднему по счетчикам
						AND (@count_last_month_counter_value<=3 OR @counter_metod=9)
						--AND EXISTS (
						--	SELECT 1
						--	FROM dbo.View_counter_inspector_lite 
						--	WHERE occ = @occ1
						--		AND service_id = @serv1
						--		AND tip_value = 1
						--		AND @fin_id1 - fin_id <= 3
						--)	-- 3 месяца
					BEGIN
						-- получить тариф по счетчику
						--IF @tar_counter1 = 0  -- 18/05/23 зачем заново искать тариф?
						--	SELECT @tar1 = dbo.Fun_GetCounterTarf(@fin_id1, @counter_id1, NULL)
						--ELSE
						--	SELECT @tar1 = @tar_counter1
						IF @tar_counter1 <> 0
							SELECT @tar1 = @tar_counter1

						-- вычисляем сумму средних значений счётчиков			
						--select @avg_vday=dbo.Fun_GetAvgCounterValue(@occ1,@serv1)
						--PRINT @serv1

						SELECT @kol = @KolDayFinPeriod * @avg_vday

						SELECT @value1 = @tar1 * @kol

					--IF @kol=0 SET @counter_metod=1
					END
					ELSE
					IF @counter_metod NOT IN (0, 5, 6)
						SET @counter_metod = 1

					IF @counter_metod IN (1, 6)  -- начисляем по норме по счетчикам
					BEGIN
						--SET @NormaSingle=NULL
						-- получить норму на человека по счетчику	
						IF COALESCE(@NormaSingle, 0) = 0
							SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 1, @tip_id1, @fin_id1)

						IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
						BEGIN
							SET @value1 = 0

							SELECT @kol = SUM(@NormaSingle * koefday)
							FROM #people2
							WHERE service_id = @serv1
								AND is_paym = 1
							--print @Kol

							SELECT @value1 = @value1 + @tar1 * @NormaSingle * koefday
							FROM #people2
							WHERE service_id = @serv1
								AND is_paym = 1

						--print str(@value1)+' '+str(@NormaSingle)+ '  '+str(@mode1)
						END --else print str(@occ1)+' не найдена норма по счетчику '+@serv1		

						IF @counter_metod_kol > 0
						BEGIN
							SELECT @kol = @counter_metod_kol
							SELECT @value1 = @tar1 * @kol
						END

					END  -- IF @counter_metod=1  -- начисляем по норме по счетчикам

					-- расчет по внутр.счетчику если нет показаний
					IF @counter_metod = 0	-- если не считать 
					BEGIN
						SELECT @kol = 0
							 , @value1 = 0
					END
				END
			--if @debug=1 and @serv1='отоп' select  @value1 as value, @tar1 as tar, @Square as [Square], @kol as kol, @counter_metod as counter_metod, @NormaSingle, @Square
			END
			ELSE
			BEGIN
				-- расчет по тарифу 
				IF @occ_serv_kol > 0
					SELECT @kol = @occ_serv_kol, @counter_metod=8
				ELSE
					SELECT @kol = @Square
				SELECT @value1 = @tar1 * @kol
			--if @debug=1 AND @serv1='лифт' select  @value1, @tar1, @Square
			END

			IF @is_koef1 = 1
			BEGIN
				SELECT @value1 = @value1 * @koef1
			END

			IF (@serv1 in ('капр', 'Крем')
				AND @old_house = 1)  -- если ветхий дом то не начисляем
			BEGIN
				SET @value1 = 0
				SET @kol = 0
				SET @discount1 = 0
				SET @added1 = 0
			END


			IF @kolDayRas < @KolDayFinPeriod
				--AND @added = 0  -- 16.09.2021
				AND @serv_unit1 NOT IN (N'ггкл', N'гкоп') -- там уменьшили уже кол-во 26.08.2021
			BEGIN
				SELECT @value1 = @value1 / @KolDayFinPeriod * @kolDayRas
			END

			--IF @debug=1 PRINT @serv1+' '+str(@KolDayFinPeriod)+'  '+str(@kolDayRas)+'  '+str(@value1,9,2)  
			--IF @debug=1 print @serv1 + '  '+ str(@tar1,9,2)+ '  '+ str(@Square,9,2)+ '  '+ str(@value1,9,2)

			GOTO WriteResult
		END
		/*****************************************************************
		   ед. изм. Люди
		*****************************************************************/
		IF @serv_unit1 = N'люди'
		BEGIN
			--select * from #people2
			IF @payms_tip1 = 0 -- если не начисляем по данному жилому фонду
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			-- Определяем тариф для перерасчета по горячей воде
			IF (@serv1 IN (N'гвод', N'гвс2', N'гвсд'))
				AND (@added = 2)
			BEGIN
				SET @tar1 = ROUND(@tar1 * (@AddGvrProcent1 * 0.01), 2)
				IF (@serv1 IN (N'гвод', N'гвс2', N'гвсд'))
					AND (@tnorm1 > @tnorm2)
					AND (@tnorm2 > 0)
				BEGIN
					SET @tar1 = ROUND(@tar1 * @tnorm2 / @tnorm1, 2)
				--      print '2 гвод '+str(@tar1,8,4)
				END

			END

			IF @is_koef1 = 1
			BEGIN
				SELECT @value1 = @value1 + @tar1 * koefday * @koef1
				FROM #people2
				WHERE service_id = @serv1
					AND is_paym = 1
			END
			ELSE
			BEGIN
				SELECT @value1 = @value1 + @tar1 * koefday
				FROM #people2
				WHERE service_id = @serv1
					AND is_paym = 1
			END

			SELECT @kol = SUM(1 * koefday)
			FROM #people2
			WHERE service_id = @serv1
				AND is_paym = 1

			-- проверяем есть ли одновременно внутренние и внешние счетчики
			IF EXISTS (
					SELECT COUNT(*)
					FROM (
						SELECT internal
							 , COUNT(counter_id) AS p2
						FROM #t_counter AS tc
						WHERE service_id = @serv1
						GROUP BY internal
					) AS p
					HAVING COUNT(*) > 1
				)
			BEGIN
				RAISERROR (N'Есть внешние и внутренние счетчики по услуге: %s одновременно! Лицевой: %u', 16, 1, @serv1, @occ1)
			END

			-- ************************************************************************
			IF @is_counter1 = 2 -- внутренний счетчик   
			BEGIN
				--print 'внутренний счетчик по услуге: '+@serv1

				SELECT TOP 1 @serv_unit1 = cl.unit_id     -- получаем ед.измерения
						   , @counter_id1 = counter_id
				FROM #t_counter AS cl
				WHERE cl.internal = 1
					AND cl.service_id = @serv1

				-- получить тариф по счетчику
				--IF @tar_counter1 = 0
				--	SELECT @tar1 = dbo.Fun_GetCounterTarf(@fin_id1, @counter_id1, NULL)
				--ELSE
				--	SELECT @tar1 = @tar_counter1
				IF @tar_counter1 <> 0
					SELECT @tar1 = @tar_counter1

				IF @counter_metod IN (2, 9) -- начисляем по среднему по счетчикам
					AND (@count_last_month_counter_value<=3 OR @counter_metod=9)
					--AND EXISTS (
					--	SELECT 1
					--	FROM dbo.View_counter_inspector_lite
					--	WHERE occ = @occ1
					--		AND service_id = @serv1
					--		AND tip_value = 1
					--)
				BEGIN
					-- вычисляем сумму средних значений счётчиков
					--select @avg_vday=dbo.Fun_GetAvgCounterValue(@occ1,@serv1)
					--PRINT @serv1

					SELECT @kol = @KolDayFinPeriod * @avg_vday

					SELECT @value1 = @tar1 * @kol

				--IF @kol=0 SET @counter_metod=1
				END
				IF @counter_metod = 1  -- начисляем по норме по счетчикам
				BEGIN

					--SET @NormaSingle=NULL
					-- получить норму на человека по счетчику
					IF COALESCE(@NormaSingle, 0) = 0
						SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 1, @tip_id1, @fin_id1)

					IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
					BEGIN
						SET @value1 = 0

						SELECT @kol = SUM(@NormaSingle * koefday)
						FROM #people2
						WHERE service_id = @serv1
							AND is_paym = 1
						--print @Kol

						SELECT @value1 = @value1 + @tar1 * @NormaSingle * koefday
						FROM #people2
						WHERE service_id = @serv1
							AND is_paym = 1

					--print str(@value1)+' '+str(@NormaSingle)+ '  '+str(@mode1)
					END --else print str(@occ1)+' не найдена норма по счетчику '+@serv1		

					IF @counter_metod_kol > 0
					BEGIN
						SELECT @kol = @counter_metod_kol
						SELECT @value1 = @tar1 * @kol
					END

				END  -- IF @counter_metod=1  -- начисляем по норме по счетчикам

				-- расчет по внутр.счетчику если нет показаний
				IF @counter_metod = 0	-- если не считать 
				BEGIN
					SELECT @kol = 0
						 , @value1 = 0
				END
			END

			--************************************************************
			-- IF @debug=1
			-- begin
			--if (@serv1='хвод') print str(@kol,15,2)+' '+str(@value1,15,2) +' ' +STR(@NormaSingle,9,4)+' '+STR(@tar1,9,4)
			--if (@serv1='хвод') select * from #people2 where service_id='хвод'
			-- end

			GOTO WriteResult
		END

		/*****************************************************************
		   ед. изм.  "кубм"
		*****************************************************************/
		IF (@serv_unit1 = 'кубм')
		BEGIN
			--if @debug=1 PRINT @serv1

			IF @payms_tip1 = 0 -- если не начисляем по данному жилому фонду
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			-- IF @raschet_agri=0 AND @serv1='хвод'
			-- BEGIN
			--   UPDATE ao 
			--SET value=0
			--FROM dbo.AGRICULTURE_OCC AS ao
			--WHERE fin_id=@fin_id1 AND occ=@occ1
			-- END

			IF @raschet_agri = 1
				AND @serv1 = 'хвод'
				AND @is_counter1 <> 2
			BEGIN

				UPDATE ao
				SET kol = COALESCE((
						SELECT SUM(koefday)
						FROM #people2
						WHERE service_id = @serv1
							AND is_paym = 1
					), 0)
				  , kol_day = @KolDayFinPeriod
				FROM dbo.Agriculture_Occ AS ao
					JOIN dbo.Agriculture_Vid av 
						ON av.id = ao.ani_vid
				WHERE fin_id = @fin_id1
					AND occ = @occ1
					AND av.is_people = 1

				UPDATE ao
				SET value = kol *
								 CASE
									 WHEN kol_day = @KolDayFinPeriod THEN 1
									 ELSE (CAST(kol_day AS DECIMAL(8, 4)) / @KolDayFinPeriod)
								 END * av.kol_norma * @tar1
				FROM dbo.Agriculture_Occ AS ao
					JOIN dbo.Agriculture_Vid av 
						ON av.id = ao.ani_vid
				WHERE fin_id = @fin_id1
					AND occ = @occ1

				SELECT @value_agri = SUM(value)
					 , @kol_agri = SUM(kol * kol_norma)
				FROM dbo.Agriculture_Occ AS ao 
					JOIN dbo.Agriculture_Vid av 
						ON av.id = ao.ani_vid
				WHERE fin_id = @fin_id1
					AND occ = @occ1
			END

			--SET @NormaSingle = NULL
			--SELECT @NormaSingle=dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 0, @tip_id1, @fin_id1)
			--IF @debug=1 PRINT STR(@NormaSingle,8,4) 

			IF COALESCE(@NormaSingle, 0) = 0
				-- получить норму на человека по счетчику	
				SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 1, @tip_id1, @fin_id1)

			--IF @debug=1 SELECT @serv1,@mode1,@NormaSingle,@pkoef_rasch_dpoverka

			--Если есть счётчики по смежным услугам то не считаем
			IF @serv1 IN (N'хвпк', N'хпк2')
				IF
					EXISTS (
						SELECT 1
						FROM dbo.Counter_list_all cla 
						--JOIN dbo.Counters AS c ON cla.counter_id=c.id
						WHERE fin_id = @fin_id1
							AND occ = @occ1
							AND cla.service_id = N'хвод'
							--AND c.date_del IS NULL
							AND (CASE
								WHEN 1 = 1 THEN KolmesForPeriodCheck
								ELSE 0
							END) >= @pkoef_rasch_dpoverka ---3  @pkoef_rasch_dpoverka дата поверки истекла не более 3 мес назад
					)
					--AND EXISTS (SELECT
					--			1
					--		FROM dbo.View_counter_inspector_lite 
					--		WHERE occ = @occ1
					--		AND service_id = 'хвод'
					--		AND tip_value = 1
					--		AND @fin_id1 - fin_id <= 6)  -- не подаёт показания 6 мес
					SELECT @NormaSingle = 0

			IF @serv1 IN (N'гвпк')
				IF EXISTS (
						SELECT 1
						FROM dbo.Counter_list_all cla
						--JOIN dbo.Counters AS c ON cla.counter_id=c.id
						WHERE fin_id = @fin_id1
							AND occ = @occ1
							AND cla.service_id = N'гвод'
							--AND c.date_del IS NULL
							AND (CASE
								WHEN 1 = 1 THEN KolmesForPeriodCheck
								ELSE 0
							END) >= @pkoef_rasch_dpoverka ---3  @pkoef_rasch_dpoverka дата поверки истекла не более 3 мес назад
					)
					SELECT @NormaSingle = 0

			IF @serv1 IN (N'хвпк', N'хпк2', N'гвпк', N'вопк', N'впк2')
				IF @NormaSingle > 0
					AND @KolDayFinPeriod <> @kolDayRas --AND @added<>2
				BEGIN
					SELECT @NormaSingle = CAST((@NormaSingle / @KolDayFinPeriod * @kolDayRas) AS DECIMAL(9, 4))
				END

			--IF @debug=1 SELECT @serv1,@mode1,@NormaSingle AS NormaSingle,@pkoef_rasch_dpoverka AS pkoef_rasch_dpoverka

			SET @NormaSingleTmp = @NormaSingle;

			IF @serv_is_build = 1
			BEGIN
				--IF @debug=1 PRINT STR(@NormaSingle,8,4) + ' ' +STR(@occ_opu_sq,8,4)
				SELECT @NormaSingleTmp = @NormaSingle * @occ_opu_sq
			END

			IF COALESCE(@NormaSingleTmp, 0) > 0 -- норма заполнена
			BEGIN
				SET @value1 = 0

				SELECT @kol = SUM(@NormaSingleTmp * koefday * @koef1)
				FROM #people2
				WHERE service_id = @serv1
					AND is_paym = 1
				--SELECT @Kol=@kol+@kol_saldo
				--if @debug=1 --select @serv1,@Kol
				--SELECT * FROM #people2 WHERE service_id='гвод' AND is_paym=1

				IF @serv_is_build = 1
				BEGIN -- общедомовая услуга
					SELECT @kol = @NormaSingleTmp
					SELECT @value1 = @tar1 * @NormaSingleTmp

					IF @kolDayRas < @KolDayFinPeriod
					BEGIN
						SELECT @value1 = @value1 / @KolDayFinPeriod * @kolDayRas
					END
				END
				ELSE
					SELECT @value1 = @tar1 * @kol
				--SELECT @value1=@value1+@tar1*@NormaSingle*koefday FROM #people2 WHERE service_id=@serv1 AND is_paym=1

				--if @debug=1 and @serv1='хвпк' print @serv1+' '+str(@value1,9,2)+' '+str(@NormaSingle,8,4)+ '  '+str(@mode1)+' '+str(@tar1,9,4)+' '+str(@kol,8,4)+' '+str(@kolDayRas)			

				IF @people0_counter_norma = 1
					AND @counter_metod_kol > 0
					AND @Total_peopleReg = 0
				BEGIN
					SELECT @kol = @counter_metod_kol
					SELECT @value1 = @tar1 * @kol
				--IF @debug=1 print str(@value1)+' '+str(@counter_metod_kol,8,4)+ '  '+str(@tar1,9,4)
				END
				SELECT @value1 = @value1 + COALESCE(@value_agri, 0)
					 , @kol = @kol + @kol_agri

			END

			IF (@is_counter1 = 2)
				AND ((@source1 % 1000) > 0
				AND (@mode1 % 1000) > 0)  -- внутренний счетчик и есть режим и поставщик  
			BEGIN
				--print 'внутренний счетчик по услуге: '+@serv1		

				SELECT TOP 1 @serv_unit1 = cl.unit_id     -- получаем ед.измерения
						   , @counter_id1 = counter_id
				FROM #t_counter AS cl
				WHERE cl.internal = 1
					AND cl.service_id = @serv1

				-- получить тариф по счетчику
				--IF @tar_counter1 = 0
				--	SELECT @tar1 = dbo.Fun_GetCounterTarf(@fin_id1, @counter_id1, NULL)
				--ELSE
				--	SELECT @tar1 = @tar_counter1
				IF @tar_counter1 <> 0
					SELECT @tar1 = @tar_counter1

				-- если поставщика или РЕЖИМ НЕТ - не считать
				IF ((@source1 % 1000) = 0
					OR (@mode1 % 1000) = 0)
					SET @tar1 = 0

				IF @counter_metod = 5
					AND @counter_metod_service_kol <> ''
				BEGIN
					IF @counter_metod_kol > 0
						SET @kol = @counter_metod_kol
					ELSE
						SELECT @kol = kol
						FROM @paym_list1 pl
						WHERE pl.occ = @occ1
							AND pl.service_id = @counter_metod_service_kol
					SELECT @kol = @kol + @kol_saldo
					SELECT @value1 = @tar1 * @kol
				--IF @debug=1 PRINT STR(@counter_metod)+' '+@serv1+' '+STR(@kol,9,4)
				END

				IF @counter_metod IN (2, 9) -- начисляем по среднему по счетчикам
					AND (@count_last_month_counter_value<=3 OR @counter_metod=9)
					AND EXISTS (
						SELECT 1
						FROM dbo.Counter_list_all AS cla 
						WHERE occ = @occ1
							AND service_id = @serv1
							AND fin_id = @fin_id1
							AND (CASE
								WHEN @ras_no_counter_poverka = 1 THEN KolmesForPeriodCheck	-- добавил проверку @ras_no_counter_poverka=1      15.12.17
								--WHEN 1 = 1 THEN KolmesForPeriodCheck
								ELSE 0
							END) >= -3
					)
					--AND dbo.Fun_GetKolMonthPeriodCheck(@occ1,@fin_id1,@serv1)>=-3
					BEGIN
						SELECT @kol = ROUND(@KolDayFinPeriod * @avg_vday, 2)   -- средний объём округляем до 2-х знаков  03.02.2022

						-- если несколько лиц.счетов делим пропорционально людям
						IF (@Total_people_flats > @Total_people1)
						BEGIN
							IF (@Total_people1 = 0)
								SET @kol = 0
							ELSE
								SELECT @kol = @kol * @Total_people1 / @Total_people_flats
						END
						SELECT @kol = @kol + @kol_saldo
						SELECT @value1 = @tar1 * @kol

					--IF @debug=1 PRINT @serv1+' '+str(@avg_vday,9,4)+' '+str(@kol,9,4)+' '+str(@KolDayFinPeriod)
					--if @debug=1 PRINT @tar1
					--if @debug=1 PRINT @value1
					--IF @kol=0 SET @counter_metod=1
					END
					ELSE
					IF @counter_metod NOT IN (0, 5, 6)
						SET @counter_metod = 1

				IF @counter_metod = 1  -- начисляем по норме по счетчикам
				BEGIN
					--SET @NormaSingle=NULL			
					IF COALESCE(@NormaSingle, 0) = 0  -- получить норму на человека по счетчику			
						SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 1, @tip_id1, @fin_id1)

					IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
					BEGIN
						SET @value1 = 0

						SELECT @kol = SUM(@NormaSingle * koefday)
						FROM #people2
						WHERE service_id = @serv1
							AND is_paym = 1
						SELECT @kol = @kol + @kol_saldo
						--print @Kol
						SELECT @value1 = @value1 + @tar1 * @NormaSingle * koefday
						FROM #people2
						WHERE service_id = @serv1
							AND is_paym = 1

					--print str(@value1)+' '+str(@NormaSingle)+ '  '+str(@mode1)
					END
					--else print str(@occ1)+' не найдена норма по счетчику '+@serv1		

					IF @counter_metod_kol > 0
					BEGIN
						SELECT @kol = @counter_metod_kol
						SELECT @kol = @kol + @kol_saldo
						SELECT @value1 = @tar1 * @kol
					END

				END

				-- расчет по внутр.счетчику если нет показаний
				IF @counter_metod = 0	-- если не считать 
				BEGIN
					SELECT @kol = 0
						 , @value1 = 0
				END

			END

			IF @occ_serv_kol > 0
			BEGIN
				SELECT @kol = @occ_serv_kol, @counter_metod=8
				SELECT @value1 = @tar1 * @kol
			END

			--if @debug=1 --and @serv1='гвод' 
			--if @debug=1 print @serv1+' '+str(@value1,9,2) +' '+str(@NormaSingle,8,4)+ '  '+str(@mode1)+' '+str(@tar1,9,4)+' '+str(@kol,9,4)+' counter_metod:'+STR(@counter_metod)		
			--if @debug=1 and @serv1='хвод' select * from #people2 ORDER BY service_id
			-- Расчет окончен
			GOTO WriteResult
		END

		/*****************************************************************
		   ед. изм.  "един"
		*****************************************************************/
		IF (@serv_unit1 = 'един')
			AND (@serv1 not in ('анте','отоп')) --AND (@serv1 <> 'элек')
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			SELECT @value1 = @tar1 * @koefDayRas * CASE
                                                       WHEN @is_koef1 = 1 THEN @koef1
                                                       ELSE 1
                END
				 , @kol = 1

			--if @debug=1 PRINT STR(@value1,9,2)+' '+STR(@tar1,9,2)
			-- select * from #people2
			-- Расчет окончен
			GOTO WriteResult
		END
		
		-- *****************************************************************************************
		IF (@serv_unit1 = 'едкм')
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			-- -- тариф расчитываем пропорционально пропорционально людям
			--IF (@Total_people_flats>@Total_people1)
			--BEGIN
			--	IF (@Total_people1=0) SET @tar1=0
			--	ELSE
			--	SELECT @tar1=@tar1*@Total_people1/@Total_people_flats
			--END 
			IF @CountOccFlats > 0
				SELECT @tar1 = @tar1 / @CountOccFlats

			SELECT @value1 = @tar1 * @koefDayRas * CASE
                                                       WHEN @is_koef1 = 1 THEN @koef1
                                                       ELSE 1
                END
				 , @kol = 1

			-- select * from #people2
			-- Расчет окончен
			GOTO WriteResult
		END
		
		-- *****************************************************************************************
		IF (@serv_unit1 IN ('кубм2', 'квтчм2'))
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду
			IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
			BEGIN
				SELECT @kol = @NormaSingle * @Total_Sq1 * @koefDayRas
				SELECT @value1 = @tar1 * @kol
			END
			--IF @debug=1 print str(@value1,9,2)+' '+str(@NormaSingle,12,6)+ '  '+str(@kol,12,6)+ '  '+str(@tar1,12,6)
			-- Расчет окончен
			GOTO WriteResult
		END

		-- *****************************************************************************************
		IF (@serv_unit1 IN ('ктон', 'кклг'))
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			--SELECT @kol=@NormaSingle
			--SELECT
			--	@value1 = @tar1 * @kol

			IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
			BEGIN
				SET @value1 = 0

				if @status1='своб' AND @counter_metod=7
				BEGIN
					SELECT @value1 = @tar1 * @NormaSingle * @koefDayRas, @kol = @NormaSingle
				END
				ELSE
				BEGIN
					SELECT @kol = SUM(@NormaSingle * koefday)
					FROM #people2
					WHERE service_id = @serv1
						AND is_paym = 1

					SELECT @kol = @kol + @kol_saldo

					--print @Kol
					SELECT @value1 = @value1 + @tar1 * @NormaSingle * koefday
					FROM #people2
					WHERE service_id = @serv1
						AND is_paym = 1
				END

			--print str(@value1,9,2)+' '+str(@NormaSingle,12,6)+ '  '+str(@kol,12,6)
			END

			-- Расчет окончен
			GOTO WriteResult
		END

		-- ************** Расчет за Антенну ****************
		IF (@serv1 = 'анте')
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			SELECT @value1 = @tar1 * @koefDayRas * CASE
                                                       WHEN @is_koef1 = 1 THEN @koef1
                                                       ELSE 1
                END
				 , @kol = 1

			-- Расчет окончен
			GOTO WriteResult
		END

		-- ************** Расчет за Обращение с ТКО ****************
		-- Если ни кто не зарегистрирован, то на собственников иначе на зарегистрированных
		--IF (@serv1 IN ('втбо'))
		IF @serv_unit1 IN ('ротко')
		BEGIN
			--if @debug=1 PRINT @serv1
			IF @payms_tip1 = 0 -- если не начисляем по данному жилому фонду
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
			BEGIN
				SELECT @value1 = 0, @kol = 0, @kol_tmp = 0

				if @status1='своб' AND @Total_Sq1>0 --AND @counter_metod=7
				BEGIN
					SELECT @value1 = @tar1 * @NormaSingle * @koefDayRas, @kol = @NormaSingle
				END
				ELSE
				BEGIN
					-- находим кол-во зарегистрированных и по собственникам
					SELECT @kol = SUM(@NormaSingle * CASE
                                                         WHEN is_registration = 1 THEN koefday
                                                         ELSE 0
                        END) 
						, @kol_tmp = SUM(@NormaSingle * CASE
                                                            WHEN is_owner_flat = 1 THEN koefday
                                                            ELSE 0
                        END)
					FROM #people2
					WHERE service_id = @serv1

					IF @kol=0 
						SET @kol=@kol_tmp
						
					SELECT @kol = @kol + @kol_saldo
					SELECT @value1 = @value1 + @tar1 * @kol

				END				
			END
			--if @debug=1  print str(@value1,9,2)+' '+str(@NormaSingle,12,6)+ ' @kol='+str(@kol,12,6)+ ' @kol_tmp='+str(@kol_tmp,12,6)
		END

		-- ************** Расчет за Электричество ****************
		IF (@serv1 IN ('элек', 'эле2', 'элпк'))
		BEGIN
			--if @debug=1 PRINT @serv1
			IF @payms_tip1 = 0 -- если не начисляем по данному жилому фонду
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			DECLARE @KolWatt DECIMAL(8, 4) = 0

			IF @is_counter1 = 2
				AND @tar1 = 0  -- если забыли установить тариф по норме
			BEGIN
				SELECT @tar1 = dbo.Fun_GetCounterTarfServ(@fin_id1, @occ1, 'элек', 'квтч')
			END

			--SELECT @Total_people_ee1=COUNT(owner_id) FROM #people2 
			--WHERE service_id=@serv1 

			IF @Total_people_ee1 = 0
				AND NOT @is_counter1 = 2 -- внутр. счётчик
				AND NOT @counter_metod = 2 -- расчёт по среднему
				GOTO WriteResult  -- Расчет окончен


			IF @serv1 IN ('элпк')
				SELECT @mode1 = mode_id
				FROM #services1
				WHERE id = 'элек'

			IF @kol_rooms > 0
				AND @Total_people_ee1 > 0
			BEGIN
				SELECT @KolWatt = kol_watt
				FROM dbo.Measurement_ee 
				WHERE mode_id = @mode1
					AND Rooms =
							   CASE
								   WHEN @kol_rooms > 4 THEN 4
								   ELSE @kol_rooms
							   END
					AND kol_people =
									CASE
										WHEN @Total_people_ee1 > 5 THEN 5
										ELSE @Total_people_ee1
									END
					AND fin_id = @fin_id1
			END
			ELSE
			IF @kol_rooms = 0
				AND @Total_people_ee1 > 0
			BEGIN -- не задано количество комнат
				SELECT @NormaSingle = q_single
					 , @NormaMember = q_member
					 , @NormaTwoSingle = two_single
					 , @NormaThreeSingle = three_single
					 , @NormaFourSingle = four_single
				FROM dbo.Measurement_units 
				WHERE unit_id = @serv_unit1
					AND mode_id = @mode1
					AND is_counter = 0
					AND tip_id = @tip_id1
					AND fin_id = @fin_id1

				--select @Total_people_ee1, @PeopleSocNorma

				SET @KolWatt =
							  CASE
								  WHEN @Total_people_ee1 = 0 THEN 0
								  WHEN @Total_people_ee1 = 1 THEN @NormaSingle
								  WHEN @Total_people_ee1 = 2 THEN @NormaTwoSingle
								  WHEN @Total_people_ee1 = 3 THEN @NormaThreeSingle
								  WHEN @Total_people_ee1 = 4 THEN @NormaFourSingle
								  ELSE @NormaFourSingle + (@NormaMember * (@Total_people_ee1 - 4))
							  END

				SET @KolWatt = @KolWatt / @Total_people_ee1

			END

			IF @KolWatt IS NULL
				SET @KolWatt = 0

			IF @occ_serv_kol > 0
				SELECT @KolWatt = @occ_serv_kol, @counter_metod=8

			--if @debug=1 print @serv1+' KolWatt: '+str(@KolWatt,8,4)+'  tar:'+str(@tar1,8,4)+' Total_people_ee1: '+str(@Total_people_ee1)
			--if @debug=1 print ' kol_rooms: '+STR(@kol_rooms)+', mode_id='+str(@mode1)+', @koef1='+str(@koef1,10,4)

			--================================================
			IF @serv1 IN ('элпк')
				IF EXISTS (
						SELECT 1
						FROM dbo.Counter_list_all cla
						WHERE fin_id = @fin_id1
							AND occ = @occ1
							AND cla.service_id = 'элек'
							AND (CASE
								WHEN 1 = 1 THEN KolmesForPeriodCheck
								ELSE 0
							END) >= @pkoef_rasch_dpoverka ---3  @pkoef_rasch_dpoverka дата поверки истекла не более 3 мес назад
					)
					SELECT @KolWatt = 0
			--================================================

			UPDATE #people2
			SET Snorm = @KolWatt * koefday * CASE
                                                 WHEN @is_koef1 = 1 THEN @koef1
                                                 ELSE 1
                END
			WHERE service_id = @serv1
				AND is_paym = 1

			--if @debug=1 select * from #people2 where service_id='элек'			
			--if @debug=1 print concat(@serv1,' KolWatt: ', @KolWatt,'  tar:',@tar1,' Total_people_ee1: ',@Total_people_ee1,' kol_rooms: ',@kol_rooms)

			SELECT --@kol = SUM(Snorm)
				@kol += Snorm
				,@value1 = @value1 + @tar1 * Snorm --* koefday 
			FROM #people2
			WHERE service_id = @serv1
				AND is_paym = 1

			--if @debug=1 print concat(@serv1,' @value1: ', coalesce(@value1,0),'  @kol:',coalesce(@kol,0))

			IF @is_counter1 = 2
				AND @counter_metod IN (2, 9)  -- начисляем по среднему по счетчикам
			BEGIN
				IF (@count_last_month_counter_value<=3 OR @counter_metod=9)
					AND EXISTS (
						SELECT 1
						FROM dbo.Counter_list_all AS cla 
						WHERE occ = @occ1
							AND service_id = @serv1
							AND fin_id = @fin_id1
							AND (CASE
								WHEN @ras_no_counter_poverka = 1 THEN KolmesForPeriodCheck	-- добавил проверку @ras_no_counter_poverka=1      15.12.17
								--WHEN 1 = 1 THEN KolmesForPeriodCheck
								ELSE 0
							END) >= -9999
					)  --  быдо -3  -- сказали если истекла дата надо всегда считить по среднему 08.09.2021
				--AND dbo.Fun_GetKolMonthPeriodCheck(@occ1,@fin_id1,@serv1)>=-3
				BEGIN
					--IF @debug = 1
					--	PRINT 'вычисляем сумму средних значений счётчиков по услуге: ' + @serv1
					--SELECT
					--	@avg_vday = dbo.Fun_GetAvgCounterValue(@occ1, @serv1)

					--if @debug=1 SELECT @KolDayFinPeriod,@kol_tmp
					SELECT @kol_tmp = @KolDayFinPeriod * @avg_vday

					-- если несколько лиц.счетов делим пропорционально людям
					IF (@Total_people_flats > @Total_people1)
					BEGIN
						IF (@Total_people1 = 0)
							SET @kol_tmp = 0
						ELSE
							SELECT @kol_tmp = @kol_tmp * @Total_people1 / @Total_people_flats
					END

					--IF @debug = 1
					--	SELECT @serv1, @Total_people_flats AS Total_people_flats
					--	   ,@Total_people1 AS Total_people1,@kol AS kol, @kol_tmp,@avg_vday AS avg_vday,@KolDayFinPeriod AS KolDayFinPeriod

					--IF @kol_tmp <= 0   -- Закомментировал если показание 0 то так должно быть.    10.10.2019  
					--	SET @counter_metod = 1
					--ELSE
					BEGIN
						SET @kol = @kol_tmp
						SELECT @kol = @kol + @kol_saldo
						SELECT @value1 = @tar1 * @kol
					END

				END
				ELSE
				IF @counter_metod NOT IN (0, 5, 6)
					SET @counter_metod = 1
			END

			IF @counter_metod = 1
				AND @counter_metod_kol > 0  --  начислять по норме и норма задана
			BEGIN
				SELECT @kol = @counter_metod_kol
				SELECT @value1 = @tar1 * @kol
			END

			SELECT @Norma_extr_tarif=COALESCE(norma_extr_tarif,0)
				, @Norma_full_tarif=COALESCE(norma_full_tarif,0)
			FROM dbo.Fun_GetNorma_tf(@serv_unit1, @mode1, @is_counter1, @tip_id1, @fin_id1)			
			--IF @debug=1 print @serv_unit1 +' '+ str(@mode1)+' '+ str(@is_counter1)+' '+ str(@tip_id1)+' '+ str(@fin_id1)

			-- есть сверх нормативный тариф
			if @extr_tar>0 AND @Norma_extr_tarif>0 and @Norma_full_tarif>=0
			BEGIN
				IF @kol<@Norma_extr_tarif
				BEGIN
					SELECT @value1 = @tar1 * @kol
				END
				ELSE  -- если нет показаний ИПУ				
					IF NOT EXISTS (SELECT 1	FROM dbo.View_counter_inspector_lite 
									WHERE fin_id = @fin_id1 
									AND occ = @occ1	--AND tip_value=1
									AND	(CASE
											WHEN @ras_no_counter_poverka = 1 THEN KolmesForPeriodCheck
											ELSE 0
										END) >= 0
					)
					BEGIN
						DELETE FROM dbo.Counter_paym2 WHERE fin_id=@fin_id1 and occ=@occ1 AND service_id=@serv1
					
						IF @kol>=@Norma_extr_tarif and @kol<@Norma_full_tarif
						BEGIN
							SELECT @value1 = (@tar1 * @Norma_extr_tarif)+((@kol-@Norma_extr_tarif)*@extr_tar)
							INSERT INTO dbo.Counter_paym2([fin_id], [occ], [service_id], [tip_value], [tarif], [value], [kol], [metod_rasch])
							VALUES(@fin_id1, @occ1,@serv1,1,@tar1,(@tar1 * @Norma_extr_tarif),@Norma_extr_tarif, 0),
								  (@fin_id1, @occ1,@serv1,1,@extr_tar,(@extr_tar*(@kol-@Norma_extr_tarif)), (@kol-@Norma_extr_tarif), 0)
						END
						ELSE
						IF @kol>@Norma_full_tarif
						BEGIN
							SELECT @value1 = (@tar1 * @Norma_extr_tarif)+(@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif))+(@full_tar*(@kol-@Norma_full_tarif))						
							INSERT INTO dbo.Counter_paym2([fin_id], [occ], [service_id], [tip_value], [tarif], [value], [kol], [metod_rasch])
							VALUES(@fin_id1, @occ1, @serv1, 1, @tar1, (@tar1 * @Norma_extr_tarif), @Norma_extr_tarif, 0),
								  (@fin_id1, @occ1, @serv1, 1, @extr_tar, (@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif)), (@Norma_full_tarif-@Norma_extr_tarif), 0),
								  (@fin_id1, @occ1, @serv1, 1, @full_tar, (@full_tar * (@kol-@Norma_full_tarif)), (@kol-@Norma_full_tarif), 0)
						END
					END
				--if @debug=1
				--begin
				--	PRINT concat(@tar1,' * ',dbo.NSTR(@Norma_extr_tarif),' = ',dbo.NSTR(@tar1 * @Norma_extr_tarif))
				--	PRINT concat(@extr_tar,' * ',dbo.NSTR(@Norma_full_tarif-@Norma_extr_tarif),' = ', dbo.NSTR((@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif))) )
				--	PRINT concat(@full_tar,' * ',dbo.NSTR(@kol-@Norma_full_tarif),' = ',dbo.NSTR((@full_tar*(@kol-@Norma_full_tarif))) )
				--	PRINT str(@value1,9,2)
				--end
			END;

			-- расчет по внутр.счетчику если нет показаний
			IF @is_counter1 = 2
				AND @value1 > 0
				AND @counter_metod = 0	-- если не считать 
			BEGIN
				SELECT @kol = 0
					 , @value1 = 0
			END

			--IF @debug=1 PRINT @serv1+' value:'+str(@value1,9,2)+' kol:'+str(@kol,12,6)+' kol_tmp:'+str(@kol_tmp,12,6)+' avg_vday:'+STR(@avg_vday,6,4)+' KolDayFinPeriod:'+STR(@KolDayFinPeriod)
			--IF @debug=1 PRINT 'is_counter:'+STR(@is_counter1)+' counter_metod:'+STR(@counter_metod)+' counter_metod_kol:'+STR(@counter_metod_kol)
			--IF @debug=1 print @serv1+' '+str(@value1,9,2)+' '+str(@NormaSingle,8,4)+ ' '+str(@Kol,9,4)+' '+str(@Norma_extr_tarif,9,4)+' '+str(@Norma_full_tarif,9,4)
			-- Расчет окончен
			GOTO WriteResult
		END
		
		-- *****************************************************************************************
		IF (@serv_unit1 = N'квтч')
		BEGIN
			IF @payms_tip1 = 0 -- если не начисляем по данному жилому фонду
			BEGIN
				SELECT @full_tar = 0
					 , @tar1 = 0
					 , @kol = 0
					 , @value1 = 0
				GOTO WriteResult
			END

			--SET @NormaSingle=NULL

			-- получить норму на человека по счетчику
			--IF COALESCE(@NormaSingle, 0) = 0
			--SELECT @NormaSingle = NormaSingle
			--	, @Norma_extr_tarif=COALESCE(norma_extr_tarif,0)
			--	, @Norma_full_tarif=COALESCE(norma_full_tarif,0)
			--FROM dbo.Fun_GetNorma_tf(@serv_unit1, @mode1, @is_counter1, @tip_id1, @fin_id1)

			IF COALESCE(@NormaSingle, 0) > 0 -- норма заполнена
			BEGIN
				SET @value1 = 0

				SELECT @kol = SUM(@NormaSingle * koefday)
				FROM #people2
				WHERE service_id = @serv1
					AND is_paym = 1
				--print @Kol				
				SELECT @value1 = @tar1 * @kol
								
				--SELECT @value1 = @value1 + @tar1 * @NormaSingle * koefday
				--FROM #people2
				--WHERE service_id = @serv1
				--	AND is_paym = 1
			END			
			
			IF @serv_is_build = 1
			BEGIN	-- общедомовая услуга	
				--PRINT @NormaSingle
				SELECT @kol = @NormaSingle * @occ_opu_sq
				SELECT @value1 = @tar1 * @kol
			END

			IF @occ_serv_kol > 0
			BEGIN
				SELECT @kol = @occ_serv_kol, @counter_metod=8
				SELECT @value1 = @tar1 * @kol
			END

			--IF @debug=1 print @serv1+' '+str(@value1)+' '+str(@NormaSingle,8,4)+ ' '+str(@occ_opu_sq,9,2)+' '+str(@Kol,9,4)
			-- select * from #people2
			-- Расчет окончен
			GOTO WriteResult
		END
		
		-- *****************************************************************************************
		IF (@serv_unit1 IN ('одпу'))
			AND (@serv1 = 'обуу')
			AND (@mode1 % 1000 > 0)
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			SELECT @kol = CASE
                              WHEN @total_sq_new > 0 THEN @total_sq_new
                              ELSE @Total_Sq1
                END --@Square
				 , @tar1 = (@tar1 * @opu_tepl_kol) / @Build_total_serv_soi

			SELECT @value1 = @tar1 * @koefDayRas * @kol

			--IF @debug=1 
			--BEGIN
			--	PRINT '  @kol: '+str(@kol,9,4)+ ' @tar1: '+str(@tar1,9,4)+ ' @opu_tepl_kol: '+str(@opu_tepl_kol,9,4)  
			--	PRINT '  @Build_total_serv_soi: '+str(@Build_total_serv_soi,9,4)+ ' @value1: '+str(@value1,9,2)
			--END

			-- Расчет окончен
			GOTO WriteResult
		END
		
		-- *****************************************************************************************
		IF (@serv_unit1 IN ('одсч', 'одс2', 'одпо', 'одсч2'))   -- единицы измерения на СОИ  одсч-Вода одс2-ЭЭЛ одпо-отпление(газ)
			AND (@mode1 % 1000 > 0)-- ОДН с 01.01.2017 
		BEGIN
			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			-- ищем норматив по услуге по дому
			SET @NormaSingleBuild = NULL
			SELECT @NormaSingleBuild = sb.norma_kol
				 , @Build_total_serv_soi = CASE
                                               WHEN sb.build_total_sq > 0 THEN sb.build_total_sq
                                               ELSE @Build_total_serv_soi
                END
			FROM dbo.Services_build sb
			WHERE sb.build_id = @build_id1
				AND sb.service_id = @serv1

			--IF @debug=1 
			--BEGIN
			--	PRINT coalesce(@NormaSingleBuild,0)
			--	PRINT coalesce(@Build_total_serv_soi,0)
			--END

			SET @Square = CASE
                              WHEN @total_sq_new > 0 THEN @total_sq_new
                              ELSE @Total_Sq1
                END

			IF @Square > 0	  -- а то (@Total_Sq_build + @Build_arenda_sq) бывает = 0

				IF @soi_metod_calc = 'CALC_KOL'
				BEGIN
					--IF @debug=1 PRINT '-- метод по расчету объема услуги'
					SELECT @NormaSingle = COALESCE(@NormaSingleBuild, dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 0, @tip_id1, @fin_id1))
					--SELECT
					--	@NormaSingle = dbo.Fun_GetNormaSingle('одсч', @mode1, 0, @tip_id1, @fin_id1)

					IF @serv_unit1 = 'одс2' -- Доля общедом ЭЭ сои кВтч
						SELECT @kol = @NormaSingle * @Square * @Build_opu_sq_elek / @Build_total_serv_soi
					ELSE
					IF @serv_unit1 = 'одпо' -- Доля общедом на Отопление
						SELECT @kol = @NormaSingle * @Square * @Build_opu_sq_otop / @Build_total_serv_soi
					ELSE
					BEGIN
						IF @serv1 in ('одтж') -- ТЭдля ГВ на сод.о.и*
						BEGIN
							-- надо использовать норматив с услуги одгж(гвс одн)	
							--SELECT @norma_gkal_gvs = dbo.Fun_GetNormaSingle(@serv_unit1, (
							--			SELECT TOP (1) mode_id
							--			FROM #services1
							--			WHERE id = 'одгж'  -- ГВ для сод. о.и.*
							--				AND sup_id = @sup_id
							--		), 0, @tip_id1, @fin_id1)

							SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, (
										SELECT TOP (1) mode_id
										FROM #services1
										WHERE id = 'одгж'  -- ГВ для сод. о.и.*
											AND sup_id = @sup_id
									), 0, @tip_id1, @fin_id1)

							SELECT @kol = @NormaSingle * @norma_gkal_gvs * @Square * @Build_opu_sq / @Build_total_serv_soi 
						END
						ELSE
							SELECT @kol = @NormaSingle * @Square * @Build_opu_sq / @Build_total_serv_soi
					END

					-- расчитываем кол-во с коэф.дней
					SET @kol = @koefDayRas * @kol
					SELECT @value1 = @tar1 * @kol
				END
				ELSE  
				BEGIN
					--IF @debug=1 PRINT '-- метод по расчету тарифа'
					SELECT @NormaSingle = COALESCE(@NormaSingleBuild, dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 0, @tip_id1, @fin_id1))
					--SELECT
					--	@NormaSingle = COALESCE(@NormaSingleBuild, dbo.Fun_GetNormaSingle('одсч', @mode1, 0, @tip_id1, @fin_id1))
					SELECT @kol = @Square
						 , @full_tar = @tar1

					IF @serv1 = 'одэж' -- ЭЭ для сод. о.и.*
						SELECT @tar1 = @NormaSingle * @Build_opu_sq_elek * @full_tar / @Build_total_serv_soi
					ELSE
					IF @serv_unit1 = 'одпо'  -- Доля общедом на Отопление
						SELECT @tar1 = @NormaSingle * @Build_opu_sq_otop * @full_tar / @Build_total_serv_soi
					ELSE
					IF @serv1 = 'одтж' -- ТЭдля ГВ на сод.о.и*
					BEGIN
						-- надо использовать норматив с услуги одгж(гвс одн)
						SELECT @NormaSingle = dbo.Fun_GetNormaSingle(@serv_unit1, (
								SELECT TOP 1 mode_id
								FROM #services1
								WHERE id = 'одгж'  -- ГВ для сод. о.и.*
									AND sup_id = @sup_id
							), 0, @tip_id1, @fin_id1)
						SELECT @tar1 = @NormaSingle * @norma_gkal_gvs * @Build_opu_sq * @full_tar / @Build_total_serv_soi
					END
					ELSE
						SELECT @tar1 = @NormaSingle * @Build_opu_sq * @full_tar / @Build_total_serv_soi

					-- расчитываем сумму с коэф.дней
					SELECT @value1 = @tar1 * @koefDayRas * @kol
				END

			--IF @debug=1 
			--BEGIN
			--	PRINT '=>'+@serv1+' @tar1: '+str(@tar1,9,4) +' @soi_metod_calc: '+@soi_metod_calc+' @serv_unit1: '+@serv_unit1+' @kol: '+str(@kol,12,6)
			--	PRINT '  @NormaSingle: '+str(@NormaSingle,10,6)+ ' @Square: '+str(@Square,9,4) + ' @Build_opu_sq: '+str(@Build_opu_sq,9,2)+ ' @Build_total_serv_soi: '+str(@Build_total_serv_soi,9,2)
			--	PRINT '  @Total_Sq_build: '+str(@Total_Sq_build,9,2)+' @Build_arenda_sq: '+str(@Build_arenda_sq,9,2)
			--	PRINT '  @Build_opu_sq_otop: '+str(@Build_opu_sq_otop,9,2) +' @koefDayRas: '+str(@koefDayRas,9,2)
			--	PRINT '  @full_tar: '+str(@full_tar,9,2)+ ' @norma_gkal_gvs: '+str(@norma_gkal_gvs,9,6)
			--	PRINT '  @value1: '+str(@value1,9,2)+' @mode1: '+str(@mode1)
			--END

			-- Расчет окончен
			GOTO WriteResult
		END

		-- ************** Расчет Цессии в тек.месяце ****************
		IF (@serv1 in (N'цеся', N'клек')) AND @added = 0
		BEGIN
			--print 'Расчёт цессии'

			IF @payms_tip1 = 0
				SELECT @full_tar = 0
					 , @tar1 = 0  -- если не начисляем по данному жилому фонду

			SELECT @SumSaldo_Serv = saldo
			FROM @paym_list1
			WHERE occ = @occ1
				AND service_id = @serv1
				AND sup_id = @sup_id

			IF @SumSaldo_Serv = 0  -- Если долга по услугам нет - проверяем на OCC_SUPPLIERS
			BEGIN
				IF NOT EXISTS (
						SELECT 1
						FROM dbo.Occ_Suppliers OS 
						WHERE occ = @occ1
							AND fin_id < @fin_id1
							AND sup_id = @sup_id
					)
				BEGIN
					SELECT @SumSaldo_Serv = saldo
					FROM dbo.Occ_Suppliers OS 
					WHERE occ = @occ1
						AND fin_id = @fin_id1
						AND sup_id = @sup_id

					UPDATE pl
					SET saldo = @SumSaldo_Serv
					FROM @paym_list1 AS pl
					WHERE occ = @occ1
						AND service_id = @serv1
						AND sup_id = @sup_id
				END
			END
			--PRINT @SumSaldo_Serv
			IF @SumSaldo_Serv <= 0  -- Если долга нет - не начисляем
			BEGIN
				SELECT @kol = 0
					 , @value1 = 0
					 , @SumSaldo_Serv = 0
			--GOTO WriteResult
			END

			SELECT @kol = 0
				 , @cessia_dolg_mes = NULL

			SELECT @occ_sup = os.occ_sup
				 , @cessia_dolg_mes_start = c.dolg_mes_start
			FROM dbo.Occ_Suppliers os 
				JOIN dbo.Cessia AS c ON os.occ_sup = c.occ_sup
					AND c.dog_int = os.dog_int
			WHERE os.occ = @occ1
				AND fin_id = @fin_id1

			-- читаем кол-во месяцев долга за прошлый месяц
			SELECT @cessia_dolg_mes = cessia_dolg_mes_new
			FROM dbo.Occ_Suppliers 
			WHERE occ = @occ1
				AND fin_id = @fin_id1 - 1
				AND sup_id = @sup_id

			IF @cessia_dolg_mes IS NULL
			BEGIN
				UPDATE os
				SET cessia_dolg_mes_old = @cessia_dolg_mes_start
				  , @cessia_dolg_mes = @cessia_dolg_mes_start
				FROM dbo.Occ_Suppliers AS os 
				WHERE os.occ = @occ1
					AND fin_id = @fin_id1
					AND occ_sup = @occ_sup
			END

			IF @cessia_dolg_mes < @cessia_dolg_mes_start
				SET @cessia_dolg_mes = @cessia_dolg_mes_start

			-- находим процент
			IF @serv1 = N'цеся'
			BEGIN
				SELECT @value1 = COALESCE(SUM(PC.value_ces), 0)
				FROM dbo.Paying_serv AS PS 
					JOIN dbo.Paying_cessia AS PC 
						ON PC.paying_id = PS.paying_id
				WHERE occ = @occ1
					AND service_id = @serv1

				SELECT TOP 1 @kol = PC.kol_ces
				FROM dbo.Paying_serv AS PS 
					JOIN dbo.Paying_cessia AS PC 
						ON PC.paying_id = PS.paying_id
				WHERE occ = @occ1
					AND service_id = @serv1

			--SELECT @Kol=[dbo].[Fun_GetProcentAgenta] (@cessia_dolg_mes_start,@dog_int, Null)
			--SELECT @Kol=procent
			--FROM dbo.STAVKI_AGENTA 
			--WHERE @cessia_dolg_mes_start BETWEEN mes1 AND mes2
			END
			IF @serv1 = N'клек'
			BEGIN
				SELECT @value1 = COALESCE(SUM(PC.value_col), 0)
				FROM dbo.Paying_serv AS PS 
					JOIN dbo.Paying_cessia AS PC 
						ON PC.paying_id = PS.paying_id
				WHERE occ = @occ1
					AND service_id = @serv1

				SELECT TOP 1 @kol = COALESCE(PC.kol_col, 0)
				FROM dbo.Paying_serv AS PS 
					JOIN dbo.Paying_cessia AS PC 
						ON PC.paying_id = PS.paying_id
				WHERE occ = @occ1
					AND service_id = @serv1

				--SELECT @Kol=[dbo].[Fun_GetProcentAgenta] (@cessia_dolg_mes_start,NULL, @collector_id)

				UPDATE @paym_list1
				SET saldo = 0
				WHERE service_id = N'клек'  -- по коллекторам сальдо не хранить
			END


			IF @SumSaldo_Serv > 0
				SELECT @cessia_dolg_mes = @cessia_dolg_mes + 1

			SELECT @Paymaccount_Serv = 0
				 , @SumSaldo_Serv = 0

			-- Расчет окончен
			GOTO WriteResult
		END

	--IF @occ_serv_kol > 0
	--BEGIN
	--	SELECT
	--		@kol = @occ_serv_kol, @counter_metod=8
	--	SELECT
	--		@value1 = @tar1 * @kol
	--END

	-- записываем результат

	WriteResult:

		IF @tar1 IS NULL
			SELECT @tar1 = 0
		IF @koef1 IS NULL
			SELECT @koef1 = 0

		IF @value1 IS NULL
			SELECT @value1 = 0
		IF @discount1 IS NULL
			SELECT @discount1 = 0
		IF @added1 IS NULL
			SELECT @added1 = 0
		IF @SumSaldo IS NULL
			SELECT @SumSaldo = 0

		--**************************************************************
		-- Наем  (Для приватизированных и купленных квартир не расчитывается)
		IF (@serv1 = N'наем')
			AND (@proptype1 = N'прив'
			OR @proptype1 = N'купл')
		BEGIN
			SELECT @value1 = 0
			SELECT @discount1 = 0
		END

		IF @subsid_only1 = 1
		BEGIN
			SELECT @value1 = 0
			SELECT @discount1 = 0

			UPDATE #people2
			SET discount = 0
			WHERE service_id = @serv1
				AND discount > 0
		END


		IF @counter_votv_norma = 0
			IF @value1 = 0
				SET @kol = 0
			ELSE
			IF @value1 = 0
				AND @is_counter1 > 0
				SET @kol = 0

		-- изменяем
		UPDATE @paym_list1
		SET subsid_only = COALESCE(@subsid_only1, 0)
		  , is_counter = @is_counter1
		  , tarif = @tar1
		  , koef =
				  CASE
					  WHEN @koef1 = 1 THEN NULL
					  ELSE @koef1
				  END
		  , kol = COALESCE(@kol, 0)
		  , kol_norma = COALESCE(@kol, 0)
		  , value = COALESCE(@value1, 0)
		  , discount = COALESCE(@discount2, 0)
		  , added = 0
		  ,    --@added1   26/09/2005  далее заполняем
			serv_unit = @serv_unit1
		  , metod =
				   CASE
					   WHEN @is_counter1 = 2 AND
						   @counter_metod in (2,9) THEN 2  -- по среднему
					   WHEN @is_counter1 = 2 AND
						   @counter_metod = 0 THEN 0  -- не начислять
					   WHEN @is_counter1 = 2 AND
						   @counter_metod = 1 THEN 1  -- по норме
					   WHEN @is_counter1 = 2 AND
						   @counter_metod = 8 THEN 8  -- ручной из карточки режимов
					   WHEN @is_counter1=0 AND service_id in ('хвод','гвод') AND @kol>0 THEN 1 -- по норме  --29/08/23
				   END
		  , mode_id = @mode1
		  , source_id = @source1
		  , counter_metod = @counter_metod
		  , counter_metod_service_kol = @counter_metod_service_kol
		  , normaSingle = @NormaSingle
		  , avg_vday = @avg_vday
		  , date_ras_start = @date_ras_start
		  , date_ras_end = @date_ras_end
		  , kol_saldo = @kol_saldo
		  , koef_day = @koefDayRas
		WHERE occ = @occ1
			AND service_id = @serv1
			AND sup_id = @sup_id

		--if @serv1='пгаз' select * from #people2 where service_id=@serv1
		--if @debug=1 and @serv1='отоп' select * from @paym_list1 where service_id=@serv1
		--if @debug=1 select @serv1 as serv1, @value1 as value1, @serv_unit1 as serv_unit1, @tar1 as tar1, @counter_metod as counter_metod

		FETCH NEXT FROM Cur_services
		INTO @serv1, @is_koef1, @is_norma1, @is_subs1, @mode1, @source1, @koef1, @subsid_only1,
		@serv_unit1, @is_counter1, @tar1, @extr_tar, @full_tar, @sup_id, @dog_int, @serv_is_build,
		@date_ras_start, @date_ras_end, @avg_vday, @tar_counter1,
		@NormaSingle, @NormaMember, @NormaTwoSingle, @NormaThreeSingle, @Total_people_flats,
		@counter_metod, @counter_metod_kol, @counter_metod_service_kol, @pkoef_rasch_dpoverka, 
		@occ_serv_kol, @count_last_month_counter_value
	END

	CLOSE Cur_services
	DEALLOCATE Cur_services
	--*************************************************** 

	UPDATE pl
	SET metod_old = metod -- сохраняем метод расчёта
	, serv_unit=CASE
                    WHEN pl.serv_unit = '' THEN s.unit_id
                    ELSE pl.serv_unit
        END               -- проставляем ед.изм. по умолчанию (например были только разовые)
	FROM @paym_list1 AS pl
	LEFT JOIN #services1 as s ON pl.service_id=s.id AND pl.sup_id=s.sup_id

	--UPDATE p1
	--SET p1.mode_id=cl.mode_id, source_id=cl.source_id
	--FROM @paym_list1 AS p1
	--JOIN dbo.consmodes_list AS cl ON p1.occ=cl.occ AND p1.service_id=cl.service_id
	--WHERE cl.occ=@occ1 AND @added1=0  -- текущий расчёт

	--UPDATE #people2 
	--SET owner_lgota=0 
	--WHERE discount=0

	--where p.service_id not in (select id from #services1)   

	--***************************************************
	--IF @debug=1 select * from @paym_list1
	--select * from #people2 order by service_id

	--***********************************************************************
	DELETE FROM #people2
	WHERE tarif = 0

	UPDATE #people2
	SET LgotaAll = 0
	WHERE discount = 0

	-- заносим расширенную информацию о расчете
	IF @people_list = 1
	BEGIN
		DELETE FROM dbo.People_list_ras
		WHERE occ = @occ1

		INSERT INTO dbo.People_list_ras (occ
									   , owner_id
									   , service_id
									   , lgota_id
									   , Snorm
									   , percentage
									   , owner_only
									   , norma_only
									   , nowork_only
									   , status_id
									   , is_paym
									   , is_lgota
									   , is_subs
									   , is_norma
									   , is_norma_sub
									   , is_rates
									   , birthdate
									   , tarif
									   , kolday
									   , koefday
									   , KolDayLgota
									   , KoefDayLgota
									   , Sown_s
									   , LgotaAll
									   , discount
									   , owner_lgota)
		SELECT @occ1
			 , owner_id
			 , service_id
			 , lgota_id
			 , Snorm
			 , percentage
			 , owner_only
			 , norma_only
			 , nowork_only
			 , status_id
			 , is_paym
			 , is_lgota
			 , is_subs
			 , is_norma
			 , is_norma_sub
			 , is_rates
			 , birthdate
			 , tarif
			 , kolday
			 , koefday
			 , KolDayLgota
			 , KoefDayLgota
			 , Sown_s
			 , LgotaAll
			 , discount
			 , owner_lgota
		FROM #people2

	END

	--if @debug=1 select * from @paym_list1

	-- Удаляем начисления по счетчику если их быть там не должно
	DELETE FROM dbo.Paym_counter_all
	WHERE occ = @occ1
		AND fin_id = @FinPeriodCurrent

	-- Добавляем начисления из истории
	INSERT INTO dbo.Paym_counter_all (fin_id
									, occ
									, service_id
									, subsid_only
									, tarif
									, saldo
									, value
									, discount
									, added
									, Compens
									, paid
									, paymaccount
									, paymaccount_peny)
	SELECT @FinPeriodCurrent
		 , ph.occ
		 , ph.service_id
		 , ph.subsid_only
		 , tarif
		 , debt
		 , 0
		 , 0
		 , COALESCE(aca.val, 0) AS added
		 , 0
		 , COALESCE(aca.val, 0) AS paid
		 , 0
		 , 0
	FROM dbo.Paym_counter_all AS ph 
		OUTER APPLY (
			SELECT SUM(t2.value) AS val
			FROM dbo.Added_Counters_All AS t2 
			WHERE t2.occ = ph.occ
				AND t2.fin_id = ph.fin_id
				AND t2.service_id = ph.service_id
		) AS aca
	WHERE ph.occ = @occ1
		AND ph.fin_id = @FinPred

	--IF @debug=1 select * from @paym_list1 where is_counter>0

	IF @payms_tip1 = 1 -- если начисляем по данному жилому фонду
		AND EXISTS (
			SELECT 1
			FROM @paym_list1
			WHERE is_counter > 0
		)  -- если есть счетчики
	BEGIN   -- Сохраняем информацию по счетчикам

		--IF @debug=1
		--begin
		--SELECT * FROM dbo.PAYM_COUNTER_ALL AS pc
		--	WHERE pc.occ=@occ1 AND pc.fin_id=@FinPeriodCurrent
		--SELECT t.occ,t.service_id,tarif=AVG(t.tarif),VALUE=SUM(t.VALUE),
		--	kol=SUM(COALESCE(t.kol,0)),avg_vday=sum(t.avg_vday) FROM @paym_list1 t
		--	where t.occ=@occ1 and t.is_counter>0
		--	GROUP BY t.occ,t.service_id
		--end	

		-- Обновляем информацию по существующим счетчикам
		MERGE dbo.Paym_counter_all AS pc USING (
			SELECT t.occ
				 , t.service_id
				 , AVG(t.tarif) AS tarif
				 , SUM(t.VALUE) AS VALUE
				 , SUM(COALESCE(t.kol, 0)) AS kol
				 , SUM(t.avg_vday) AS avg_vday
				 , MIN(COALESCE(aca.val, 0)) AS add_val
			FROM @paym_list1 t
				OUTER APPLY (
					SELECT SUM(t2.VALUE) AS val
					FROM dbo.Added_Counters_All AS t2 
					WHERE t2.occ = t.occ
						AND t2.fin_id = @fin_id1
						AND t2.service_id = t.service_id
				) AS aca
			WHERE t.occ = @occ1
				AND t.is_counter > 0
			GROUP BY t.occ
				   , t.service_id
		) AS p1
		ON p1.occ = pc.occ
			AND p1.service_id = pc.service_id
			AND pc.fin_id = @FinPeriodCurrent
		WHEN MATCHED
			THEN UPDATE
				SET pc.subsid_only = 0
				  , pc.tarif = p1.tarif
				  , pc.value = p1.value
				  , pc.discount = 0	 --coalesce(p1.discount,0),
				  , pc.added = COALESCE(add_val, 0)
				  , pc.Compens = 0
				  , pc.paid = p1.value + COALESCE(add_val, 0)
				  , pc.paymaccount = COALESCE((
						SELECT SUM(p2.value)
						FROM dbo.Payings AS p2 
						WHERE p2.occ = p1.occ
							AND p2.fin_id = @fin_id1
							AND p2.forwarded = cast(1 as bit)
							AND p2.service_id = p1.service_id
					), 0)
				  , pc.paymaccount_peny = 0
				  , pc.kol = p1.kol
				  , pc.avg_vday = p1.avg_vday
		WHEN NOT MATCHED
			-- Добавляем информацию по новым счетчикам
			THEN INSERT (fin_id
					   , occ
					   , service_id
					   , subsid_only
					   , tarif
					   , saldo
					   , value
					   , discount
					   , added
					   , Compens
					   , paid
					   , paymaccount
					   , paymaccount_peny
					   , kol)
				VALUES(@FinPeriodCurrent
					 , p1.occ
					 , p1.service_id
					 , 0
					 , p1.tarif
					 , 0 --saldo
					 , p1.value
					 , 0 --discount
					 , COALESCE(add_val, 0)
					 , 0
					 , p1.value + COALESCE(add_val, 0)
					 , COALESCE((
						   SELECT SUM(p2.value)    -- paymaccount
						   FROM dbo.Payings AS p2 
						   WHERE p2.occ = p1.occ
							   AND p2.fin_id = @fin_id1
							   AND p2.forwarded = 1
							   AND p2.service_id = p1.service_id
					   ), 0)
					 , 0 --paymaccount_peny
					 , p1.kol  --kol
				)
		;

		-- Очищаем начисления по внешним счетчикам
		UPDATE p1
		SET value = 0
		  , discount = 0
		  , added = COALESCE((
				SELECT SUM(t2.value)
				FROM dbo.Added_Payments AS t2 
				WHERE t2.occ = p1.occ
					AND t2.service_id = p1.service_id
					AND t2.sup_id = p1.sup_id
			), 0)
		  , paymaccount = 0
		  , paymaccount_peny = 0
		FROM @paym_list1 AS p1
		WHERE is_counter = 1
			-- и не заблокированны счетчики
			AND p1.service_id NOT IN (
				SELECT service_id
				FROM Fun_GetCounterBlocked(@occ1, @fin_id1)
			)

		-- удаляем начисления по норме у счетчиков которые заблокированны
		DELETE FROM dbo.Paym_counter_all
		WHERE occ = @occ1
			AND fin_id = @FinPeriodCurrent
			AND service_id IN (
				SELECT service_id
				FROM Fun_GetCounterBlocked(@occ1, @fin_id1)
			)

		--IF @debug=1 select * from @paym_list1 where is_counter>0
		--*********************************************************************

		-- Если счётчик внутренний
		-- 1. Если есть показания квартиросьемщика берем его в раcчет
		IF EXISTS (
				SELECT 1
				FROM dbo.View_counter_inspector_lite 
				WHERE fin_id = @fin_id1-- @FinPeriodCurrent
					AND occ = @occ1
					--AND tip_value=1
					AND
					(CASE
						WHEN @ras_no_counter_poverka = 1 THEN KolmesForPeriodCheck
						ELSE 0
					END) >= 0
			)
		BEGIN
			--IF @debug=1 select * from @paym_list1 where is_counter>0		
			SET @counter_metod = 3 -- метод расчета
			--IF @debug=1 print 'есть показания, @ras_no_counter_poverka= '+str(@ras_no_counter_poverka)
			UPDATE p1
			SET tarif = case when cnt_tarif>1 then p1.tarif else COALESCE(cp2.tarif, 0) end -- 29.06.23
			  , kol = COALESCE(cp2.kol, 0)
			  , kol_norma = case when (cnt_tarif>1 and cp2.value>0 AND p1.tarif>0) then cp2.value/p1.tarif else COALESCE(cp2.kol, 0) end  -- 29.06.23
			  , value = cp2.value
			  , discount = cp2.discount
			  , serv_unit = (
					SELECT TOP 1 cl.unit_id     -- получаем ед.измерения
					FROM #t_counter AS cl 
					WHERE cl.internal = 1
						AND cl.service_id = p1.service_id
				)
			  , metod = @counter_metod
			  , metod_old = @counter_metod
			FROM @paym_list1 AS p1
				JOIN (
					SELECT service_id
						 , CASE
							  WHEN (COUNT(TARIF) > 1 AND SUM(VALUE) > 0 AND SUM(kol) > 0) THEN SUM(VALUE) / SUM(kol)
							  WHEN (COUNT(TARIF) > 1) THEN 0
							  ELSE AVG(TARIF)		
						   END AS TARIF
						 , SUM(kol) AS kol
						 , SUM(VALUE) AS VALUE
						 , SUM(discount) AS discount
						 , COUNT(distinct TARIF) AS cnt_tarif
					FROM dbo.Counter_paym2 AS cp 
					WHERE cp.occ = @occ1
						AND cp.tip_value = 1  -- 25.10.2021
						AND cp.fin_id = @fin_id1-- @FinPeriodCurrent
						AND cp.kol_counter = cp.kol_inspector -- 10/10/17 чтобы по каждому ИПУ было показание
					GROUP BY service_id
				) AS cp2 ON p1.service_id = cp2.service_id
			WHERE p1.is_counter = 2 --  счетчик внутренний
				AND p1.counter_metod <> 6
				AND NOT (@is_summer_period=1 AND p1.service_id='отоп') -- в летний период по отоп не начисляем  06/07/23
				--and cp2.kol>0  -- кол-во может быть = 0	
				--AND NOT EXISTS(SELECT * FROM dbo.SERVICES_TYPE_COUNTERS AS st 
				--WHERE st.tip_id = @tip_id1 AND p1.service_id = st.service_id AND st.no_counter_raschet=1) -- Блокирую начисления где заблокирован расчёт по ПУ по услуге	

				AND EXISTS (
					SELECT *
					FROM (
						SELECT cla.occ
							 , COUNT(cla.counter_id) AS count_counter_id
							 , SUM(CASE WHEN ci.inspector_value IS NULL THEN 0 ELSE 1 END) AS count_inspector_value
						FROM dbo.Counter_list_all cla 
							JOIN dbo.Counters AS c ON 
								c.id = cla.counter_id
								--AND (c.date_del IS NULL)  -- 13.04.2022  OR c.date_del BETWEEN @Start_date AND @End_date)
							LEFT JOIN dbo.Counter_inspector ci ON 
								ci.counter_id = cla.counter_id
								AND ci.fin_id = cla.fin_id
						WHERE cla.fin_id = @fin_id1
							AND cla.occ = @occ1
							AND cla.service_id = p1.service_id
							AND (CASE
								WHEN @ras_no_counter_poverka = 1 THEN cla.KolmesForPeriodCheck
								ELSE 0
							END) >= 0
						GROUP BY cla.occ
					) AS t
					WHERE t.count_counter_id <= t.count_inspector_value   -- кол-во ПУ должно быть = кол-ву показаний по нему
				)   -- 18/12/2018
			--print @@rowcount

			-- **********************************************************************  14/07/2011
			IF @added = 0 -- только в текущем периоде
			BEGIN
				UPDATE pl
				SET tarif = p1.tarif
				  , kol = p1.kol
				  , metod = p1.metod
				  , metod_old = p1.metod_old
				FROM dbo.Paym_list pl
				JOIN @paym_list1 AS p1 ON p1.occ = pl.occ
						AND p1.service_id = pl.service_id
						AND p1.sup_id = pl.sup_id
						AND p1.is_counter = 2
						AND p1.counter_metod <> 6
				WHERE pl.fin_id = @fin_id1
					AND pl.occ = @occ1					

				EXEC dbo.ka_counter_norma3 @occ = @occ1
										 , @fin_current = @fin_id1 --, @debug=@debug

			END
		-- **********************************************************************
		END
		ELSE
			DELETE FROM dbo.Added_Payments
			WHERE occ = @occ1
				AND add_type = 12
				AND doc_no = '888'
				AND @added = 0 -- авт. кор. по внутр. счетчикам

		-- добавил 23.11.17	*************** изменяем метод в Counter_paym2 и показаниях Counter_inspector
		UPDATE cp2
		SET fin_paym = @FinPeriodCurrent
		  , metod_rasch = p1.metod
		FROM @paym_list1 AS p1
			JOIN dbo.Counter_paym2 AS cp2 ON 
				p1.occ = cp2.occ
				AND p1.serv_counter = cp2.service_id  -- заменил на serv_counter 23.11.17
		WHERE p1.is_counter = 2 --  счетчик внутренний
			AND cp2.occ = @occ1
			AND cp2.tip_value = 1
			AND cp2.fin_id = @FinPeriodCurrent
			AND (p1.tarif > 0 OR cp2.tarif > 0)	 --06.07.23  OR cp2.tarif > 0
			AND @added = 0

		UPDATE ci
		SET metod_rasch =
						 CASE
							 WHEN p1.metod IS NULL AND
								 ci.actual_value = 0 THEN 3
							 ELSE p1.metod
						 END
		FROM dbo.Counter_list_all cla 
			JOIN dbo.Counter_inspector AS ci 
				ON ci.counter_id = cla.counter_id
				AND ci.fin_id = cla.fin_id
			JOIN @paym_list1 AS p1 ON 
				p1.occ = cla.occ
				AND p1.serv_counter = cla.service_id
		WHERE cla.fin_id = @fin_id1
			AND cla.occ = @occ1
			AND (p1.tarif > 0 OR ci.tarif > 0) --06.07.23  OR ci.tarif > 0
	--********************************************************************

	--if @debug=1 select * from @paym_list1 where is_counter>0    
	--*********************************************************************

	END -- if exists(select * from @paym_list1 where is_counter>0)
	--if @debug=1 select * from @paym_list1 where service_id='хвод'
	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id IN ('гвод','гвс2','отоп','ото2')

	-- ************************************************
	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id IN ('гвод','гвс2','отоп','ото2')
	--if @debug=1 SELECT * FROM @paym_list1
	--*******************************************************************************************
	IF @build_sup_out = 1
	BEGIN
		--SELECT * FROM @paym_list1 WHERE service_id IN ('гвод','гвс2')
		UPDATE pl
		SET serv_unit = cl.serv_unit
		  , metod = cl.metod
		  , is_counter = COALESCE(cl.is_counter, 0)
		  , kol = COALESCE(cl.kol, 0)
		  , tarif = COALESCE(cl.tarif, 0)
		--,value=cl.value 
		FROM @paym_list1 AS pl
			JOIN (
				SELECT *
				FROM @paym_list1
				WHERE service_id = N'гвод'
			) AS cl ON 
				pl.occ = cl.occ
		WHERE pl.service_id = N'гвс2'
			AND pl.sup_id > 0
			AND (cl.kol > 0 OR cl.metod = 3)
		--AND pl.paym_blocked=0
		--SELECT * FROM @paym_list1 WHERE service_id IN ('гвод','гвс2')				

		UPDATE pl
		SET kol = COALESCE(cl.kol, 0)
		  , tarif = COALESCE(cl.tarif, 0)
		  , value = cl.value --coalesce(cl.kol,0)*coalesce(cl.tarif,0)
		FROM @paym_list1 AS pl
			JOIN (
				SELECT *
				FROM @paym_list1
				WHERE service_id = N'гвод'
			) AS cl ON pl.occ = cl.occ
		WHERE pl.service_id = N'гвс2'
			AND pl.sup_id > 0
			AND pl.is_counter > 0

		UPDATE pl
		SET value = 0
		  , kol = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'гвод'
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 AS p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'гвс2'
					AND p2.sup_id > 0
					AND p2.paym_blocked = 0
			)
		UPDATE pl
		SET value = 0
		  , kol = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'гвод'
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 AS p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'гвод'
					AND p2.sup_id <> pl.sup_id
					AND p2.paym_blocked = 0
					AND pl.paym_blocked = 1
			)
		UPDATE pl
		SET kol = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'гвс2'
			AND pl.kol > 0
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'гвод'
					AND p2.kol > 0
			)
		UPDATE pl
		SET account_one = 1
		  , sup_id = cl.sup_id  -- для общедомовая услуга по ГВС УКС
		FROM @paym_list1 AS pl
			JOIN (
				SELECT occ
					 , account_one
					 , sup_id
				FROM @paym_list1
				WHERE service_id = N'гвс2'
					AND sup_id > 0
			) AS cl ON pl.occ = cl.occ
				AND pl.sup_id = cl.sup_id
		WHERE pl.service_id = N'гв2д'

		--UPDATE cl
		--SET sup_id=pl.sup_id, account_one=pl.account_one
		--SELECT cl.*,pl.*
		--FROM @paym_list1 AS pl
		--JOIN dbo.CONSMODES_LIST AS cl ON pl.occ=cl.occ AND pl.service_id=cl.service_id
		--WHERE pl.service_id='гв2д'
		--AND cl.occ=@occ1

		--AND EXISTS(SELECT * FROM @paym_list1 WHERE occ=@occ1 AND service_id='гвс2' AND sup_id IS NOT NULL AND value>0)
		--SELECT * FROM @paym_list1 WHERE occ=@occ1 AND service_id IN ('гвсд','гвс2')	
		-- ************** ОТОПЛЕНИЕ ************************		
		UPDATE pl
		SET serv_unit = cl.serv_unit
		  , metod = cl.metod
		  , is_counter = COALESCE(cl.is_counter, 0)
		  , kol = COALESCE(cl.kol, 0)
		  , tarif = COALESCE(cl.tarif, 0)
		  , value = cl.value  --coalesce(cl.kol,0)*coalesce(cl.tarif,0)
		FROM @paym_list1 AS pl
			JOIN (
				SELECT *
				FROM @paym_list1
				WHERE service_id = N'отоп'
			) AS cl ON pl.occ = cl.occ
		WHERE pl.service_id = N'ото2'
			AND pl.sup_id > 0
			AND (cl.kol > 0 OR cl.metod = 3)

		UPDATE pl
		SET value = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'отоп'
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'ото2'
					AND p2.sup_id > 0
					AND p2.paym_blocked = 0
			)
		--**************************************************************************
		UPDATE pl
		SET serv_unit = cl.serv_unit
		  , metod = cl.metod
		  , is_counter = COALESCE(cl.is_counter, 0)
		  , kol = COALESCE(cl.kol, 0)
		  , tarif = COALESCE(cl.tarif, 0)
		  , value = cl.value --coalesce(cl.kol,0)*coalesce(cl.tarif,0)
		FROM @paym_list1 AS pl
			JOIN (
				SELECT *
				FROM @paym_list1
				WHERE service_id = N'хвод'
			) AS cl ON pl.occ = cl.occ
		WHERE pl.service_id = N'хвс2'
			AND pl.sup_id > 0
			AND (cl.kol > 0 OR cl.metod = 3) -- по счетчику кол-во может быть равно 0

		UPDATE pl
		SET value = 0
		  , kol = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'хвод'
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'хвс2'
					AND p2.sup_id > 0
					AND p2.paym_blocked = 0
			)
		UPDATE pl
		SET kol = 0
		FROM @paym_list1 AS pl
		WHERE pl.service_id = N'хвс2'
			AND pl.kol > 0
			AND EXISTS (
				SELECT 1
				FROM @paym_list1 p2
				WHERE p2.occ = @occ1
					AND p2.service_id = N'хвод'
					AND p2.kol > 0
			)
	END
	--*******************************************************************************************
	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id IN ('хвод','гвод','гвс2','отоп','ото2')

	-- сохраняем метод расчёта
	UPDATE pl
	SET metod_old = metod
	FROM @paym_list1 AS pl
	WHERE metod_old IS NULL

	--if @debug=1 SELECT * FROM @paym_list1 --WHERE service_id='гГВС'	
	--************* метод расчёта по дому **************
	UPDATE pl
	SET value = pcb.value
	  , metod = 4
	  , kol = pcb.kol
	  , kol_norma = COALESCE(pcb.kol_old,0)  -- сохраняем расчитанный объём
	  , tarif = pcb.tarif
	  , serv_unit = coalesce(pcb.unit_id, serv_unit)
	FROM @paym_list1 AS pl
		JOIN dbo.Paym_occ_build AS pcb 
			ON pcb.fin_id = @fin_id1
			AND pl.occ = pcb.occ
			AND pl.service_id = pcb.service_id
	WHERE (pcb.tarif > 0) OR (pcb.kol<>0) -- 24.10.23  + OR (pcb.kol<>0)

	--if @debug=1 SELECT * FROM @paym_list1 --WHERE service_id='гГВС'

	-- не всегда по домовому удаётся вычислить тариф и кол-во
	UPDATE pl
	SET value = pcb.value
	  , metod = 4
	  , kol =
			 CASE
				 WHEN pl.tarif > 0 THEN pcb.value / pl.tarif
				 ELSE 0
			 END
	  , serv_unit = coalesce(pcb.unit_id, serv_unit)
	FROM @paym_list1 AS pl
		JOIN dbo.Paym_occ_build AS pcb 
			ON pcb.fin_id = @fin_id1
			AND pl.occ = pcb.occ
			AND pl.service_id = pcb.service_id
	WHERE (pcb.tarif=0) AND (pcb.kol=0) AND (pl.tarif>0) AND (pl.kol=0)  -- 24.10.23

	--if @debug=1 SELECT * FROM @paym_list1 --WHERE service_id='гГВС'	
	--******************************** Очищаем услуги по которым расчёт заблокирован
	UPDATE p1
	SET value = 0 --, kol=0
	FROM @paym_list1 AS p1
	WHERE p1.paym_blocked = 1

	--******************************** ВОДООТВЕДЕНИЕ ***************************************
	--if @debug=1 SELECT * FROM @paym_list1 WHERE paym_blocked=1
	--if @debug=1 SELECT * FROM @paym_list1 WHERE metod<>4
	--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')

	IF EXISTS (
			SELECT 1
			FROM @paym_list1
			WHERE (is_counter > 0 OR serv_unit = N'кубм')
				AND service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
		)
		OR (@status1 = N'своб') -- в своб квартирах норматива нет поэтому надо суммировать
	--AND (dbo.Fun_GetCounterBlockedServ(@flat_id1)='') -- услуга где нет действующего ИПУ
	--AND NOT EXISTS(SELECT * FROM @paym_list1 WHERE metod=4 
	--AND service_id IN ('вотв','вот2','канд','во2д')) -- по водоотведению есть общедомовые  06/05/13
	BEGIN
		-- Расчет за Водоотвод обнулять или нет? 
		-- когда Счетчик только на гор. или хол воду

		DECLARE @ras_votv1 BIT  -- гор.вода
			  , @ras_votv2 BIT  -- хол.вода

		-- начальное значение считать за водотведение
		SELECT @ras_votv1 = 1
			 , @ras_votv2 = 1

		-- если есть счетчик по гор.воде или режим = нет
		IF EXISTS (
				SELECT 1
				FROM #services1
				WHERE id = N'гвод'
					AND is_counter > 0
			)
			-- если режима нет то и строки в таблице #services1 тоже нет!!!
			OR NOT EXISTS (
				SELECT 1
				FROM #services1
				WHERE id = N'гвод'
			)
			OR EXISTS (
				SELECT 1
				FROM #services1
				WHERE id IN (N'гвод')
					AND unit_id = N'кубм'
			)
			SELECT @ras_votv1 = 0  -- то не считаем

		-- если есть счетчик по хол.воде или режим = нет
		IF EXISTS (
				SELECT 1
				FROM #services1
				WHERE id = N'хвод'
					AND is_counter > 0
			)
			OR NOT EXISTS (
				SELECT 1
				FROM #services1
				WHERE id = N'хвод'
			)
			OR EXISTS (
				SELECT 1
				FROM #services1
				WHERE id IN (N'хвод')
					AND unit_id = N'кубм'
			)
			SELECT @ras_votv2 = 0

		IF EXISTS (
				SELECT 1
				FROM #services1
				WHERE id = N'вот2'
					AND (source_id % 1000 != 0)
			)
			SELECT @ras_votv1 = 0
				 , @ras_votv2 = 0

		-- если в доме нет водоотведения то не считать
		IF @counter_votv_ras1 = 1
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Build_mode AS b 
				WHERE b.build_id = @build_id1
					AND b.service_id IN (N'вотв', N'вот2')
					AND (mode_id % 1000) != 0
			)
			SET @counter_votv_ras1 = 0

		--if @debug=1 print @counter_votv_ras1
		--if @debug=1 print @counter_votv_norma
		IF @counter_votv_norma = 1
			AND NOT EXISTS (
				SELECT 1
				FROM @paym_list1
				WHERE is_counter > 0
					AND service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
			)
			SELECT @ras_votv1 = 1

		IF (@ras_votv1 = 0)
			AND (@ras_votv2 = 0)
			UPDATE @paym_list1  -- обнуляем водоотведение
			SET value = 0
			  , discount = 0
			WHERE service_id IN (N'вотв', N'вот2')
				AND COALESCE(metod, 1) <> 4

		--if @debug=1 select * from #services1	
		--   if @debug=1 print @counter_votv_ras1
		--if @debug=1 print @ras_votv1
		--if @debug=1 print @ras_votv2
		--if @debug=1 select * from @paym_list1 WHERE service_id='вотв' 

		SELECT @serv_unit1 = (
				SELECT TOP 1 serv_unit
				FROM @paym_list1
				WHERE service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
					AND serv_unit <> ''
			)
		SELECT @tar1 =
					  CASE
						  WHEN tarif = 0 THEN dbo.Fun_GetCounterTarfServ(@fin_id1, @occ1, N'вотв', @serv_unit1)
						  ELSE tarif
					  END
		FROM @paym_list1
		WHERE service_id = N'вотв'

		--if @debug=1 PRINT @tar1
		--if @debug=1 PRINT @serv_unit1
		--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')

		IF @counter_votv_ras1 = 1
			AND (@ras_votv1 = 0)
			AND (@ras_votv2 = 0)
		BEGIN
			--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id IN ('хвод','хвс2','гвод','гвс2') AND serv_unit='кубм'

			SELECT @kol = COALESCE(SUM(COALESCE(kol, 0)), 0)
				 , @kol_norma = COALESCE(SUM(COALESCE(kol_norma, 0)), 0)
			FROM @paym_list1
			WHERE service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
				AND serv_unit = N'кубм'
				AND (value <> 0 OR (paym_blocked = 1 AND @counter_votv_norma = 1))

			-- --Водоотведение по домовому не должно быть меньше нормы
			--IF @Db_Name='KR1' --AND @tip_id1=68
			--	SELECT @kol=coalesce(SUM(
			--	CASE WHEN metod=4 THEN coalesce(kol_norma,0) ELSE coalesce(kol,0)
			--	END
			--	),0) 
			--	FROM @paym_list1 
			--	WHERE service_id IN ('хвод','хвс2','гвод','гвс2') 
			--	AND serv_unit='кубм'

			--if @debug=1 print @kol
			--print @tar1
			--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')

			IF @kol < 0
			BEGIN -- считаем, что были поданы в прошлый раз ошибочные показания
				-- берём последний тариф рассчитанный по счетчикам
				SELECT TOP (1) @tar1 = ph.tarif
				FROM dbo.Paym_history ph 
				WHERE occ = @occ1
					AND ph.service_id IN (N'вотв', N'вот2')
					AND ph.metod = 3
				ORDER BY ph.fin_id DESC
			END

			UPDATE @paym_list1  -- расчитываем водоотведение
			SET kol = COALESCE(@kol, 0)
			  , kol_norma = COALESCE(@kol_norma, 0)
			  , tarif = @tar1
			  , serv_unit = @serv_unit1
			  , value = @kol * @tar1
			  , metod = (
					SELECT TOP 1 metod
					FROM @paym_list1
					WHERE service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
						AND metod IS NOT NULL
					ORDER BY metod DESC
				)
			WHERE service_id IN (N'вотв')
				AND COALESCE(metod, 1) <> 4

			--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')

			UPDATE @paym_list1  -- если за воду нет расчёта по счётчикам ставим метод расчёта по норме
			SET metod = 1
			WHERE service_id = N'вотв'
				AND COALESCE(metod, 1) <> 4
				AND NOT EXISTS (
					SELECT 1
					FROM @paym_list1
					WHERE service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
						AND metod IN (2, 3, 4)
				)

			--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')		
			UPDATE pl
			SET kol = pl2.kol
			  , value = pl2.kol * pl.tarif
			  , -- pl.tarif,
				metod = pl2.metod
			  , serv_unit = @serv_unit1
			FROM @paym_list1 AS pl
				JOIN (
					SELECT *
					FROM @paym_list1 AS t
					WHERE t.service_id = N'вотв'
				) AS pl2 ON pl.occ = pl2.occ
			WHERE pl.service_id = N'вот2'  -- водоотведение УКС, ижводоканал
				AND pl2.kol <> 0
				AND pl.tarif > 0
				AND COALESCE(pl.metod, 1) <> 4
			--AND EXISTS(SELECT 1 FROM @paym_list1 WHERE service_id IN ('хвс2','гвс2') AND value>0)  25.03.14 закоментировал

			IF EXISTS (
					SELECT 1
					FROM @paym_list1 AS t
					WHERE t.service_id = N'вот2'
						AND t.value <> 0
				)
				UPDATE pl
				SET value = 0
				  , metod = NULL
				FROM @paym_list1 AS pl
				WHERE pl.service_id = N'вотв'

			IF EXISTS (
					SELECT 1
					FROM @paym_list1 AS t
					WHERE service_id IN (N'вот2')
						AND t.tarif > 0
				)
				SET @service_house_votv = N'во2д'  -- общедомовая услуга по водоотведению
		END

		--if @debug=1 SELECT * FROM @paym_list1 AS pl --WHERE service_id IN ('вотв','вот2')

		--IF EXISTS
		--(SELECT * FROM @paym_list1 WHERE (is_counter=0 AND serv_unit='кубм') 
		--AND service_id IN ('хвод','хвс2','гвод','гвс2'))
		--BEGIN
		UPDATE t
		--SET kol=COALESCE(kol,0)+COALESCE((SELECT SUM(kol) FROM @paym_list1 as t2 
		SET kol = COALESCE((
			SELECT SUM(kol)
			FROM @paym_list1 AS t2
			WHERE service_id IN (N'хвпк', N'гвпк')
				AND kol > 0
		), 0)
		FROM @paym_list1 AS t
		WHERE service_id IN (N'вопк')--,'впк2') --IN ('вотв','вот2')
			AND t.tarif > 0

		UPDATE t
		SET value = kol * tarif
		  , kol_norma = COALESCE(kol, 0)
		FROM @paym_list1 AS t
		WHERE service_id IN (N'вопк')--,'впк2') --='вопк' -- IN ('вотв','вот2')
			AND t.tarif > 0
		--END

		IF EXISTS (
				SELECT 1
				FROM @paym_list1 AS t
				WHERE t.service_id = N'хпк2'
					AND t.value > 0
			)
			UPDATE pl
			SET value = 0
			  , metod = NULL
			FROM @paym_list1 AS pl
			WHERE pl.service_id = N'хвпк'
		IF EXISTS (
				SELECT 1
				FROM @paym_list1 AS t
				WHERE t.service_id = N'впк2'
					AND t.value > 0
			)
			UPDATE pl
			SET value = 0
			  , metod = NULL
			FROM @paym_list1 AS pl
			WHERE pl.service_id = N'вопк'

		--if @debug=1 SELECT * FROM @paym_list1 AS pl WHERE service_id IN ('вотв','вот2')

		IF @fin_id1 < 137
			AND -- Расчёт общедомового водоотведения только до 01.06.2013 (@fin_id1=137)
			EXISTS (
				SELECT 1
				FROM @paym_list1 AS pl
				WHERE service_id IN (N'гвсд', N'хвсд', N'гв2д', N'хв2д')
			)
		BEGIN
			-- Расчёт общедомового водоотведения *************************
			SELECT @kol = COALESCE(SUM(COALESCE(kol, 0)), 0)
			FROM @paym_list1
			WHERE service_id IN (N'гвсд', N'хвсд', N'гв2д', N'хв2д')
				AND serv_unit = N'кубм';
			--PRINT @kol
			--PRINT @service_house_votv

			IF NOT EXISTS (
					SELECT 1
					FROM @paym_list1
					WHERE service_id = @service_house_votv
						AND COALESCE(metod, 1) = 4
				)
				-- т.е. если уже небыло сумм по общедомовому расчёту  28/12/2012
				AND NOT EXISTS (
					SELECT 1
					FROM dbo.Paym_occ_build pob 
					WHERE fin_id = @fin_id1
						AND occ = @occ1
						AND service_id IN (N'вотв', N'вот2')
				--AND coalesce(metod,1)=4
				)
			BEGIN
				MERGE @paym_list1 AS p USING (
					SELECT occ = @occ1
						 , service_id = @service_house_votv
						 , kol = COALESCE(@kol, 0)
						 , value = @tar1 * COALESCE(@kol, 0)
				) AS p1
				ON p.occ = p1.occ
					AND p.service_id = p1.service_id
				WHEN MATCHED
					THEN UPDATE
						SET p.tarif = @tar1
						  , p.kol =
								   CASE
									   WHEN p1.value = 0 THEN 0
									   ELSE p1.kol
								   END
						  , p.value = p1.value
						  , serv_unit = @serv_unit1
						  , metod = 4
				WHEN NOT MATCHED
					THEN INSERT (occ
							   , service_id
							   , tarif
							   , kol
							   , value
							   , serv_unit
							   , metod)
						VALUES(p1.occ
							 , p1.service_id
							 , @tar1
							 , CASE
								   WHEN p1.value = 0 THEN 0
								   ELSE p1.kol
							   END
							 , p1.value
							 , @serv_unit1
							 , 4);
			END
		END

	END --if exists(SELECT * FROM @paym_list1 WHERE is_counter>0)

	-- Расчет Водоотведения по СОИ (одвж)
	-- если надо суммировать по ХВС СОИ(одхж) и ГВС СОИ (одгж)
	IF (@soi_metod_calc = 'CALC_KOL')
		AND (@soi_votv_fact = 1)
		AND EXISTS (
			SELECT 1
			FROM @paym_list1
			WHERE service_id = 'одвж'
				AND tarif > 0
		)
	BEGIN
		--if @debug=1 SELECT @soi_metod_calc as soi_metod_calc,@soi_votv_fact as soi_votv_fact, * FROM @paym_list1 WHERE service_id='одвж'

		SELECT @kol = COALESCE(SUM(COALESCE(kol, 0)), 0)
		FROM @paym_list1
		WHERE service_id IN ('одхж', 'одгж')
			AND tarif > 0

		--if @debug=1 print @kol

		UPDATE pl
		SET kol = @kol
		  , value = pl.tarif * @kol
		FROM @paym_list1 AS pl
		WHERE pl.service_id = 'одвж'

		--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id='одвж'
	END

	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id='канд'
	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id='площ'
	--if @debug=1 select * from @paym_list1 WHERE service_id='вотв'
	--if @debug=1 SELECT * FROM @paym_list1 --WHERE paym_blocked=1
	-- ещё раз обнуляем для водоотведения
	UPDATE p1
	SET value = 0
	FROM @paym_list1 AS p1
	WHERE p1.paym_blocked = 1

	--*****************************************************************************

	IF @LgotaRas1 = 0 -- расчет льготы не ведется
		UPDATE @paym_list1
		SET discount = 0
		WHERE discount > 0

	--if @debug=1 SELECT * FROM @paym_list1 WHERE service_id='тепл'
	--******************************************************************************
	-- для расчёта услуг на основе других услуг 
	-- 2-х компонентный тариф
	DECLARE @metod SMALLINT
		  , @metod_old SMALLINT
		  , @is_counter SMALLINT

	DECLARE cur CURSOR LOCAL FOR
		SELECT pl.service_id
			 , pl.counter_metod_service_kol
			 , pl.normaSingle
			 , pl.sup_id
			 , pl.serv_unit
			 , pl.mode_id
		FROM @paym_list1 pl
		WHERE pl.counter_metod = 5
			AND pl.counter_metod_service_kol <> ''
			AND COALESCE(pl.metod, 0) <> 4 -- чтобы не был уже расчитан по ОПУ
			AND pl.paym_blocked = 0
			AND NOT (pl.service_id IN ('одтж') AND @is_boiler=1) -- ТЭдля ГВ на сод.о.и* там где есть бойлер считать по другому 25.10.23

	OPEN cur;
	FETCH NEXT FROM cur INTO @serv1, @counter_metod_service_kol, @NormaSingle, @sup_id, @serv_unit1, @mode1

	WHILE @@fetch_status = 0
	BEGIN
		SELECT @NormaSingle =
							 CASE
								 WHEN @norma_gaz_otop > 0 THEN @norma_gaz_otop
								 WHEN @norma_gaz_gvs > 0 THEN @norma_gaz_gvs
								 WHEN @norma_gkal_gvs > 0 THEN @norma_gkal_gvs
								 WHEN @norma_gkal > 0 THEN @norma_gkal  -- 14/02/2020
								 ELSE 0
							 END

		--IF @debug=1 SELECT @norma_gaz_otop as norma_gaz_otop, @norma_gaz_gvs as norma_gaz_gvs, @norma_gkal_gvs as norma_gkal_gvs, @norma_gkal as norma_gkal

		IF @serv1='одтж' AND @norma_gkal_gvs=0
			SELECT @NormaSingle=dbo.Fun_GetNormaSingle(@serv_unit1, @mode1, 0, @tip_id1, @fin_id1)

		SELECT @kol = COALESCE(pl.kol, 0)
			 , @metod = pl.metod
			 , @metod_old = pl.metod_old
			 , @is_counter = pl.is_counter
			 , @koefDayRas = CASE
                                 WHEN COALESCE(pl.metod, 1) = 1 THEN COALESCE(pl.koef_day, 1)
                                 ELSE 1
            END -- если по нормативу - то используем коэф.дней 21.07.22
		FROM @paym_list1 pl
		WHERE pl.occ = @occ1
			AND pl.service_id = @counter_metod_service_kol
			AND pl.sup_id = @sup_id

		--IF @debug=1 SELECT @serv1,@kol AS kol,@NormaSingle as NormaSingle, @norma_gkal_gvs as norma_gkal_gvs
		SELECT @kol = @kol * @NormaSingle -- * @koefDayRas  -- основная услуга уже расчитана с коэф. закомен. 22.08.22

		IF @kol < 0
		BEGIN -- считаем, что были поданы в прошлый раз ошибочные показания
			-- берём последний тариф рассчитанный по счетчикам
			SELECT TOP (1) @tar1 = ph.tarif
			FROM dbo.Paym_history ph 
			WHERE occ = @occ1
				AND ph.service_id = @serv1
				AND ph.metod = 3
			ORDER BY ph.fin_id DESC
		END
		--IF @debug=1 SELECT @serv1,@kol AS kol,@NormaSingle AS NormaSingle,@counter_metod_service_kol AS counter_metod_service_kol, @is_counter as is_counter

		UPDATE pl
		SET value = CASE
                        WHEN @kol < 0 AND @tar1 > 0 THEN @tar1
                        ELSE pl.tarif
                        END * @kol
		  , tarif = CASE
                        WHEN @kol < 0 AND @tar1 > 0 THEN @tar1
                        ELSE pl.tarif
            END
		  , kol = @kol
		  , kol_norma = COALESCE(@kol, 0)
		  , normaSingle = @NormaSingle
		  , metod = @metod
		  , metod_old = @metod_old
		--,is_counter		= @is_counter
		FROM @paym_list1 pl
		WHERE pl.occ = @occ1
			AND pl.service_id = @serv1
			AND pl.sup_id = @sup_id

		FETCH NEXT FROM cur INTO @serv1, @counter_metod_service_kol, @NormaSingle, @sup_id, @serv_unit1, @mode1
	END

	CLOSE cur;
	DEALLOCATE cur;
	--******************************************************************************
	--if @debug=1 SELECT * FROM @paym_list1 --WHERE service_id='тепл'

LABEL_END_RASCHET:

	-- закидываем услугу пени (если есть)
	MERGE INTO @paym_list1 AS Target USING (
		SELECT *
		FROM dbo.Paym_list
		WHERE occ = @occ1
			AND fin_id = @fin_id1
			AND service_id = N'пени'
	) AS Source
	ON Target.occ = Source.occ
		AND Target.service_id = Source.service_id
		AND Target.sup_id = Source.sup_id
	WHEN MATCHED
		THEN UPDATE
			SET saldo = Source.saldo
			  , value = Source.value
			  , added = Source.added
	WHEN NOT MATCHED BY Target
		THEN INSERT (occ
				   , service_id
				   , sup_id
				   , saldo
				   , value
				   , added
				   , paymaccount
				   , paymaccount_peny)
			VALUES(Source.occ
				 , Source.service_id
				 , Source.sup_id
				 , Source.saldo
				 , Source.value
				 , Source.added
				 , Source.paymaccount
				 , Source.paymaccount_peny)
	;

	UPDATE p
	SET value = ROUND(p.value, @decimal_round)
	FROM @paym_list1 AS p

	-- *****************  ПЕРЕРАСЧЕТЫ  *************************************************
	-- Рассчитаем объем разовых (количество)
	--if @debug=1 select * from dbo.Added_payments where occ=@occ1 and kol=0

	UPDATE ap
	SET kol = CASE
                  WHEN p.tarif <= 0 THEN ap.kol
                  ELSE (ap.value / tarif)
        END
	FROM dbo.Added_Payments AS ap
		JOIN @paym_list1 AS p ON p.occ = ap.occ
			AND p.service_id = ap.service_id
			AND p.sup_id = ap.sup_id
		JOIN dbo.Services AS s ON s.id = ap.service_id
	WHERE ap.occ = @occ1
		AND COALESCE(ap.kol, 0) = 0
		AND s.service_type = 2

	--где блокировка разовых - убираем сумму разовых 
	UPDATE ap
	SET value = 0
	FROM dbo.Added_Payments AS ap
		JOIN @paym_list1 AS p ON p.occ = ap.occ
			AND p.service_id = ap.service_id
			AND p.sup_id = ap.sup_id
	WHERE ap.occ = @occ1
		AND p.add_blocked = CAST(1 AS BIT)

	--if @debug=1 select * from dbo.Added_payments where occ=@occ1

	--- 22/05/2006 Субсидии в банк то разовые по субсидиям в квитанцию не должны попасть
	UPDATE p
	SET kol_norma = CASE
                        WHEN p.metod not in (3,4) THEN p.kol  -- 29.06.23 добавил метод 3 (там вычисления сделал)
                        ELSE kol_norma
        END -- если метод домовой то оставляем расчётный объём
	  , added = COALESCE(ap.value, 0)
	  , kol_added = COALESCE(ap.kol, 0)
	FROM @paym_list1 AS p
		OUTER APPLY (
			SELECT SUM(p2.value) AS value
				 , SUM(COALESCE(p2.kol, 0)) AS kol
			FROM dbo.Added_Payments AS p2
			WHERE p2.occ = @occ1
				AND p2.service_id = p.service_id
				AND p2.sup_id = p.sup_id
				AND p2.add_type <> 4  -- кроме возврата по субсидиям
				AND p2.fin_id = @FinPeriod
		) AS ap
	--if @debug=1 select * from @paym_list1
	
	-- Расчет по проценту ***********************************************
	--SELECT * FROM @paym_list1 WHERE serv_unit='проц' AND tarif<>0 AND service_id NOT IN ('цеся','клек')
	--SELECT service_id, paid FROM @paym_list1 WHERE serv_unit<>'проц' and paid<>0
	--SELECT SUM(paid) FROM @paym_list1 WHERE serv_unit<>'проц'

	SELECT @val_tmp=SUM(value + added) FROM @paym_list1	WHERE serv_unit <> 'проц'
	IF @val_tmp<0 
		SET @val_tmp=0
	UPDATE p1
	SET value = tarif * @val_tmp * 0.01
	FROM @paym_list1 AS p1
	WHERE serv_unit = 'проц'
		AND tarif <> 0
		AND service_id NOT IN ('цеся', 'клек')
	--SELECT * FROM @paym_list1 WHERE serv_unit='проц' AND tarif<>0 AND service_id NOT IN ('цеся','клек')
	--******************************************************************************

	IF @added = 0  -- если расчет в текущем фин.периоде
	BEGIN

		IF @ras_subsid_only1 = 1
			UPDATE p1
			SET saldo = 0
			  , paymaccount = 0
			  , paymaccount_peny = 0
			FROM @paym_list1 AS p1;

		-- заносим информацию по льготам
		--******************************************************************************
		--DELETE FROM dbo.PAYM_LGOTA_ALL WHERE occ=@occ1 AND fin_id=@fin_id1

		--INSERT INTO dbo.PAYM_LGOTA_ALL (fin_id, occ,owner_id, service_id, lgota_id, lgotaAll, discount, subsid_only,
		--  Snorm, owner_lgota, is_counter)
		--SELECT @fin_id1, @occ1, p.owner_id, p.service_id, p.lgota_id, p.lgotaAll, p.discount, p1.subsid_only,
		--  coalesce(Snorm,0), owner_lgota, p1.is_counter   
		--FROM #people2 AS p
		--   JOIN @paym_list1 AS p1 ON p.service_id=p1.service_id
		----WHERE p.discount>0 

		-- Если режим "Нет" - убираем начисления
		--IF @debug=1 SELECT * FROM  @paym_list1
		--SELECT *
		UPDATE pl
		SET kol = 0
		  , value = 0
		FROM @paym_list1 pl
			JOIN dbo.Services S 
				ON pl.service_id = S.id
		WHERE ((mode_id % 1000) = 0 OR (source_id % 1000) = 0)
			AND pl.value > 0
			AND pl.metod <> 4  -- 24.10.23
			AND S.is_build = 0 -- услуга не общедомовая

		--if @debug=1 select * from @paym_list1
		UPDATE @paym_list1
		SET value = CASE
                        WHEN occ_sup = 0 THEN 0
                        ELSE value
            END
		  , kol =
				 CASE
					 WHEN value = 0 AND
						 kol > 0 AND
						 paym_blocked = 0 AND
						 COALESCE(metod, 0) <> 3 THEN 0
					 ELSE kol
				 END
		  , metod_old = CASE
                            WHEN metod_old IS NULL AND metod <> 4 THEN metod
                            ELSE metod_old
            END					   
		  , account_one = CASE
                              WHEN sup_id > 0 THEN 1
                              ELSE account_one
            END

		--UPDATE @paym_list1 SET value=0 WHERE occ_sup=0
		--UPDATE @paym_list1 SET kol=0 WHERE VALUE=0 AND kol>0 AND paym_blocked=0
		--UPDATE @paym_list1 SET metod_old=metod WHERE metod_old IS NULL AND metod IS NOT null

		--******************************************
		UPDATE @paym_list1
		SET paid =
				  CASE
					  WHEN service_id IN (N'цеся', N'клек') THEN added
					  ELSE ([value] - discount + added)
				  END
		WHERE occ = @occ1

		--WHERE service_id not in ('цеся','клек')
		---- 15/04/2013
		--UPDATE @paym_list1 
		--SET paid=added
		--WHERE service_id in ('цеся','клек')	
		--******************************************

		--if @debug=1 select * from @paym_list1
		--if @debug=1 select * from paym_list WHERE occ=@occ1
		--SELECT * FROM @paym_list1 WHERE service_id='гвс2'		
		--Соединяем временный файл @paym_list1 с основным paym_list

		--DELETE p
		--FROM dbo.paym_list AS p
		--WHERE p.occ=@occ1

		--INSERT INTO dbo.paym_list	
		--(occ,
		--	   service_id,
		--	   subsid_only,
		--	   account_one,
		--	   tarif,
		--	   koef,
		--	   kol,
		--	   saldo,
		--	   VALUE,
		--	   added,
		--	   paymaccount,
		--	   paymaccount_peny,
		--	   paid,
		--	   unit_id,
		--	   metod,
		--	   is_counter,
		--	   fin_id,
		--	   kol_norma,
		--	   metod_old,
		--	   sup_id,
		--	   build_id
		--	   )             
		--SELECT p1.occ,
		--	   p1.service_id,
		--	   p1.subsid_only,
		--	   p1.account_one,
		--	   p1.tarif,
		--	   p1.koef,
		--	   CASE WHEN p1.value=0 THEN 0 ELSE p1.kol END,
		--	   p1.kol,
		--	   p1.saldo,
		--	   p1.value,
		--	   p1.added,
		--	   p1.paymaccount,
		--	   p1.paymaccount_peny,
		--	   p1.paid,
		--	   p1.serv_unit,
		--	   p1.metod,
		--	   p1.is_counter,
		--	   @FinPeriodCurrent,
		--	   kol_norma,
		--	   p1.metod_old,
		--	   p1.sup_id,
		--	   @build_id1
		--FROM @paym_list1 AS p1

		MERGE dbo.Paym_list AS p USING @paym_list1 AS p1
		ON p.occ = p1.occ
			AND p.service_id = p1.service_id
			AND p.sup_id = p1.sup_id
			AND p.fin_id=@FinPeriodCurrent
		WHEN MATCHED
			THEN UPDATE
				SET p.subsid_only = p1.subsid_only
				  , p.account_one = p1.account_one
				  , p.tarif = p1.tarif
				  , p.koef = p1.koef
				  ,
					--p.kol=CASE WHEN p1.value=0 THEN NULL ELSE p1.kol END,
					p.kol = p1.kol
				  , p.saldo = ROUND(p1.saldo, @decimal_round)
				  , p.value = ROUND(p1.value, CASE
                                                  WHEN p1.sup_id > 0 THEN 2
                                                  ELSE @decimal_round
                    END)
				  , p.added = ROUND(p1.added, @decimal_round)
				  , p.paymaccount = ROUND(p1.paymaccount, @decimal_round)
				  , p.paymaccount_peny = ROUND(p1.paymaccount_peny, @decimal_round)
				  , p.paid = ROUND(p1.paid, CASE
                                                WHEN p1.sup_id > 0 THEN 2
                                                ELSE @decimal_round
                    END)
				  , p.unit_id = p1.serv_unit
				  , p.metod = p1.metod
				  , p.is_counter = p1.is_counter
				  , p.fin_id = @FinPeriodCurrent
				  ,
					--p.source_id=p1.source_id,
					p.kol_norma = p1.kol_norma
				  , p.metod_old = p1.metod_old
				  , p.sup_id = p1.sup_id
				  , p.build_id = @build_id1
				  , p.kol_norma_single = p1.normaSingle
				  , p.kol_added = p1.kol_added
				  , p.source_id = p1.source_id
				  , p.mode_id = p1.mode_id
				  , p.date_start = CASE
                                       WHEN p1.date_ras_start <> @Start_date THEN p1.date_ras_start
                                       ELSE NULL
                    END
				  , p.date_end = CASE
                                     WHEN p1.date_ras_end <> @End_date THEN p1.date_ras_end
                                     ELSE NULL
                    END
				  , p.koef_day = p1.koef_day
				  , p.occ_sup_paym =
									CASE
										WHEN p1.occ_sup IS NOT NULL THEN p1.occ_sup
										WHEN p1.occ_sup IS NULL AND
											p1.sup_id = 0 THEN p1.occ
										WHEN p1.occ_sup IS NULL AND
											p1.sup_id > 0 THEN dbo.Fun_GetOccSUP(p1.occ, p1.sup_id, p1.dog_int)
										ELSE p1.occ
									END
				  , p.penalty_prev = p1.penalty_prev
		WHEN NOT MATCHED
			AND (p1.value > 0 OR p1.kol <> 0 OR p1.saldo <> 0 OR p1.penalty_prev <> 0 OR p1.paid <> 0 OR @penalty_value1 <> 0 OR @penalty_added1 <> 0 OR @penalty_old_new1 <> 0 OR (p1.source_id % 1000 <> 0) -- есть поставщик
			OR p1.sup_id > 0 OR p1.tarif <> 0 OR p1.penalty_prev <> 0)	 -- у хвс,гвс value может быть 0, а общедомовые есть (для квитанции нужна строка) 
			THEN INSERT (occ
					   , service_id
					   , subsid_only
					   , account_one
					   , tarif
					   , koef
					   , kol
					   , saldo
					   , value
					   , added
					   , paymaccount
					   , paymaccount_peny
					   , paid
					   , unit_id
					   , metod
					   , is_counter
					   , fin_id
					   , kol_norma
					   , metod_old
					   , sup_id
					   , build_id
					   , kol_norma_single
					   , source_id
					   , mode_id
					   , occ_sup_paym
					   , date_start
					   , date_end
					   , kol_added
					   , koef_day
					   , penalty_prev)
				VALUES(p1.occ
					 , p1.service_id
					 , p1.subsid_only
					 , p1.account_one
					 , p1.tarif
					 , p1.koef
					 ,
					   --CASE WHEN p1.value=0 THEN 0 ELSE p1.kol END,
                       p1.kol
					 , ROUND(p1.saldo, @decimal_round)
					 , ROUND(p1.value, @decimal_round)
					 , ROUND(p1.added, @decimal_round)
					 , ROUND(p1.paymaccount, @decimal_round)
					 , ROUND(p1.paymaccount_peny, @decimal_round)
					 , ROUND(p1.paid, @decimal_round)
					 , p1.serv_unit
					 , p1.metod
					 , p1.is_counter
					 , @FinPeriodCurrent
					 , p1.kol_norma
					 , p1.metod_old
					 , p1.sup_id
					 , @build_id1
					 , p1.normaSingle
					 , p1.source_id
					 , p1.mode_id
					 , CASE
						   WHEN p1.occ_sup IS NOT NULL THEN p1.occ_sup
						   WHEN p1.occ_sup IS NULL AND
							   p1.sup_id = 0 THEN p1.occ
						   WHEN p1.occ_sup IS NULL AND
							   p1.sup_id > 0 THEN dbo.Fun_GetOccSUP(p1.occ, p1.sup_id, p1.dog_int)
						   ELSE p1.occ
					   END
					 , CASE
                           WHEN p1.date_ras_start <> @Start_date THEN p1.date_ras_start
                           ELSE NULL
                           END
					 , CASE
                           WHEN p1.date_ras_end <> @End_date THEN p1.date_ras_end
                           ELSE NULL
                           END
					 , p1.kol_added
					 , p1.koef_day
					 , p1.penalty_prev)
		OPTION (RECOMPILE)  -- 28.08.2020

		--WHEN NOT MATCHED BY SOURCE AND p.occ=@occ1 -- есть в paym_list и нет в @paym_list1
		--	THEN DELETE 
		;
		--IF @debug=1 select * from @paym_list1 where occ=@occ1	
		--IF @debug=1 select * from dbo.paym_list where occ=@occ1 ORDER BY service_id

		--DELETE p
		--	FROM dbo.PAYM_LIST AS p 
		--	LEFT JOIN @paym_list1 AS p1
		--		ON p.occ = p1.occ
		--		AND p.service_id = p1.service_id
		--		AND p.sup_id = p1.sup_id
		--WHERE p.occ = @occ1
		--	AND p1.sup_id IS NULL

		--IF @debug=1 select * from dbo.paym_list where occ=@occ1 ORDER BY service_id

		-- если нет режимов добавляем (по домовым может быть)
		INSERT INTO dbo.Consmodes_list (fin_id
									  , occ
									  , service_id
									  , source_id
									  , mode_id
									  , sup_id)
		SELECT PL.fin_id
			 , PL.occ
			 , PL.service_id
			 , source_id = (
				   SELECT id
				   FROM dbo.View_suppliers AS cm 
				   WHERE cm.service_id = PL.service_id
					   AND id % 1000 = 0
			   )
			 , mode_id = (
				   SELECT id
				   FROM dbo.Cons_modes AS cm 
				   WHERE cm.service_id = PL.service_id
					   AND id % 1000 = 0
			   )
			 , PL.sup_id
		FROM dbo.Paym_list PL 
			LEFT JOIN dbo.Consmodes_list CH 
				ON CH.occ = PL.occ
				AND CH.service_id = PL.service_id
				AND PL.sup_id = CH.sup_id
		WHERE PL.occ = @occ1
			AND PL.fin_id = @fin_id1
			AND CH.service_id IS NULL
			AND (PL.paid <> 0 OR PL.value > 0)
			AND @added = 0  -- только в текущем периоде

		-- ****************************************

		--IF @tip_id1 IN (1,5) 
		--	EXEC dbo.k_vvod_penalty_saldo @occ1

		-- Корректируем сальдо у кого есть сальдо по услугам
		-- и нет начисления по услугам
		--IF EXISTS(SELECT * FROM @paym_list1 
		--   WHERE (paid=0 AND saldo<0) OR (@SumSaldo<0) )         -- было saldo<>0    23/11/07
		--   AND @Saldo_edit<>1 -- и небыло ручного изменения сальдо                                   
		--BEGIN
		--  EXEC dbo.k_raschet_saldo @occ1
		--END

		--IF @debug=1 
		--BEGIN
		--	select * from OCCUPATIONS o where occ=@occ1
		--	select * from paym_list where occ=@occ1
		--end
		--*****************************************
		--print @occ1
		--  Процедура раскидки оплаты
		EXEC dbo.k_raschet_paymaccount @occ1 = @occ1
									 , @debug = 0

		--
		-- ****************************************
		--IF @debug=1 
		--BEGIN
		--	select * from OCCUPATIONS o where occ=@occ1
		--	select * from paym_list where occ=@occ1
		--end

		--IF @Penalty_calc1 = 1 -- стоит галочка "расчет пени". 30.06.21 уже раскидали по услугам зачем тогда убирать. 
		--BEGIN -- в расчете пеней надо блокировать 
		--	-- если в системе пени не расчитывается то
		--	IF (@Penalty_calc_glob1 = 0
		--		OR @Penalty_calc_tip1 = 0
		--		OR @Penalty_calc_build1 = 0)
		--		SELECT
		--			@penalty_value1 = 0
		--END
		IF @penalty_value1 IS NULL
			SET @penalty_value1 = 0
		IF @penalty_old_new1 IS NULL
			SET @penalty_old_new1 = 0

		--***********************************************************************
		-- Изменяем поле "начисленно в этом месяце"  
		-- Обнуляем для внешних услуг
		UPDATE dbo.Paym_list
		SET paid = 0
		WHERE occ = @occ1
			AND fin_id = @fin_id1
			AND subsid_only = CAST(1 AS BIT)

		--********* Удаляем не нужные строки ***********
		IF @payms_tip1 = 0
			DELETE FROM dbo.Paym_list
			WHERE occ = @occ1
				AND fin_id = @fin_id1
				AND tarif = 0
				AND saldo = 0
				AND value = 0
				AND paid = 0
				AND paymaccount = 0
				AND paymaccount_peny = 0
				AND added = 0
				AND ((source_id % 1000 = 0)	AND (mode_id % 1000 = 0))
				AND penalty_serv = 0
				AND penalty_old = 0
				AND penalty_prev = 0

		DECLARE @paid1 DECIMAL(15, 2) = 0 -- Постоянные начисления
			  , @paid_minus1 DECIMAL(15, 2) = 0 -- Постоянные начисления с минусом
			  , @Whole_payment1 DECIMAL(15, 2) = 0 -- итого к оплате
			  , @Debt1 DECIMAL(15, 2) = 0 -- конечное сальдо

		--**********************************************************************

		SELECT @SumSaldo_Serv = COALESCE(SUM(saldo), 0)
			 , @Paymaccount_Serv = COALESCE(SUM(paymaccount), 0)
			 , @Paymaccount_peny_serv1 = COALESCE(SUM(paymaccount_peny), 0)
			 , @value1 = COALESCE(SUM(value), 0)
			 , @discount1 = 0
			 , @added1 = COALESCE(SUM(added), 0)
			 , @paid1 = COALESCE(SUM(paid), 0)
		FROM dbo.Paym_list p 
		WHERE p.occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.sup_id = 0
			AND p.subsid_only = CAST(0 AS BIT)
			AND p.service_id <> 'пени'

		IF @Paymaccount_peny1 <> @Paymaccount_peny_serv1
			EXEC dbo.k_raschet_peny @occ1 = @occ1
								  , @debug = 0

		SELECT @Paymaccount1 = @Paymaccount_Serv

		-- если расчитываем только Субсидии
		IF @ras_subsid_only1 = 1
			SELECT @SumSaldo = 0
				 , @SumSaldo_Serv = 0
				 , @Paymaccount1 = 0
				 , @penalty_value1 = 0
				 , @penalty_added1 = 0
				 , @penalty_old_new1 = 0
				 , @Paymaccount1 = 0
				 , @Paymaccount_peny1 = 0

		-- Корректируем сальдо по услугам
		-- Если @SumSaldo_Serv<>@Sumsaldo и не было ручного изменения сальдо и разрешено по типу фонда	
		IF (@SumSaldo_Serv = 0
			AND @SumSaldo <> 0)
			AND @Saldo_edit <> 1
			AND @saldo_rascidka = 1   -- 24/05/12
		BEGIN
			--select @SumSaldo_Serv,@Sumsaldo,@Saldo_edit
			EXEC dbo.k_raschet_saldo @occ1 = @occ1
								   , @debug = 0

			-- проверяем
			SELECT @SumSaldo_Serv = COALESCE(SUM(saldo), 0)
			FROM dbo.Paym_list 
			WHERE occ = @occ1
				AND fin_id = @fin_id1
				AND subsid_only = CAST(0 AS BIT)
				AND account_one = CAST(0 AS BIT)
				AND service_id <> 'пени'

			IF @SumSaldo_Serv <> @SumSaldo
				SET @SumSaldo = @SumSaldo_Serv
		END
		ELSE -- корректируем сальдо на лицевом чтобы было как в услугах	
		IF @SumSaldo_Serv <> @SumSaldo
			SET @SumSaldo = @SumSaldo_Serv

		-- Дебет Без пени
		--SELECT @Debt1=@Sumsaldo+@paid1-(@paymaccount1-@Paymaccount_peny1) 
		--select @Debt1, @Sumsaldo, @Paid1, @paymaccount1,@Paymaccount_peny1

		SELECT @Whole_payment1 =
			(@SumSaldo + @paid1 - (@Paymaccount1 - @Paymaccount_peny1)) + (@penalty_value1 + @penalty_added1 + @penalty_old_new1)

		IF @Whole_payment1 < 0
		BEGIN
			SELECT @Whole_payment1 = 0
		END

		SET @paid_minus1 = 0
		IF @paid1 < 0
		BEGIN
			SET @paid_minus1 = @paid1
			SELECT @paid1 = 0
		END

		-- Собираем итоги с поставщиками кому начисляем
		SELECT @SumSaldoAll = SUM(p.saldo)
			 , @Paymaccount_ServAll = SUM(p.paymaccount - p.paymaccount_peny)
			 , @PaidAll = SUM(p.paid)
			 , @AddedAll = SUM(p.added)
		FROM dbo.Paym_list p 
			JOIN @paym_list1 AS p1 
				ON p.occ = p1.occ
				AND p.service_id = p1.service_id
				AND p.sup_id = p1.sup_id
		WHERE p.occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.subsid_only = CAST(0 AS BIT)
			AND p.service_id <> 'пени'
		--AND p1.paym_blocked = 0 --кому начисляем   закомментировал 21.10.2020 надо раньше блокировать если надо, а здесь только факт

		--IF @debug=1
		--begin
		--	SELECT * from @paym_list1 WHERE added<>0
		--	SELECT * from PAYM_LIST where occ = @occ1 AND fin_id = @fin_id1
		--	SELECT @AddedAll
		--end

		UPDATE o 
		SET SALDO_SERV = COALESCE(@SumSaldo_Serv, 0)
		  , saldo = COALESCE(@SumSaldo, 0)
		  , paymaccount = @Paymaccount1
		  , value = @value1
		  , discount = @discount1
		  , added = @added1
		  , Compens = 0
		  , paid = @paid1
		  , Paid_minus = @paid_minus1
		  , data_rascheta = current_timestamp
		  , NORMA_SQ = COALESCE(@SquareNorma, 0)
		  , status_id = @status1
		  , penalty_value = @penalty_value1
		  , penalty_added = @penalty_added1
		  , kol_people = COALESCE(p.kol_live, 0) --dbo.Fun_GetKolPeopleOccStatus(@occ1)
		  , kol_people_reg = COALESCE(p.kol_registration, 0) --dbo.Fun_GetKolPeopleOccReg(ot.fin_id, o.occ)
		  , kol_people_all = COALESCE(p.kol_itogo, 0) --dbo.Fun_GetKolPeopleOccAll(ot.fin_id, o.occ)
		  , kol_people_owner = COALESCE(p.kol_owner, 0)
		  , [ADDRESS] = [dbo].[Fun_GetAdres](@build_id1, o.flat_id, o.occ)
		  , SaldoAll = COALESCE(@SumSaldoAll, 0)
		  , Paymaccount_ServAll = COALESCE(@Paymaccount_ServAll, 0)
		  , PaidAll = COALESCE(@PaidAll, 0)
		  , AddedAll = COALESCE(@AddedAll, 0)
		  , fin_id = @FinPeriodCurrent
		  , SCHTL = CASE
                        WHEN @occ_prefix_tip <> '' THEN dbo.Fun_GetFalseOccOut(o.occ, o.tip_id)
                        ELSE SCHTL
            END
		FROM dbo.Occupations AS o
			OUTER APPLY dbo.Fun_GetCountPeopleOcc(@FinPeriodCurrent, o.occ) AS p
		WHERE o.occ = @occ1

		UPDATE I 
		SET SumPaym = @Whole_payment1
		  , paymaccount = @Paymaccount1
		  , saldo = @SumSaldo
		FROM dbo.Intprint AS I
		WHERE I.occ = @occ1
			AND I.fin_id = @FinPeriodCurrent

		--  по поставщику 	
		--IF @debug=1 select * from dbo.PAYM_LIST where occ=@occ1 AND fin_id=@fin_id1 AND sup_id > 0
		--IF @debug=1 select * from dbo.OCC_SUPPLIERS where occ=@occ1 AND fin_id=@fin_id1

		DELETE os 
		FROM dbo.Occ_Suppliers AS os
		WHERE os.occ = @occ1
			AND os.fin_id = @fin_id1
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list AS cl 
				WHERE cl.occ = os.occ
					AND cl.sup_id = os.sup_id
			)
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Cessia AS cl 
				WHERE cl.occ_sup = os.occ_sup
			)
		MERGE dbo.Occ_Suppliers AS os USING (
			SELECT pl.occ
				 , pl.sup_id
				 , MAX(COALESCE(cl.dog_int, 0)) AS dog_int
				 , SUM(saldo) AS saldo
				 , SUM(VALUE) AS VALUE
				 , SUM(added) AS added
				 , SUM(paid) AS paid
				 , SUM(paymaccount) AS paymaccount
				 , SUM(paymaccount_peny) AS paymaccount_peny
			FROM dbo.Paym_list AS pl
				JOIN dbo.Consmodes_list AS cl 
					ON pl.occ = cl.occ
					AND pl.service_id = cl.service_id
					AND pl.sup_id = cl.sup_id
			WHERE pl.occ = @occ1
				AND pl.sup_id > 0
				AND pl.service_id <> 'пени'
			GROUP BY pl.occ
				   , pl.sup_id 
		) AS p1
		ON os.occ = p1.occ
			AND os.sup_id = p1.sup_id
			AND os.fin_id = @fin_id1
		WHEN MATCHED
			THEN UPDATE
				SET os.saldo = p1.saldo
				  , os.value = p1.value
				  , os.added = p1.added
				  , os.paid = p1.paid
				  , os.paymaccount = p1.paymaccount
					--,os.paymaccount_peny=p1.paymaccount_peny
				  , occ_sup =
							 CASE
								 WHEN occ_sup <= 9999 THEN dbo.Fun_GetOccSUP(p1.occ, p1.sup_id, p1.dog_int)
								 ELSE occ_sup
							 END
		WHEN NOT MATCHED
			AND p1.dog_int > 0  --17.04.20
			THEN INSERT (fin_id
					   , occ
					   , sup_id
					   , saldo
					   , value
					   , added
					   , paid
					   , paymaccount
					   , occ_sup) --, Paymaccount_peny)             
				VALUES(@fin_id1
					 , p1.occ
					 , p1.sup_id
					 , p1.saldo
					 , p1.value
					 , p1.added
					 , p1.paid
					 , p1.paymaccount
					 , dbo.Fun_GetOccSUP(p1.occ, p1.sup_id, p1.dog_int));

		DELETE FROM dbo.Occ_Suppliers
		WHERE occ = @occ1
			AND fin_id = @fin_id1
			AND occ_sup = 0  --25.07.2021
	
		--IF @debug=1 select * from dbo.OCC_SUPPLIERS where occ=@occ1 AND fin_id=@fin_id1

		UPDATE os1 
		SET penalty_old = CASE
                              WHEN os1.Penalty_old_edit = 0 THEN COALESCE(os_old.penalty_old, 0)
                              ELSE os1.penalty_old
            END
		  , Paid_old = os_old.Paid_old
		  , id_jku_gis =
						CASE
							WHEN COALESCE(os1.id_jku_gis, '') = '' AND
								COALESCE(os_old.id_jku_gis, '') <> '' THEN os_old.id_jku_gis
							ELSE os1.id_jku_gis
						END
		  , [value] = CASE
                          WHEN @payms_tip1 = 0 THEN 0
                          ELSE os1.value
            END
		  , paid = CASE
                       WHEN @payms_tip1 = 0 THEN os1.added
                       ELSE paid
            END
		FROM dbo.Occ_Suppliers AS os1
			CROSS APPLY (
				SELECT (Penalty_old_new + penalty_value + penalty_added) AS Penalty_old
					 , paid AS paid_old
					 , id_jku_gis
				FROM dbo.Occ_Suppliers AS os2 
				WHERE os2.occ = @occ1
					AND os2.fin_id = @FinPred
					AND os2.sup_id = os1.sup_id
			) AS os_old
		WHERE occ = @occ1
			AND fin_id = @fin_id1 -- если не было ручного изменения пени
		OPTION (RECOMPILE)
		
		UPDATE os 	
		SET 
			dog_int = t_dog.id 
		  , cessia_dolg_mes_new = @cessia_dolg_mes
		  , os.rasschet = t_dog.rasschet
		FROM dbo.Occ_Suppliers AS os
		CROSS APPLY (
			SELECT TOP(1) ds.id, ao.rasschet
			FROM dbo.DOG_BUILD AS db
				JOIN dbo.DOG_SUP AS ds 
					ON db.dog_int = ds.id 
				LEFT JOIN dbo.Account_org AS ao 
					ON ds.bank_account = ao.id
			WHERE db.fin_id=@fin_id1 
			AND db.build_id=@build_id1 
			AND ds.sup_id=os.sup_id
			) AS t_dog
		WHERE os.fin_id = @fin_id1
			AND os.occ = @occ1
		OPTION (RECOMPILE) -- (MAXDOP 1)

		--IF @debug=1 select * from dbo.OCC_SUPPLIERS where occ=@occ1 AND fin_id=@fin_id1

		UPDATE ces 
		SET cessia_dolg_mes_new = @cessia_dolg_mes
		  , dog_int = OS.dog_int
		  , debt_current = OS.debt
		FROM dbo.Cessia AS ces
			JOIN dbo.Occ_Suppliers AS OS 
				ON ces.occ_sup = OS.occ_sup
				AND OS.fin_id = @fin_id1
				AND OS.occ = @occ1
		WHERE ces.occ_sup = @occ_sup

		--IF @debug=1 select * from PAYM_LIST where occ=@occ1 ORDER BY service_id

		-- Удаляем лишние строки
		DELETE pl
		--OUTPUT DELETED.*
		FROM dbo.Paym_list AS pl 
		WHERE pl.occ = @occ1
			AND fin_id = @fin_id1
			AND pl.tarif = 0
			AND pl.saldo = 0
			AND pl.value = 0
			AND pl.paid = 0
			AND pl.paymaccount = 0
			AND pl.paymaccount_peny = 0
			AND pl.debt = 0
			AND kol = 0
			AND (pl.source_id % 1000 = 0)
			--AND pl.kol_norma = 0
			AND pl.added = 0
			AND pl.penalty_prev = 0
			AND pl.penalty_old = 0
			AND pl.penalty_serv = 0
			AND pl.penalty_prev = 0
			AND @penalty_value1 = 0		  -- 11/01/2018
			AND @penalty_added1 = 0
			AND @penalty_old_new1 = 0	  -- 11/01/2018
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Services S 
				WHERE S.id = pl.service_id
					AND S.is_build = 1
			)

		--IF @debug=1 select * from PAYM_LIST where occ=@occ1

		-- если вдруг в истории есть тек. период - удаляем	
		IF EXISTS(SELECT 1 FROM dbo.Paym_history PH WHERE PH.occ = @occ1 AND PH.fin_id = @fin_id1)
			DELETE PH
			--OUTPUT DELETED.*
			FROM dbo.Paym_history PH
				JOIN dbo.Paym_list PL ON 
					PH.fin_id = PL.fin_id
					AND PH.occ = PL.occ
					AND PL.service_id = PH.service_id
			WHERE PH.occ = @occ1
				AND PH.fin_id = @fin_id1

		-- заполним площадь помещения если = 0
		UPDATE f
		SET area = COALESCE(t.total_sq, 0)
		FROM dbo.Flats AS f
		CROSS APPLY (SELECT SUM(o.total_sq) as total_sq
					FROM dbo.Occupations AS o
					WHERE o.flat_id = f.id) as t
		WHERE f.id = @flat_id1
			AND f.area = 0

	END  --if @added=0
	--ELSE
	IF @added <> 0
		OR @people_list = 1
	BEGIN  -- для перерасчетов
		--if @debug=1 select * from @paym_list1

		--SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DELETE FROM dbo.Paym_add 
		WHERE occ = @occ1

		INSERT INTO dbo.Paym_add 
		(occ
	   , service_id
	   , sup_id
	   , subsid_only
	   , tarif
	   , koef
	   , saldo
	   , value
	   , discount
	   , added
	   , paymaccount
	   , paid
	   , kol
	   , date_ras_start
	   , date_ras_end
	   , unit_id
	   , koef_day
	   , fin_id_paym
	   , kol_norma)
		SELECT occ
			 , service_id
			 , sup_id
			 , subsid_only
			 , tarif
			 , koef
			 , saldo
			 , value
			 , discount
			 , added
			 , paymaccount
			 , paid
			 , kol
			 , date_ras_start
			 , date_ras_end
			 , serv_unit
			 , koef_day
			 , @fin_id1
			 , kol_norma
		FROM @paym_list1

	--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   

	--select * from dbo.paym_add WHERE occ=@occ1
	END

--**********************************************************************   
--COMMIT TRAN
--IF @debug=1 select * from dbo.paym_list where occ=@occ1 ORDER BY service_id
LABEL_END:
	RETURN
go

