CREATE   PROCEDURE [dbo].[ka_add_P354_SOI]
	  @bldn_id1 INT
	, @service_id1 VARCHAR(10) -- код услуги
	, @fin_id1 SMALLINT -- фин. период
	, @value_source1 DECIMAL(15, 2) = 0 -- Объем по счётчику
	, @doc1 VARCHAR(100) = NULL -- Документ
	, @doc_no1 VARCHAR(15) = NULL -- номер акта -- '99999'-не делать расчеты кварплаты ,'88888'-не делать завершающий расчет квартплаты по дому
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @debug BIT = 0
	, @addyes INT = 0 OUTPUT -- если 1 то разовые добавили
	, @volume_arenda DECIMAL(12, 4) = 0 -- объём по нежилым помещениям
	, @volume_gvs DECIMAL(12, 4) = 0 -- объём воды для гвс(в домах где делают ГВС сами)
	, @serv_dom VARCHAR(10) = NULL
	, @flag SMALLINT = 0 -- 0 - не раскидывать по людям где счётчики, 1- раскидывать где счётчики
	, @use_add BIT = 1 -- учитывать перерасчёты
	, @S_arenda DECIMAL(9, 2) = NULL
	, @occ_test INT = 0 -- лиц.счёт для тестирования расчётов
	, @sup_id INT = NULL
	, @tarif DECIMAL(9, 4) = 0
	, @volume_odn DECIMAL(14, 6) = 0 -- объём по ОДН
	, @norma_odn DECIMAL(12, 6) = 0 -- норматив для расчета ОДН (по площади)
	, @set_soi_zero BIT = 0 -- установка СОИ в ноль
	, @volume_direct_contract DECIMAL(15, 6) = 0 -- объём услуги по прямым договорам
/*

Вызов процедуры:

DECLARE	@addyes int 
exec [dbo].ka_add_P354_SOI @bldn_id1 = 7028,@service_id1 = N'хвод',@fin_id1 = 239,
		@value_source1 = 1651,@doc1 = N'Тест',@doc_no1=9999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0, @volume_gvs=0, @serv_dom='одхж',@flag=1,@use_add=1,@occ_test=910001486
select @addyes

DECLARE	@addyes int 
exec [dbo].ka_add_P354_SOI @bldn_id1 = 6424,@service_id1 = N'хвод',@fin_id1 = 181,
		@value_source1 = 550,@doc1 = N'Тест',@doc_no1=9999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=38, @volume_gvs=0, @serv_dom='одхж',@flag=1,@use_add=1,@occ_test=335321
select @addyes

DECLARE	@addyes int 
exec [dbo].ka_add_P354_SOI @bldn_id1 = 5871,@service_id1 = N'элек',@fin_id1 = 181,
		@value_source1 = 34954,@doc1 = N'Тест',@doc_no1=9999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0, @volume_gvs=0, @serv_dom='одэж',@flag=1,@use_add=1,@occ_test=330002
select @addyes
		
DECLARE	@addyes int 
exec [dbo].ka_add_P354_SOI @bldn_id1 = 6424,@service_id1 = N'элек',@fin_id1 = 181,
		@value_source1 = 35276,@doc1 = N'Тест',@doc_no1=9999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=339, @volume_gvs=0, @serv_dom='одэж',@flag=1,@use_add=1,@occ_test=334139
select @addyes

используем перерасчёты и количество услуги высчитываем сами

если @doc_no1=99999	то не делаем перерасчёт по дому по окончанию процедуры
		
*/
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	IF @debug=1 
		PRINT OBJECT_NAME(@@PROCID)
	
	IF dbo.Fun_AccessAddBuild(@bldn_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	DECLARE @Vnr DECIMAL(15, 4)
		  , @Vnn DECIMAL(15, 4)
		  , @Vob DECIMAL(15, 4) = 0
		  , @value_raspred DECIMAL(15, 4) = 0
		  , @value_add_kol DECIMAL(15, 4) = 0
		  , @occ INT
		  , @total_sq DECIMAL(10, 4)
		  , @total_sq_save DECIMAL(10, 4)  -- для сравнения
		  , @Total_sq_noliving DECIMAL(10, 4)
		  , @KolPeopleItog SMALLINT
		  , @comments VARCHAR(100) = ''
		  , @ostatok_arenda DECIMAL(15, 4) = 0
		  , @ostatok DECIMAL(15, 4) = 0
		  , @tarif_norma DECIMAL(9, 4) = 0
		  , @tarif_ras DECIMAL(9, 4) = 0
		  , @sum_add DECIMAL(15, 2)
		  , @sum_value DECIMAL(15, 2)
		  , @tip_id SMALLINT
		  , @fin_current SMALLINT
		  , @str_koef VARCHAR(50)
		  , @str_formula VARCHAR(10) = N'Ф11_СОИ'
		  , @service_in VARCHAR(10) -- Код услуги на входе
		  , @flat_id1 INT
		  , @KolDayFinPeriod TINYINT -- кол-во дней в фин периоде
		  , @start_date SMALLDATETIME
		  , @is_ValueBuildMinus BIT -- Разрешить ОДН с минусом
		  , @odn_big_norma BIT -- ОДН может быть больше нормы
		  , @odn_big_norma_build BIT -- ОДН может быть больше нормы
			--@odn_min_norma_no	BIT,  -- не распределять ОДН если она меньше чем ОДН по норме
		  , @is_not_allocate_economy BIT = 1 -- не распределять экономию (по людям). Оставлять по норме.
		  , @service_pk VARCHAR(10) -- услуга с превышением норматива
		  , @is_boiler BIT -- есть бойлер
		  , @sup_id_boiler INT = 0
		  , @services_boiler VARCHAR(20) = '' -- список услуг с бойлером с противоположной услугой
		  , @soi_metod_calc VARCHAR(10) = 'CALC_TARIF' -- метод расчета СОИ  CALC_TARIF или CALC_KOL
		  , @soi_is_transfer_economy BIT
		  , @value_start DECIMAL(15, 4) = 0 -- Объём для распределения с предыдущего периода
		  , @VobEconomy DECIMAL(15, 4) = 0
		  , @soi_isTotalSq_Pasport BIT
		  , @soi_isTotalSq_Pasport_Build CHAR(1)
		  , @build_total_area DECIMAL(15,2) = 0
		  , @soi_boiler_only_hvs BIT
		  , @is_direct_contract BIT = 0 -- услуга на прямых договорах
		  , @build_total_sq_serv DECIMAL(10, 4) = 0
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @is_IVC BIT = 0

	IF dbo.strpos('KR1', @DB_NAME) > 0 SET @is_IVC=1

	SELECT @addyes = 0
		 , @service_in = @service_id1;

	SELECT @service_pk = '';
	--CASE
	--	WHEN @service_id1 = 'хвод' THEN 'хвпк'
	--	WHEN @service_id1 = 'гвод' THEN 'гвпк'
	--	ELSE ''
	--END

	SELECT @use_add=COALESCE(@use_add,1)
		, @flag=COALESCE(@flag,0)
		, @volume_gvs=COALESCE(@volume_gvs,0)
		, @volume_arenda=COALESCE(@volume_arenda,0)
		, @volume_direct_contract=COALESCE(@volume_direct_contract,0)

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL);

	SELECT @start_date = start_date
	FROM dbo.Global_values AS GV 
	WHERE fin_id = @fin_current;

	SELECT @odn_big_norma_build = COALESCE(odn_big_norma, 0)
		 , @is_boiler = COALESCE(is_boiler, 0)
		 , @soi_is_transfer_economy = soi_is_transfer_economy
		 , @build_total_area = b.build_total_area
	FROM dbo.Buildings B 
	WHERE id = @bldn_id1;

	--====================================================================

	SELECT @is_direct_contract=COALESCE(is_direct_contract,0)
		, @build_total_sq_serv = COALESCE(build_total_sq, 0)
		, @soi_isTotalSq_Pasport_Build = COALESCE(soi_isTotalSq_Pasport,'D')
	FROM dbo.Services_build 
	WHERE build_id=@bldn_id1
	 AND service_id=@service_id1

	SELECT @is_direct_contract=CASE WHEN @is_direct_contract=0 THEN COALESCE(is_direct_contract,0) ELSE @is_direct_contract END
		, @build_total_sq_serv = CASE WHEN @build_total_sq_serv=0 THEN COALESCE(build_total_sq, 0) ELSE @build_total_sq_serv END
		, @soi_isTotalSq_Pasport_Build = CASE 
			WHEN @soi_isTotalSq_Pasport_Build='Y' THEN @soi_isTotalSq_Pasport_Build ELSE COALESCE(soi_isTotalSq_Pasport,'D') END
	FROM dbo.Services_build 
	WHERE build_id=@bldn_id1
	 AND service_id=@serv_dom

	--====================================================================

	SELECT @KolDayFinPeriod = DATEDIFF(DAY, @start_date, DATEADD(MONTH, 1, @start_date));

	IF @fin_id1 = @fin_current
	BEGIN
		IF @debug=1 RAISERROR ('удаляем общедомовые по дому', 10, 1) WITH NOWAIT
		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb 
			JOIN dbo.View_occ_all AS o ON pcb.fin_id = o.fin_id
				AND pcb.occ = o.occ
		WHERE pcb.fin_id = @fin_current
			AND service_id IN (@service_id1, @serv_dom)
			AND o.bldn_id = @bldn_id1;

		DELETE pcb
		FROM dbo.[Build_source_value] AS pcb 
		WHERE pcb.fin_id = @fin_current
			AND service_id IN (@service_id1, @serv_dom)
			AND pcb.build_id = @bldn_id1;
	END;

	IF @value_source1 < 0
		RETURN;

	IF @debug = 1
		PRINT CONCAT('@service_id1: ', @service_id1, ' @serv_dom: ', @serv_dom, ' @service_in: ', @service_in)
	--IF @fin_current <> @fin_id1
	--BEGIN
	--	RAISERROR ('Задайте текущий фин период в доме!', 16, 1)
	--	RETURN -1
	--END

	IF (@fin_current = @fin_id1)
		AND COALESCE(@doc_no1,'') <> '99999'
	BEGIN
		IF @debug=1 RAISERROR ('делаем перерасчёт по дому', 10, 1) WITH NOWAIT 

		DECLARE curs CURSOR LOCAL FOR
			SELECT voa.occ
				 , voa.flat_id
			FROM dbo.VOcc voa 
				JOIN dbo.Occupation_Types AS ot ON 
					voa.tip_id = ot.id
			WHERE status_id <> 'закр'
				AND voa.bldn_id = @bldn_id1
			--AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
			ORDER BY occ;

		OPEN curs;
		FETCH NEXT FROM curs INTO @occ, @flat_id1;
		WHILE (@@fetch_status = 0)
		BEGIN
			--PRINT @occ
			-- расчитываем по внутренним счётчикам
			IF (@debug = 0)
				EXEC dbo.k_counter_raschet_flats2 @flat_id1 = @flat_id1
												, @tip_value1 = 1
												, @debug = 0;
			-- Расчитываем квартплату
			EXEC dbo.k_raschet_2 @occ1 = @occ
							   , @fin_id1 = @fin_current;

			FETCH NEXT FROM curs INTO @occ, @flat_id1;
		END;
		CLOSE curs;
		DEALLOCATE curs;
	END;

	SELECT @tip_id = tip_id
		 , @S_arenda = CASE WHEN @S_arenda IS NULL THEN COALESCE(arenda_sq, 0) ELSE @S_arenda END
		 , @is_ValueBuildMinus = CASE WHEN vb.is_value_build_minus = 1 THEN vb.is_value_build_minus ELSE OT.is_ValueBuildMinus END
		 , @is_not_allocate_economy = CASE WHEN vb.is_not_allocate_economy = 0 THEN OT.is_not_allocate_economy ELSE 0 END
		 , @odn_big_norma = CASE WHEN @odn_big_norma_build = 1 THEN 1 ELSE COALESCE(OT.odn_big_norma, 0) END -- значение из дома главнее
		 , @soi_metod_calc = OT.soi_metod_calc
		 , @soi_isTotalSq_Pasport = CASE
                                        WHEN @soi_isTotalSq_Pasport_Build = 'D' THEN ot.soi_isTotalSq_Pasport
                                        ELSE CASE WHEN(@soi_isTotalSq_Pasport_Build = 'Y') THEN 1 ELSE 0 END
        END
		 , @soi_is_transfer_economy =
           CASE
               WHEN vb.soi_is_transfer_economy = 1 THEN vb.soi_is_transfer_economy
               ELSE ot.soi_is_transfer_economy
               END --вначале берем из дома
		 , @soi_boiler_only_hvs = CASE WHEN @is_boiler = 1 THEN ot.soi_boiler_only_hvs ELSE 0 END
	FROM dbo.View_build_all AS vb 
		JOIN dbo.Occupation_Types OT ON 
			vb.tip_id = OT.id
	WHERE 
		vb.fin_id = @fin_id1
		AND vb.bldn_id = @bldn_id1;

	-- Если есть специальная площадь по услуге по нежилым
	IF @S_arenda IS NULL
		SELECT @S_arenda = arenda_sq
		FROM dbo.Build_arenda AS ba 
		WHERE fin_id = @fin_id1
			AND build_id = @bldn_id1
			AND service_id = @service_in;

	IF @S_arenda IS NULL
		SET @S_arenda = 0;

	if @soi_is_transfer_economy=1
	BEGIN
		SELECT @value_start=ch.V_start
		FROM dbo.CounterHouse AS ch 
		WHERE ch.service_id=@service_id1
			AND ch.tip_id=@tip_id
			AND ch.build_id=@bldn_id1
			AND ch.fin_id=@fin_id1

		IF @service_id1<>'отоп'  -- по отоп с прошлого периода не переносим
		BEGIN
			SELECT @value_start=ch.V_economy
			FROM dbo.CounterHouse AS ch 
			WHERE ch.service_id=@service_id1
				AND ch.tip_id=@tip_id
				AND ch.build_id=@bldn_id1
				AND ch.fin_id=@fin_id1-1
				AND ch.V_economy<0

			--if COALESCE(@value_start,0)=0
			--	SELECT @value_start=bs.v_itog
			--	FROM dbo.Build_source_value AS bs 
			--	WHERE bs.service_id=@service_id1
			--		AND bs.build_id=@bldn_id1
			--		AND bs.fin_id=@fin_id1-1
			--		AND bs.v_itog<0
		END
	END

	if @value_start IS NULL 	
		SET @value_start=0

	CREATE TABLE #t
	--DECLARE @t TABLE
	(
		  occ INT                      -- PRIMARY KEY
		, service_id VARCHAR(10) COLLATE database_default
		, sup_id INT
		, nom_kvr VARCHAR(20) COLLATE database_default DEFAULT ''
		, tarif DECIMAL(10, 4) DEFAULT 0
		, kol DECIMAL(15, 4) DEFAULT 0
		, kol_itog DECIMAL(15, 4) DEFAULT 0 NOT NULL
		, is_counter BIT DEFAULT 0
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, value DECIMAL(9, 2) DEFAULT 0
		, value_add DECIMAL(9, 2) DEFAULT 0 NOT NULL  -- сумма начислений разовых
		, value_add_kol DECIMAL(15, 4) DEFAULT 0 NOT NULL  -- объём разовых
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, sum_value DECIMAL(9, 2) DEFAULT 0
		, kol_add DECIMAL(15, 4) DEFAULT 0
		, comments VARCHAR(100) COLLATE database_default DEFAULT ''
		, norma DECIMAL(9, 2) DEFAULT 0
		, metod TINYINT DEFAULT 0
		, unit_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, kol_people TINYINT DEFAULT 0
		, mode_id INT DEFAULT 0
		, source_id INT DEFAULT 0
		, kol_norma_odn DECIMAL(15, 4) DEFAULT 0
		, kol_tmp DECIMAL(15, 4) DEFAULT 0
		, kol_excess DECIMAL(15, 4) DEFAULT 0 -- превышение ОДН
		, koef_day DECIMAL(9, 4) DEFAULT 1
		, kol_old DECIMAL(15, 6) DEFAULT 0
		, proptype_id VARCHAR(10) DEFAULT NULL
		, roomtype_id VARCHAR(10) DEFAULT NULL
		, PRIMARY KEY (occ, service_id)
	);

	-- Таблица лицевых для которых не надо считать общедомовые нужды
	DECLARE @t_occ_opu_no TABLE (
		  occ INT
	);
	-- список услуг по перерасчётам
	DECLARE @t_serv_add TABLE (
		  service_id VARCHAR(10)
	);
	IF @service_id1 IN (N'хвс2', N'хвод')
		INSERT INTO @t_serv_add
			(service_id)
			VALUES (N'хвс2')
				 , (N'хвод')
	IF @service_id1 IN (N'гвс2', N'гвод')
		INSERT INTO @t_serv_add
			(service_id)
			VALUES (N'гвс2')
				 , (N'гвод')
	IF NOT EXISTS (
			SELECT 1
			FROM @t_serv_add
			WHERE service_id = @service_id1
		)
		INSERT INTO @t_serv_add
			(service_id)
			VALUES (@service_id1)
	IF @debug = 1
		SELECT '@t_serv_add'
			 , *
		FROM @t_serv_add
	--IF @service_kol IS NULL SET @service_kol=@service_id1
	--IF @debug=1 PRINT '1'
	-- находим кол-во
	INSERT INTO #t
		(occ
	   , service_id
	   , sup_id
	   , kol
	   , is_counter
	   , value
	   , value_add
	   , value_add_kol
	   , nom_kvr
	   , metod
	   , unit_id
		 --,kol_people
	   , tarif
	   , koef_day
	   , kol_old
	   , proptype_id
	   , roomtype_id)
	SELECT oh.occ
		 , @service_id1
		 , COALESCE(ph.sup_id, 0)
		 , SUM(COALESCE(ph.kol, 0))
		 , COALESCE(ph.is_counter, 0)
		 , SUM(COALESCE(ph.value, 0))
		 , SUM(COALESCE(t_add.value, 0))
		 , SUM(COALESCE(t_add.kol, 0))
		 , oh.nom_kvr
		 , ph.metod                 -- когда по норме должен быть NULL
		 , ph.unit_id
		 , CASE
               WHEN COALESCE(@tarif, 0) = 0 THEN COALESCE(ph.tarif, 0)
               ELSE @tarif
        END                         -- если тариф не задан на входе
		 , MAX(CASE
                   WHEN @is_IVC = 0 THEN 1
                   ELSE COALESCE(ph.koef_day, 1)
        END)
		 , SUM(COALESCE(ph.kol, 0)) -- kol_old
		 , MAX(oh.proptype_id)
		 , MAX(oh.roomtype_id)
	FROM dbo.View_occ_all AS oh 
		LEFT JOIN dbo.View_paym AS ph ON 
			oh.fin_id = ph.fin_id
			AND oh.occ = ph.occ
			AND ph.service_id IN (@service_id1, @service_pk)
			AND (ph.sup_id = @sup_id OR @sup_id IS NULL)
		OUTER APPLY (
			SELECT SUM(ap.value) AS value
				 , SUM(ap.kol) AS kol
			FROM dbo.View_added AS ap 
			WHERE ap.occ = oh.occ
				AND ap.fin_id = @fin_id1
				AND ap.service_id = ph.service_id
				AND EXISTS (
					SELECT 1
					FROM @t_serv_add t
					WHERE t.service_id = ap.service_id
				)
				AND add_type NOT IN (11, 15)
		) AS t_add
	WHERE oh.bldn_id = @bldn_id1
		AND oh.fin_id = @fin_id1
	GROUP BY oh.occ
			 --, ph.service_id
		   , ph.sup_id
		   , ph.is_counter
		   , oh.nom_kvr
		   , ph.metod
		   , ph.unit_id
		   , ph.tarif;
	
	--IF @debug=1 PRINT '2'
	-- 23.12.2013
	UPDATE t
	SET kol = 0--,value=0,value_add=0
	FROM #t AS t
		JOIN @t_occ_opu_no AS t_no ON t.occ = t_no.occ;


	IF @is_direct_contract=1 AND @volume_direct_contract<>0
	BEGIN 
		IF @debug=1 PRINT 'услуга на прямых договорах'
		UPDATE t
		SET kol = 0, kol_add = 0, value_add=0, value_add_kol=0
		FROM #t AS t
	END

	DECLARE @service_id2 VARCHAR(10);
	SET @service_id2 = @service_id1;

	--*************************************************
	IF @service_id1 = N'гвс2'
		SELECT @service_id2 = N'гвод';

	IF @service_id1 = N'хвс2'
		SELECT @service_id2 = N'хвод';
	--*************************************************

	UPDATE t
	SET mode_id = cl.mode_id
	  , source_id = cl.source_id
	FROM #t AS t
		JOIN dbo.View_consmodes_all AS cl ON t.occ = cl.occ
	WHERE cl.fin_id = @fin_id1
		AND cl.service_id = @serv_dom --@service_id1
		AND cl.sup_id = t.sup_id

	UPDATE t
	SET total_sq = o.total_sq
	  , kol_itog = kol
	FROM #t AS t
		JOIN dbo.Occupations AS o ON t.occ = o.occ;

	UPDATE t
	SET kol_norma_odn = CASE
			WHEN @soi_metod_calc = 'CALC_TARIF' THEN vp.tarif
			ELSE vp.kol
		END
		, koef_day = vp.koef_day   -- берём коэф. с общедомовой услуги
	FROM #t AS t
		JOIN dbo.View_paym vp ON t.occ = vp.occ
			AND vp.fin_id = @fin_current
			AND vp.service_id = @serv_dom
	--AND t.sup_id = vp.sup_id;

	--SELECT TOP (1) @tarif_norma = tarif --kol_norma_odn
	--FROM #t AS t
	--WHERE tarif > 0  --kol_norma_odn

	SELECT TOP (1)
		@tarif_norma = kol_norma_odn  -- здесь нормативные тариф
	FROM #t AS t
	WHERE kol_norma_odn > 0

	IF (@tarif_norma = 0) AND COALESCE(@volume_odn, 0)=0
	BEGIN
		SET @comments = COALESCE(dbo.Fun_GetServiceName(@serv_dom), '')
		RAISERROR (N'Не удалось определить тариф(tarif_norma) по услуге %s. Проверьте есть ли начисления по ней!', 16, 1, @comments);
		RETURN -1
	END

	DECLARE @unit_id VARCHAR(10) = N'одсч'; --'кубм';
	
	IF @soi_metod_calc = 'CALC_KOL'
		SELECT TOP(1) @unit_id=unit_id
		FROM #t
		WHERE unit_id IS NOT NULL

	IF @service_id1 IN (N'отоп')
		SET @unit_id = N'ггкл';

	--IF @debug=1
	--	SELECT * FROM @t

	IF COALESCE(@tarif, 0) = 0 -- если тариф не задан на входе
	BEGIN
		SELECT TOP (1) @tarif = COALESCE(value, 0)
		FROM [dbo].[Rates] r
		WHERE r.finperiod = @fin_id1
			AND r.tipe_id = @tip_id
			AND r.service_id = @serv_dom
			AND r.[value] > 0
			AND EXISTS (
				SELECT 1
				FROM #t AS t
				WHERE t.mode_id = r.mode_id
			)
		ORDER BY r.[value] DESC

		IF @debug = 1
			SELECT @tarif AS tarif

		IF COALESCE(@tarif, 0) = 0
			SELECT TOP (1) @tarif = ph.tarif
			FROM dbo.View_occ_all AS oh 
				JOIN dbo.Flats AS f ON 
					oh.flat_id = f.id
				JOIN dbo.View_paym AS ph ON 
					oh.occ = ph.occ
					AND oh.fin_id = ph.fin_id
			WHERE f.bldn_id = @bldn_id1
				AND oh.fin_id = @fin_id1
				AND ph.service_id = @service_id1
				--AND (ph.is_counter IS NULL
				--OR ph.is_counter = 0)
				AND ph.value > 0
			ORDER BY tarif DESC

		IF COALESCE(@tarif, 0) = 0
		BEGIN
			SELECT TOP (1) @tarif = COALESCE(tarif, 0)
			FROM #t
			WHERE tarif > 0
		END

		IF @service_id1 IN (N'элек', N'элмп', N'эле2', N'Эдом')
		BEGIN
			SET @is_boiler = 0
						
			UPDATE t
			SET tarif = CASE
                            WHEN @tarif > 0 THEN @tarif
                            ELSE dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, @service_id1, @unit_id)
                END
			FROM #t AS t
			WHERE COALESCE(tarif,0) = 0

			IF @soi_metod_calc = 'CALC_KOL'
				UPDATE t SET tarif = @tarif	FROM #t AS t
		END
		ELSE		
		BEGIN --IF @service_id1 IN ('хвод','гвод','гвс2','вотв')
			UPDATE t
			SET tarif = CASE
                            WHEN @tarif > 0 THEN @tarif
                            ELSE dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, CASE
                                                                                 WHEN @service_id1 = N'гвс2'
                                                                                     THEN N'гвод'
                                                                                 WHEN @service_id1 = N'хвс2'
                                                                                     THEN N'хвод'
                                                                                 ELSE @service_id1
                                END, @unit_id)
                END
			FROM #t AS t
			WHERE COALESCE(tarif,0) = 0			

		END;
	END

	IF COALESCE(@volume_odn, 0)<>0 
	BEGIN  
		IF @debug=1 PRINT 'берём тариф по общедомовой услуги'
		UPDATE t
		SET tarif = p.tarif
		FROM #t AS t
			JOIN dbo.Paym_list as p ON t.occ=p.occ AND p.service_id=@serv_dom and p.fin_id=@fin_id1
		WHERE (t.tarif = 0 OR t.tarif IS NULL)
	END
	
	IF COALESCE(@tarif, 0)=0
		SELECT TOP (1) @tarif = COALESCE(tarif, 0)
		FROM #t
		WHERE tarif > 0

	IF COALESCE(@tarif, 0) = 0 AND COALESCE(@volume_odn, 0)=0
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@service_id1)
		RAISERROR (N'Не удалось определить тариф по услуге: %s. Проверьте есть ли начисления по ней!', 16, 1, @comments);
		RETURN -1;
	END;

	--IF @debug=1 SELECT * FROM @t

	IF @use_add = 0
		UPDATE t
		SET value_add_kol = 0
		FROM #t AS t
		WHERE value_add_kol <> 0;

	---- если не учитывать перерасчёты берём среднее количество по счётчикам
	---- пока не принято
	--IF @use_add = 0
	--BEGIN
	--	UPDATE t
	--	SET
	--		kol_itog = @KolDayFinPeriod * dbo.Fun_GetCounterAvgKol(occ, @service_in)
	--	FROM
	--		@t AS t
	--	WHERE
	--		is_counter = 1
	--END

	UPDATE t
	SET kol_itog = kol_itog + value_add_kol -- количество с учетом разовых
	FROM #t AS t;

	SELECT @total_sq = SUM(total_sq*koef_day) --12.10.2022
		,@Total_sq_noliving = SUM(CASE
                                      WHEN roomtype_id NOT IN (N'комм', N'об06', N'об10', N'отдк')
                                          THEN CAST(total_sq * koef_day AS DECIMAL(9, 2))
                                      ELSE 0
        END)
	FROM #t
	WHERE (source_id%1000)<>0 -- добавил условие 12.10.2022

	IF @debug = 1
		SELECT @soi_metod_calc AS soi_metod_calc
			 , COALESCE(SUM(kol_itog), 0) AS kol_itog
			 , SUM(kol) AS kol
			 , SUM(value_add_kol) AS value_add_kol
			 , SUM(value_add) AS value_add
			 , @odn_big_norma AS odn_big_norma
			 , @is_not_allocate_economy AS is_not_allocate_economy
			 , @is_ValueBuildMinus AS is_ValueBuildMinus
			 , @is_boiler AS is_boiler
			 , @service_id2 AS service_id2
			 , @is_direct_contract AS is_direct_contract
			 , @volume_direct_contract AS volume_direct_contract
			 , @flag AS flag
			 , @soi_is_transfer_economy AS soi_is_transfer_economy
			 , @value_start as value_start
			 , @service_id2 AS service_id2
			 , @service_id1 AS service_id1
			 , @service_in AS service_in
			 , @serv_dom AS serv_dom
			 , @volume_odn AS volume_odn
			 , @unit_id AS unit_id
			 , @tarif as tarif
			 , @total_sq AS total_sq
			 , @Total_sq_noliving AS Total_sq_noliving 
			 , @soi_isTotalSq_Pasport AS soi_isTotalSq_Pasport			 
			 , @build_total_area AS build_total_area			 			 
			 , @build_total_sq_serv AS build_total_sq_serv
			 , @soi_boiler_only_hvs AS soi_boiler_only_hvs
		FROM #t;

	--IF @debug = 1
	--	SELECT coalesce(sum(value_add_kol), 0) AS value_add_kol
	--	FROM
	--		@t

	IF @debug = 1
		SELECT '#t'
			 , *
		FROM #t
		ORDER BY dbo.Fun_SortDom(nom_kvr);

	IF @debug = 1
		SELECT COALESCE(SUM(kol), 0) AS kol,			   
			   COALESCE(SUM(value_add_kol), 0) AS value_add_kol,
			   COALESCE(SUM(kol_itog), 0) AS kol_itog,
			   COALESCE(SUM(kol_add), 0) AS kol_add
		FROM #t;
	
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod is null
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod=3
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=1 or metod=3
	SET @total_sq_save=@total_sq -- сохраняем потом для сравнения
	IF @soi_isTotalSq_Pasport = 1 AND @build_total_area>0
		SET @total_sq=@build_total_area -- берём площадь дома по паспорту

	if @build_total_sq_serv>0 -- берём площадь из услуги по дому
		SET @total_sq=@build_total_sq_serv 

	SELECT @KolPeopleItog = SUM(kol_people)
	FROM #t
	WHERE is_counter =
          CASE
              WHEN @flag = 0 THEN 0
              ELSE is_counter
              END -- раскидка на лицевые без счётчиков

	SELECT @Vnn = COALESCE(SUM(kol_itog), 0)
	FROM #t
	WHERE (is_counter = 0 AND metod IS NULL);
	--(is_counter = 1	AND metod=1)

	SELECT @Vnr = COALESCE(SUM(kol_itog), 0)
	FROM #t
	WHERE NOT (is_counter = 0 AND metod IS NULL);
	--is_counter = 1
	--	OR metod IN (2, 3, 4)

	SELECT @value_add_kol = SUM(value_add_kol)
	FROM #t AS t;

	IF @is_direct_contract=1 AND @volume_direct_contract<>0
	BEGIN -- услуга на прямых договорах
		SELECT @Vnr=@volume_direct_contract, @Vnn=0 	
	END

	IF (@Vnn = 0 AND @Vnr = 0) AND COALESCE(@volume_odn, 0)=0
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@service_id1)
		RAISERROR (N'Начислений по услуге %s не было', 16, 1, @comments);
		RETURN -1
	END;

	-- В домах где есть бойлер надо суммировать ещё объём другой услуги ГВС или ХВС
	DECLARE @Vnr_serv2 DECIMAL(15, 4) = 0
		  , @value_add_kol_boiler DECIMAL(15, 4) = 0
		  , @tarif_boiler DECIMAL(15, 4) = 0

	IF @is_boiler = 1
	BEGIN
		-- список услуг по перерасчётам
		DECLARE @t_serv_boiler TABLE (
			  service_id VARCHAR(10)
		);
		IF @service_id1 IN (N'хвс2', N'хвод')
			INSERT INTO @t_serv_boiler
				(service_id)
				VALUES (N'гвс2')
					 , (N'гвод')
		IF @service_id1 IN (N'гвс2', N'гвод')
			INSERT INTO @t_serv_boiler
				(service_id)
				VALUES (N'хвс2')
					 , (N'хвод')

		SELECT @services_boiler = SUBSTRING((
				SELECT ', ' + service_id
				FROM @t_serv_boiler
				FOR XML PATH ('')
			), 2, 400)

		SELECT @Vnr_serv2 = SUM(COALESCE(ph.kol, 0))
			 , @tarif_boiler = MAX(ph.tarif)
			 , @value_add_kol_boiler = COALESCE((
				   SELECT SUM(ap.kol)
				   FROM dbo.View_added AS ap 
					   JOIN dbo.View_occ_all AS oh1 ON ap.occ = oh1.occ
						   AND ap.fin_id = oh1.fin_id
				   WHERE ap.fin_id = @fin_id1
					   AND oh1.bldn_id = @bldn_id1
					   AND ap.service_id IN (SELECT service_id FROM @t_serv_boiler)
					   --AND ap.sup_id = ph.sup_id -- @sup_id_boiler
					   AND add_type NOT IN (11, 15)
			   ), 0)
		FROM dbo.View_occ_all AS oh 
			JOIN dbo.View_paym AS ph ON oh.fin_id = ph.fin_id
				AND oh.occ = ph.occ
		--AND ph.sup_id = @sup_id_boiler
		WHERE oh.bldn_id = @bldn_id1
			AND oh.fin_id = @fin_id1
			AND (ph.Paid <> 0 OR ph.kol <> 0)
			AND ph.service_id IN (SELECT service_id FROM @t_serv_boiler)

		IF (@service_id1 = N'вотв')
			AND (@serv_dom = N'одвж') 
			AND (@soi_boiler_only_hvs<>1)
		BEGIN
			SET @value_source1 = @value_source1 * 0.5
		END

		IF @debug = 1
		BEGIN
			PRINT '@value_source1: ' + STR(@value_source1, 12, 4)
			PRINT '@services_boiler: ' + @services_boiler
			PRINT '@sup_id_boiler: ' + STR(@sup_id_boiler, 4)
			PRINT '@Vnr_serv2 (объём boiler): ' + STR(@Vnr_serv2, 10, 4)
			PRINT '@value_add_value_boiler (объём разовых): ' + STR(@value_add_kol_boiler, 10, 4)
			PRINT '@tarif_boiler: ' + STR(@tarif_boiler, 10, 4)
			PRINT '@value_add_kol: ' + STR(@value_add_kol, 10, 4)			
		END

		SELECT @Vnr_serv2 = @Vnr_serv2 + @value_add_kol_boiler

		IF @Vnr_serv2 IS NULL
			SET @Vnr_serv2 = 0;

		IF @debug = 1
		BEGIN
			PRINT N'В доме есть Бойлер. По услугам: ' + @services_boiler + N' Объём: ' + STR(@Vnr_serv2, 9, 2);
		END
	END;
	--************************************************************************************************************

	--SELECT @Vob = @value_source1 - (@volume_arenda + @Vnn + @Vnr + @value_add_kol)
	IF COALESCE(@volume_odn, 0) <> 0
	BEGIN
		SELECT @Vob = @value_start + @volume_odn, @str_koef = dbo.NSTR(@volume_odn) --, @value_source1=0
	END
	ELSE
	BEGIN
		SELECT @Vob = @value_start + @value_source1 - @volume_arenda - @volume_gvs - @Vnn - @Vnr - @Vnr_serv2;

		SELECT @str_koef = dbo.NSTR(@value_source1) + '-' + dbo.NSTR(@volume_arenda) + '-' + dbo.NSTR(@volume_gvs) +
		'-' + dbo.NSTR(@Vnn) + '-' + dbo.NSTR(@Vnr);
	END

	IF @set_soi_zero=1
	BEGIN
		if @debug=1 PRINT '@set_soi_zero=1'
		GOTO LABEL_SET_ZERO
	END

	IF @value_start<>0
		SELECT @str_koef = dbo.NSTR(@value_start) + '+' + @str_koef

	IF @is_boiler = 1
	BEGIN
		IF (@service_id1 = N'вотв')
			AND (@serv_dom = N'одвж')
			SELECT @str_formula = N'Ф11_1_СОИ'
				 , @str_koef = '(' + @str_koef + '-' + dbo.NSTR(@Vnr_serv2) + ')'
		ELSE
			if @soi_boiler_only_hvs=1  -- не умножаем на 0.5
				SELECT @Vob = @Vob 
					 , @str_formula = N'Ф11_1_СОИ'
					 --, @str_koef = '(' + @str_koef + ')'
					 , @str_koef = @str_koef + '-' + dbo.NSTR(@Vnr_serv2)
			ELSE
				SELECT @Vob = @Vob * 0.5
					 , @str_formula = N'Ф11_1_СОИ'
					 , @str_koef = '(' + @str_koef + '-' + dbo.NSTR(@Vnr_serv2) + ')*0,5';
	END
	-- Ф11_1_СОИ: (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)
	-- Ф11_1_СОИ(Бойлер): (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*0,5
	
	if @Vob<0 -- AND @soi_is_transfer_economy=1
	BEGIN
		SELECT @VobEconomy=@Vob
		IF @debug=1 PRINT CONCAT('Экономия на след.месяц: ', @VobEconomy)
	END

	IF @Vob < 0
	BEGIN
		IF @debug = 1
			PRINT '@Vob < 0'
		UPDATE #t
		SET service_id = @serv_dom
		  , comments = CASE 
		  WHEN COALESCE(@volume_odn, 0) <> 0 THEN dbo.NSTR(@value_start) + '+' + dbo.NSTR(@volume_odn) + ' < 0'
		  ELSE  N'Объём по ОПУ (' + dbo.NSTR(@value_source1) + N') меньше рассчитанного (' + dbo.NSTR(@Vnn + @Vnr + @Vnr_serv2) + ')'
			END
	END

	IF @Vob > 0
		AND @service_in <> N'отоп'
	BEGIN
		IF @debug = 1
			PRINT N'раскидка по площади на общедомовые нужды СОИ'

		IF @soi_metod_calc = 'CALC_TARIF'
		BEGIN

				IF @norma_odn>0
				BEGIN
					IF @debug=1 PRINT '@norma_odn > 0'
			
					UPDATE t
					SET kol_add = @norma_odn * total_sq * t.koef_day
					  , comments = dbo.NSTR(t.tarif) + '*'+ dbo.NSTR(@norma_odn) + '*' + dbo.NSTR(total_sq)
					  + CASE
                            WHEN t.koef_day < 1 THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
                            ELSE ''
                                       END
					FROM #t t			

				END
				ELSE
				BEGIN

					IF (@total_sq + @S_arenda) > 0
						SELECT @tarif_ras = @Vob * @tarif / (@total_sq + @S_arenda)

					IF @debug = 1
						PRINT 'tarif_ras=' + STR(COALESCE(@tarif_ras, 0), 9, 4) + ' tarif_norma=' + STR(@tarif_norma, 9, 4)

					--IF (@tarif_norma > @tarif_ras)
					--	OR (@tarif_norma < @tarif_ras
					--	AND @odn_big_norma = 1)
					--	SET @tarif_ras = @tarif_ras
					--ELSE
					--	SET @tarif_ras = @tarif_norma

					IF (@tarif_ras > @tarif_norma) AND (@odn_big_norma = 0)
						SET @tarif_ras = @tarif_norma


					UPDATE t
					SET kol_add = total_sq
					  , tarif = @tarif_ras
					  , comments = @str_formula + CASE
                                                      WHEN @tarif_ras = @tarif_norma THEN N'(НТ)'
                                                      ELSE N'(РТ)'
                        END + ':(' + @str_koef + ')*' +
                                   dbo.FSTR(@tarif, 9, 2) + '/(' + dbo.FSTR(@total_sq, 9, 2) + '+' + dbo.FSTR(@S_arenda, 9, 2) +
                                   ')' + CASE
                                             WHEN @tarif_ras = @tarif_norma THEN N'(РТ:' + dbo.FSTR(@tarif_ras, 9, 4)
                                             ELSE N'(НТ:' + dbo.FSTR(@tarif_norma, 9, 4)
                                       END + ')'
					FROM #t AS t;
				-- Ф11_1_СОИ:((ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*Тариф/(ПлощДом+ПлощАренда); РасчТариф: Объём*Тариф/(ПлощДом+ПлощАренда)
				END
		END
		ELSE
		BEGIN  -- @soi_metod_calc = CALC_KOL
			IF @debug = 1
				PRINT 'меняем объём'

			--IF @soi_isTotalSq_Pasport = 1 AND @build_total_area>0
			--	UPDATE t
			--	SET kol_tmp = @Vob * total_sq / @build_total_area
			--		,comments = @str_formula + ':(' + @str_koef + ')*' + dbo.FSTR(total_sq, 9, 2) + '/' +
			--		dbo.FSTR(@build_total_area, 9, 2)
			--	FROM #t AS t
			--ELSE
			IF (@total_sq + @S_arenda) > 0
				UPDATE t
				SET kol_tmp = @Vob * (total_sq  * t.koef_day) / (@total_sq + @S_arenda)
					,comments = @str_formula + ':(' + @str_koef + ')*(' + dbo.NSTR(total_sq) + CASE
                                                                                                  WHEN t.koef_day < 1
                                                                                                  THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
																								ELSE '' END 
					+ ')/(' + dbo.NSTR(@total_sq) + '+' + dbo.NSTR(@S_arenda) + ')'
				FROM #t AS t
				WHERE (t.mode_id%1000)<>0

		-- Ф11_1 (Площадь): (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*ПлощКв/(ПлощДом+ПлощАренда)
			
			--IF @odn_big_norma = 1  -- разрешены ОДН больше норматива
			UPDATE t
			SET kol_add = COALESCE(kol_tmp, 0)
			    , kol_excess = CASE
                                   WHEN t.kol_tmp > kol_norma_odn THEN t.kol_tmp - kol_norma_odn
                                   ELSE 0
                END
				, comments = CASE
                                 WHEN t.total_sq = 0 THEN ''
                                 ELSE t.comments
                END
			FROM #t AS t

			--IF @debug=1 SELECT '1', nom_kvr, kol, kol_tmp, kol_add, comments FROM #t

			IF (@is_not_allocate_economy = 1) and (@odn_big_norma = 0) AND COALESCE(@volume_odn, 0) = 0-- 
			BEGIN
				IF @soi_boiler_only_hvs=1 AND (@service_in='хвод' AND @serv_dom='одхж')
					UPDATE t
					SET kol_add = (t.kol_norma_odn*2)  -- норматив гвс сои + хвс сои (т.к. гвс сои не начисляем)
					  , comments = N'Оставили начисление по норме'
					FROM #t AS t
					WHERE kol_add>(t.kol_norma_odn*2)
						--AND t.service_id='одхж'
				ELSE
					UPDATE t
					SET kol_add = t.kol_norma_odn
					  , comments = N'Оставили начисление по норме'
					FROM #t AS t
					WHERE kol_add>t.kol_norma_odn
			END

			--IF @debug=1 SELECT '2', nom_kvr, kol, kol_tmp, kol_add, comments FROM #t

			IF ((@odn_big_norma = 1) OR (@volume_odn>0)) AND (@total_sq_save=@total_sq) 
			BEGIN -- когда площадь по паспорту другая, не будем раскидывать остаток
				SELECT @ostatok_arenda = SUM(kol_add)
				FROM #t;
				SELECT @ostatok_arenda = @Vob - @ostatok_arenda;

				IF @S_arenda = 0
					AND @ostatok_arenda <> 0
				BEGIN
					IF @debug = 1
						PRINT N'надо раскидать остаток';

					;WITH cte AS (
						SELECT TOP (1) * FROM #t AS t WHERE kol_add <> 0
					)
					UPDATE cte
					SET kol_add = kol_add + @ostatok_arenda;					
				END;
			END;

		END

		if @is_ValueBuildMinus=0 -- запрещено кол-во с минусом
			UPDATE t SET kol_add=0	FROM #t AS t WHERE kol_add < 0;

		UPDATE t
		SET sum_value = tarif * kol_add		
		FROM #t AS t
		WHERE kol_add <> 0;

		UPDATE #t
		SET service_id = @serv_dom;

		IF @debug = 1
			SELECT @tarif AS tarif
				 , @tarif_norma AS tarif_norma
				 , @tarif_ras AS tarif_ras

		-- сохраняем распределяемый объём
		SELECT @value_raspred = SUM(kol_add)
		FROM #t;
	END
	ELSE
	BEGIN -- @Vob < 0
		UPDATE t
		SET kol_add = 0
		  , sum_add = 0
		  , sum_value = 0
		FROM #t AS t;
	END

	IF @debug = 1
		SELECT @value_source1 AS '@value_source1'
			 , @volume_arenda AS '@volume_arenda'
			 , @Vnn AS '@Vnn'
			 , @Vnr AS '@Vnr'
			 , @Vnr_serv2 AS '@Vnr_serv2'
			 , @Vob AS '@value_source1-@volume_arenda-@Vnn-@Vnr'
			 , @ostatok_arenda AS '@ostatok_arenda'
			 , @value_add_kol AS '@value_add_kol'
			 , @S_arenda AS '@S_arenda'
			 , @tarif AS '@tarif'
			 , @tip_id AS '@tip_id'
			 , @fin_id1 AS '@fin_id1'
			 , @VobEconomy AS '@VobEconomy'
			 , @Vob AS '@Vob'
			 , @volume_odn AS '@volume_odn'
			 , @volume_direct_contract AS '@volume_direct_contract'

	SELECT @sum_add = SUM(sum_add)
		 , @sum_value = SUM(sum_value)
	FROM #t;

	IF @debug = 1
		SELECT t = '@t'
			 , *
		FROM #t
		ORDER BY dbo.Fun_SortDom(nom_kvr);

	DECLARE @user_edit1 SMALLINT;
	SELECT @user_edit1 = dbo.Fun_GetCurrentUserId();

	--RETURN  -- для тестирования

	IF @fin_current > @fin_id1
	BEGIN
		-- Формируем перерасчёты в текущем месяце по общедомовым
		INSERT INTO dbo.Added_Payments
			(occ
		   , service_id
		   , sup_id
		   , add_type
		   , value
		   , doc
		   , doc_no
		   , doc_date
		   , user_edit
		   , date_edit
		   , comments
		   , kol
		   , fin_id)
		SELECT t.occ
			 , @service_in
			 , t.sup_id
			 , 2
			 , t.sum_value
			 , @doc1
			 , @doc_no1
			 , @doc_date1
			 , @user_edit1
			 , current_timestamp
			 , t.comments
			 , t.kol_add
			 , @fin_current
		FROM #t AS t;
		SELECT @addyes = CASE
                             WHEN @addyes = 0 THEN @@rowcount
                             ELSE @addyes
            END;

		GOTO LABEL_END;
	END;

	BEGIN TRAN;

	--IF @service_id1 <> @serv_dom
	--	-- удаляем начисления по общедомовой услуге
	--	DELETE pcb
	--	FROM dbo.PAYM_OCC_BUILD AS pcb
	--		JOIN @t AS t
	--			ON pcb.occ = t.occ
	--	WHERE pcb.fin_id = @fin_current
	--		AND
	--		pcb.service_id = @serv_dom


	DELETE pcb
	FROM dbo.Paym_occ_build AS pcb
		JOIN #t AS t ON 
			pcb.occ = t.occ
	WHERE pcb.fin_id = @fin_current
		AND pcb.service_id IN (@service_id1, @serv_dom);

	INSERT INTO dbo.Paym_occ_build 
		(fin_id
	   , occ
	   , service_id
	   , kol
	   , tarif
	   , value
	   , comments
	   , unit_id
	   , procedura
	   , kol_add
	   , metod_old
	   , service_in
	   , kol_excess
	   , sup_id
	   , koef_day
	   , kol_old)
	SELECT @fin_current
		 , t.occ
		 , t.service_id
		 , t.kol_add
		 , t.tarif
		 , t.sum_value
		 , t.comments
		 , NULLIF(@unit_id,'') AS unit_id
		 , OBJECT_NAME(@@PROCID) AS procedura
		 , CASE
				WHEN service_id=@serv_dom THEN t.kol_norma_odn - t.kol_add
				ELSE t.kol - t.kol_add
		   END AS kol_add
		 , t.metod
		 , @service_in
		 , t.kol_excess
		 , COALESCE(t.sup_id, 0) AS sup_id
		 , t.koef_day
		 , t.kol_old
	FROM #t AS t
	WHERE t.service_id = @serv_dom;
	SELECT @addyes = CASE
                         WHEN @addyes = 0 THEN @@rowcount
                         ELSE @addyes
        END;

	COMMIT TRAN;

LABEL_SET_ZERO:
	IF ((@service_id1 <> @serv_dom) AND (@soi_metod_calc = 'CALC_TARIF')) OR (@set_soi_zero=1)
	BEGIN
		IF @debug = 1
			PRINT N'Обнуляем чтобы не было ОДН по норме'

		INSERT INTO dbo.Paym_occ_build 
			(fin_id
		   , occ
		   , service_id
		   , kol
		   , tarif
		   , value
		   , comments
		   , unit_id
		   , procedura
		   , kol_add
		   , metod_old
		   , service_in
		   , sup_id
		   , kol_excess
		   , koef_day
		   , kol_old)
		SELECT @fin_current
			 , t.occ
			 , @serv_dom
			 , 0
			 , t.tarif
			 , 0
			 , CONCAT(N'Обнуляем чтобы не было СОИ по норме. Итого Объём: ', dbo.nstr(@Vob))
			 , NULLIF(@unit_id,'') AS unit_id
			 , OBJECT_NAME(@@PROCID) AS procedura
			 , 0
			 , t.metod
			 , @service_in
			 , COALESCE(sup_id, 0)
			 , - t.kol_norma_odn
			 , t.koef_day
			 , t.kol_old
		FROM #t AS t
		WHERE service_id <> @serv_dom
		SELECT @addyes = CASE
                             WHEN @addyes = 0 THEN @@rowcount
                             ELSE @addyes
            END;
	END

	IF @soi_boiler_only_hvs=1 AND (@service_in='хвод' AND @serv_dom='одхж')
	BEGIN
		IF @debug = 1
			PRINT N'Обнуляем ГВС СОИ'

		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb
			JOIN #t AS t ON pcb.occ = t.occ
		WHERE pcb.fin_id = @fin_current
			AND pcb.service_id IN ('одгж');

		INSERT INTO dbo.Paym_occ_build 
			(fin_id
		   , occ
		   , service_id
		   , kol
		   , tarif
		   , value
		   , comments
		   , unit_id
		   , procedura
		   , kol_add
		   , metod_old
		   , service_in
		   , sup_id
		   , kol_excess
		   , koef_day)
		SELECT @fin_current
			 , t.occ
			 , 'одгж'
			 , 0
			 , tarif
			 , 0
			 , N'Обнуляем чтобы не было СОИ по норме'
			 , NULLIF(@unit_id,'') AS unit_id
			 , OBJECT_NAME(@@PROCID) AS procedura
			 , 0
			 , metod
			 , 'гвод'
			 , COALESCE(sup_id, 0)
			 , - t.kol_norma_odn
			 , koef_day
		FROM #t AS t

	END

	IF @debug = 1
		PRINT N'сохраняем итоговые данные по дому, использованные в расчёте'
	MERGE dbo.Build_source_value AS bs USING (
		SELECT @bldn_id1 AS bldn_id1
			 , @fin_current AS fin_current
			 , @service_in AS service_in
	) AS t2
	ON bs.build_id = t2.bldn_id1
		AND fin_id = t2.fin_current
		AND service_id = t2.service_in
	WHEN MATCHED
		THEN UPDATE
			SET value_source = @value_source1
			  , value_arenda = @volume_arenda
			  , value_norma = @Vnn
			  , value_add = @value_add_kol
			  , value_ipu = @Vnr
			  , value_gvs = @volume_gvs
			  , v_itog = @Vob
			  , S_arenda = @S_arenda
			  , kol_people_serv = COALESCE(@KolPeopleItog, 0)
			  , unit_id = @unit_id
			  , total_sq = @total_sq
			  , use_add = @use_add
			  , flag_raskidka = @flag
			  , value_raspred = COALESCE(@value_raspred, 0)
			  , value_start = @value_start
			  , value_odn = @volume_odn
	WHEN NOT MATCHED
		THEN INSERT
				(fin_id
			   , build_id
			   , service_id
			   , value_start
			   , value_source
			   , value_arenda
			   , value_norma
			   , value_add
			   , value_ipu
			   , value_gvs
			   , v_itog
			   , S_arenda
			   , kol_people_serv
			   , unit_id
			   , total_sq
			   , use_add
			   , flag_raskidka
			   , value_raspred
			   , value_odn)
				VALUES (@fin_current
					  , @bldn_id1
					  , @service_in
					  , @value_start
					  , @value_source1
					  , @volume_arenda
					  , @Vnn
					  , @value_add_kol
					  , @Vnr
					  , @volume_gvs
					  , @Vob
					  , @S_arenda
					  , COALESCE(@KolPeopleItog, 0)
					  , @unit_id
					  , @total_sq
					  , @use_add
					  , @flag
					  , COALESCE(@value_raspred, 0)
					  , COALESCE(@volume_odn, 0));

	--**************************************************************
	DECLARE @counter_id1 INT = NULL;
	SELECT @counter_id1 = id
	FROM dbo.View_counter_build AS vcb
	WHERE build_id = @bldn_id1
		AND service_id = @service_in
		AND vcb.date_del is NULL
	--AND unit_id = @unit_id;

	IF @counter_id1 IS NULL AND (@is_boiler=0 AND @service_id1<>'гвод')
		AND @unit_id <> N'одсч'
	BEGIN
		IF @debug = 1
			PRINT N'Если нет домового счётчика по этой услуге то заводим его'
		-- дату создания счётчика делаем 1 число текущего месяца
		DECLARE @CurDate SMALLDATETIME = @start_date
			  , @serial_number_house VARCHAR(20) = STR(@bldn_id1, 6) + ' ' + @service_in;

		EXEC k_counter_add @build_id1 = @bldn_id1
						 , @flat_id1 = NULL
						 , @service_id1 = @service_in
						 , @serial_number1 = @serial_number_house
						 , @type1 = 'HOUSE'
						 , @max_value1 = 999999
						 , @koef1 = 1
						 , @unit_id1 = @unit_id
						 , @count_value1 = 0
						 , @date_create1 = @CurDate
						 , @periodcheck = NULL
						 , @comments1 = N'создан автоматически при расчёте ОПУ'
						 , @internal = 0
						 , @is_build = 1
						 , @counter_id_out = @counter_id1 OUTPUT;

	END;

	IF @debug = 1
	begin		
		RAISERROR (N'Добавляем показание по счётчику', 10, 1) WITH NOWAIT;
		RAISERROR ('@counter_id1=%d, @unit_id=%s', 10, 1, @counter_id1, @unit_id) WITH NOWAIT;
	end

	DECLARE @t_counter TABLE (
		  id INT
		, counter_id INT
		, actual_value DECIMAL(12, 4)
	);
	DECLARE @Sum_Actual_value DECIMAL(12, 4)
		  , @inspector_date1 SMALLDATETIME;

	INSERT INTO @t_counter
		(id
	   , counter_id
	   , actual_value)
	SELECT id
		 , counter_id
		 , COALESCE(actual_value, 0)
	FROM dbo.View_counter_insp_build
	WHERE build_id = @bldn_id1
		AND fin_id = @fin_current
		AND service_id = @service_id1;

	SELECT @Sum_Actual_value = COALESCE(SUM(actual_value), 0)
	FROM @t_counter;

	IF @Sum_Actual_value <> @value_source1
	BEGIN
		DELETE ci
		FROM dbo.Counter_inspector AS ci
			JOIN @t_counter AS t ON 
				ci.id = t.id;

		--DELETE FROM @t_counter;
		SET @Sum_Actual_value = 0;
	END;

	IF @Sum_Actual_value = 0
		AND @counter_id1 > 0
	BEGIN
		IF @debug = 1
			RAISERROR (N'заполняем данные по ОПУ', 10, 1) WITH NOWAIT;

		SELECT @inspector_date1 = dbo.Fun_GetOnlyDate(end_date)
		FROM dbo.Global_values AS GV
		WHERE fin_id = @fin_current;

		EXEC k_counter_value_add3 @counter_id1 = @counter_id1
								, @inspector_value1 = 0
								, @inspector_date1 = @inspector_date1
								, @actual_value = @value_source1
								, @blocked1 = 0
								, @comments1 = N'взято из перерасчётов'
								, @volume_arenda = @volume_arenda
								, @volume_odn = @volume_odn
								, @volume_direct_contract = @volume_direct_contract
	END;

	IF @debug = 1
		RAISERROR (N'заполняем данные по нежилым помещениям дома', 10, 1) WITH NOWAIT;

	MERGE dbo.Build_arenda AS ba USING (
		SELECT @bldn_id1 AS bldn_id1
			 , @fin_current AS fin_current
			 , @service_in AS service_in
			 , @volume_arenda AS volume_arenda
			 , @ostatok_arenda AS ostatok_arenda
			 , @S_arenda AS S_arenda
	) AS t2
	ON ba.build_id = t2.bldn_id1
		AND fin_id = t2.fin_current
		AND service_id = t2.service_in
	WHEN MATCHED
		THEN UPDATE
			SET kol = t2.volume_arenda
			  , kol_dom = t2.ostatok_arenda
			  , arenda_sq = t2.S_arenda
	WHEN NOT MATCHED
		THEN INSERT
				(build_id
			   , fin_id
			   , service_id
			   , kol
			   , kol_dom
			   , arenda_sq)
				VALUES (t2.bldn_id1
					  , t2.fin_current
					  , t2.service_in
					  , t2.volume_arenda
					  , t2.ostatok_arenda
					  , t2.S_arenda);

LABEL_END:;

	IF @doc_no1 NOT IN ('99999','88888')
	BEGIN
		IF @debug = 1
			RAISERROR (N'делаем перерасчёт по дому', 10, 1) WITH NOWAIT;
		EXEC dbo.k_raschet_build @build_id = @bldn_id1;
	END
	ELSE
	BEGIN		
		UPDATE pl
		SET value = pcb.value
		  , metod = 4
		  , kol = pcb.kol
		  , tarif = pcb.tarif
		  , unit_id = pcb.unit_id
		FROM dbo.Paym_list AS pl
			JOIN dbo.Paym_occ_build AS pcb ON 
				pcb.fin_id = pl.fin_id
				AND pl.occ = pcb.occ
				AND pl.service_id = pcb.service_id
		WHERE pcb.fin_id = @fin_id1
		AND pcb.tarif > 0;
	END
END;
go

