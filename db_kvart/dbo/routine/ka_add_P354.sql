CREATE   PROCEDURE [dbo].[ka_add_P354]
	  @bldn_id1 INT
	, @service_id1 VARCHAR(10) -- код услуги
	, @fin_id1 SMALLINT -- фин. период
	, @value_source1 DECIMAL(15, 2) = 0 -- Объем по счётчику ОДПУ
	, @doc1 VARCHAR(100) = NULL -- Документ
	, @doc_no1 VARCHAR(15) = NULL -- номер акта  -- '99999'-не делать расчеты кварплаты ,'88888'-не делать завершающий расчет квартплаты по дому
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
	, @avg_volume_m2 DECIMAL(14, 6) = 0  -- средний расход услуги на м2
	, @volume_direct_contract DECIMAL(15, 6) = 0 -- объём услуги по прямым договорам
	, @block_noliving BIT = 0 -- не использовать не жилые помещения в расчете
/*

Вызов процедуры:

DECLARE	@addyes int 
exec [dbo].ka_add_P354 @bldn_id1 = 5849,@service_id1 = N'хвод',@fin_id1 = 172,
		@value_source1 = 924,@doc1 = N'Тест',@doc_no1=99999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0, @volume_gvs=0, @serv_dom='хвсд',@flag=1,@use_add=1,@occ_test=910000432
select @addyes
		
DECLARE	@addyes int 
exec [dbo].ka_add_P354 @bldn_id1 = 5849,@service_id1 = N'гвод',@fin_id1 = 172,
		@value_source1 = 924,@doc1 = N'Тест',@doc_no1=99999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0, @volume_gvs=0, @serv_dom='гвсд',@flag=1,@use_add=1,@occ_test=910000432
		
exec [dbo].[ka_add_F9] @bldn_id1 = 3508,@service_id1 = N'вотв',@fin_id1 = 121,
		@value_source1 = 768,@doc1 = N'Тест',@doc_no1=999, @debug=1, @ras_add=1, @addyes = @addyes OUTPUT		

22/06/2012
используем перерасчёты и количество услуги высчитываем сами
		
*/
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @DB_NAME VARCHAR(30) = UPPER(DB_NAME())
		  , @is_IVC BIT = 0
		  , @tip_id SMALLINT
		  , @is_ValueBuildMinus BIT -- Разрешить ОДН с минусом
		  , @odn_big_norma BIT -- ОДН может быть большенормы
			--@odn_min_norma_no	BIT,  -- не распределять ОДН если она меньше чем ОДН по норме
		  , @is_not_allocate_economy BIT = 1 -- не распределять экономию (по людям). Оставлять по норме.
		  , @soi_metod_calc VARCHAR(10) = 'CALC_TARIF' -- метод расчета СОИ CALC_TARIF или CALC_KOL
		  , @soi_is_transfer_economy BIT		  

	SELECT @tip_id = vb.tip_id
		 , @S_arenda = CASE WHEN @S_arenda IS NULL THEN COALESCE(vb.arenda_sq, 0) ELSE @S_arenda END
		 , @is_ValueBuildMinus = CASE WHEN vb.is_value_build_minus = 1 THEN vb.is_value_build_minus ELSE OT.is_ValueBuildMinus  END
		 , @is_not_allocate_economy = CASE WHEN vb.is_not_allocate_economy = 0 THEN OT.is_not_allocate_economy ELSE 0 END
		 , @soi_metod_calc = OT.soi_metod_calc
		 , @soi_is_transfer_economy =
			CASE WHEN vb.soi_is_transfer_economy = 1 THEN vb.soi_is_transfer_economy ELSE ot.soi_is_transfer_economy END --вначале берем из дома
	FROM dbo.View_build_all AS vb
		JOIN dbo.Occupation_Types OT ON vb.tip_id = OT.id
	WHERE vb.fin_id = @fin_id1
		AND vb.bldn_id = @bldn_id1;

	IF @serv_dom IN (
			SELECT id
			FROM dbo.Services s
			WHERE s.service_type = 1
		)
		--AND @soi_metod_calc = 'CALC_TARIF'
	BEGIN
		EXECUTE [dbo].[ka_add_P354_SOI] @bldn_id1 = @bldn_id1
									  , @service_id1 = @service_id1
									  , @fin_id1 = @fin_id1
									  , @value_source1 = @value_source1
									  , @doc1 = @doc1
									  , @doc_no1 = @doc_no1
									  , @doc_date1 = @doc_date1
									  , @debug = @debug
									  , @addyes = @addyes OUTPUT
									  , @volume_arenda = @volume_arenda
									  , @volume_gvs = @volume_gvs
									  , @serv_dom = @serv_dom
									  , @flag = @flag
									  , @use_add = @use_add
									  , @S_arenda = @S_arenda
									  , @occ_test = @occ_test
									  , @sup_id = @sup_id
									  , @tarif = @tarif
									  , @volume_odn = @volume_odn
									  , @norma_odn= @norma_odn
									  , @set_soi_zero = @set_soi_zero
									  , @volume_direct_contract = @volume_direct_contract
		RETURN;
	END
	IF @debug=1 
		PRINT 'ka_add_P354'
	
	IF dbo.Fun_AccessAddBuild(@bldn_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END
	
	IF dbo.strpos('KR1', @DB_NAME) > 0 SET @is_IVC=1

	DECLARE @Vnr DECIMAL(15, 4)
		  , @Vnn DECIMAL(15, 4)
		  , @Vob DECIMAL(15, 4) = 0
		  , @VobEconomy DECIMAL(15, 4) = 0
		  , @value_raspred DECIMAL(15, 4) = 0
		  , @value_add_kol DECIMAL(15, 4) = 0
		  , @occ INT
		  , @total_sq DECIMAL(10, 4)
		  , @total_sq_save DECIMAL(10, 4)
		  , @Total_sq_noliving DECIMAL(10, 4)
		  , @KolPeopleItog SMALLINT
		  , @comments VARCHAR(100) = ''
		  , @ostatok_arenda DECIMAL(15, 4) = 0
		  , @sum_add DECIMAL(15, 2)
		  , @sum_value DECIMAL(15, 2)
		  , @sum_kol DECIMAL(15, 6) = 0
		  , @ostatok DECIMAL(9, 2)		
		  , @value_start DECIMAL(15, 6) = 0 -- Объём для распределения с предыдущего периода

		  , @fin_current SMALLINT
		  , @str_koef VARCHAR(50)
		  , @str_formula VARCHAR(10) = N'Ф11'
		  , @service_in VARCHAR(10) -- Код услуги на входе			
		  , @flat_id1 INT
		  , @KolDayFinPeriod TINYINT -- кол-во дней в фин периоде			
		  , @start_date SMALLDATETIME

		  , @service_pk VARCHAR(10) -- услуга с превышением норматива
		  , @is_boiler BIT -- есть бойлер
		  , @NormaGvsOdn DECIMAL(12, 6) = 0.041 -- норматив на ГВС на ОДН
		  , @NormaXvsOdn DECIMAL(12, 6) = 0.041 -- норматив на ХВС на ОДН
		  , @sup_id_boiler INT = 0
		  , @services_boiler VARCHAR(20) = '' -- список услуг с бойлером с противоположной услугой
		  , @CountOccCounter INT
		  , @CountOccCounterMetodAVG INT -- кол-во лицевых со расчетом по среднему
		  , @CountOccNoCounter INT
		  , @SquareOccCounter DECIMAL(9, 2)
		  , @SquareOccNoCounter DECIMAL(9, 2)
		  , @S_arenda_occ DECIMAL(9, 2)
		  , @build_total_sq_serv DECIMAL(10, 4)

	SELECT @addyes = 0
		 , @service_in = @service_id1;

	SELECT @service_pk = '';
	--CASE
	--	WHEN @service_id1 = 'хвод' THEN 'хвпк'
	--	WHEN @service_id1 = 'гвод' THEN 'гвпк'
	--	ELSE ''
	--END
	SET @block_noliving = COALESCE(@block_noliving,0)
	SET @volume_arenda = COALESCE(@volume_arenda, 0)	
	SET @volume_gvs = COALESCE(@volume_gvs, 0)
	SET @flag = COALESCE(@flag,0)
	SET @use_add = COALESCE(@use_add, 1)
	
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL);

	SELECT @start_date = start_date
	FROM dbo.Global_values AS GV 
	WHERE fin_id = @fin_current

	SELECT @odn_big_norma = COALESCE(b.odn_big_norma, 0)
		 , @is_boiler = COALESCE(b.is_boiler, 0)
	FROM dbo.Buildings AS B 
	WHERE b.id = @bldn_id1

	SELECT @build_total_sq_serv = COALESCE(build_total_sq, 0)
	FROM dbo.Services_build 
	WHERE build_id=@bldn_id1
	 AND service_id=@service_id1

	SELECT @KolDayFinPeriod = DATEDIFF(DAY, @start_date, DATEADD(MONTH, 1, @start_date));

	IF @fin_id1 = @fin_current
	BEGIN
		IF @debug=1 RAISERROR ('удаляем общедомовые по дому', 0, 1) WITH NOWAIT;

		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb 
			JOIN dbo.View_occ_all AS o ON 
				pcb.fin_id = o.fin_id
				AND pcb.occ = o.occ
		WHERE pcb.fin_id = @fin_current
			AND (pcb.service_id IN (@service_id1, @serv_dom) OR pcb.service_id='')
			AND o.bldn_id = @bldn_id1;

		DELETE pcb
		FROM dbo.[Build_source_value] AS pcb 
		WHERE pcb.fin_id = @fin_current
			AND (pcb.service_id IN (@service_id1, @serv_dom) OR pcb.service_id='')
			AND pcb.build_id = @bldn_id1;
	END;

	IF @value_source1 < 0
		RETURN;

	--IF @fin_current <> @fin_id1
	--BEGIN
	--	RAISERROR ('Задайте текущий фин период в доме!', 16, 1)
	--	RETURN -1
	--END

	IF (@fin_current = @fin_id1)
		AND @doc_no1 <> '99999'
	BEGIN
		IF @debug=1 RAISERROR ('делаем расчёт по дому', 0, 1) WITH NOWAIT 

		DECLARE curs CURSOR LOCAL FOR
			SELECT voa.occ
				 , voa.flat_id
			FROM dbo.VOcc voa
				JOIN dbo.Occupation_Types AS ot ON 
					voa.tip_id = ot.id
			WHERE status_id <> 'закр'
				AND voa.bldn_id = @bldn_id1
				--AND ot.state_id = N'норм' -- где тип фонда открыт для редактирования
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
			EXEC dbo.k_raschet_2 @Occ1 = @occ
							   , @fin_id1 = @fin_current;

			FETCH NEXT FROM curs INTO @occ, @flat_id1;
		END;

		CLOSE curs;
		DEALLOCATE curs;
	END;

	-- Если есть специальная площадь по услуге по нежилым
	IF COALESCE(@S_arenda,0)=0
		SELECT @S_arenda = arenda_sq
		FROM dbo.Build_arenda AS ba 
		WHERE fin_id = @fin_id1
			AND build_id = @bldn_id1
			AND service_id = @service_in;
	
	IF @S_arenda IS NULL
		SET @S_arenda = 0;

	if @soi_is_transfer_economy=1
	BEGIN
		SELECT @value_start=coalesce(ch.V_start,0)
		FROM dbo.CounterHouse AS ch
		WHERE ch.service_id=@service_id1
			AND ch.tip_id=@tip_id
			AND ch.build_id=@bldn_id1
			AND ch.fin_id=@fin_id1

		IF @service_id1<>'отоп'  -- по отоп с прошлого периода не переносим
		BEGIN
			SELECT @value_start=coalesce(ch.V_economy,0)
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

	DECLARE @t TABLE (
		  occ INT                      -- PRIMARY KEY
		, service_id VARCHAR(10)
		, sup_id INT
		, nom_kvr VARCHAR(20) DEFAULT ''
		, tarif DECIMAL(10, 4) DEFAULT 0
		, kol DECIMAL(15, 6) DEFAULT 0
		, kol_itog DECIMAL(15, 6) DEFAULT 0
		, is_counter BIT DEFAULT 0
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, value DECIMAL(9, 2) DEFAULT 0
		, value_add DECIMAL(9, 2) DEFAULT 0
		, value_add_kol DECIMAL(15, 6) DEFAULT 0
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, sum_value DECIMAL(9, 2) DEFAULT 0
		, kol_add DECIMAL(15, 6) DEFAULT 0
		, comments VARCHAR(100) DEFAULT ''
		, norma DECIMAL(9, 2) DEFAULT 0
		, metod TINYINT DEFAULT 0
		, unit_id VARCHAR(10) DEFAULT NULL
		, kol_people TINYINT DEFAULT 0
		, mode_id INT DEFAULT 0
		, source_id INT DEFAULT 0
		, kol_norma_odn DECIMAL(15, 6) DEFAULT 0
		, kol_tmp DECIMAL(15, 6) DEFAULT 0
		, kol_excess DECIMAL(15, 6) DEFAULT 0 -- превышение ОДН
		, koef_day DECIMAL(9, 4) DEFAULT 1
		, proptype_id VARCHAR(10) DEFAULT NULL
		, roomtype_id VARCHAR(10) DEFAULT NULL
		, kol_old DECIMAL(15, 6) DEFAULT 0
		, PRIMARY KEY (occ, service_id)
	);

	-- Таблица лицевых для которых не надо считать общедомовые нужды	
	DECLARE @t_occ_opu_no TABLE (
		  occ INT
	);

	DECLARE @t_serv_choice TABLE (
		  service_id VARCHAR(10)
	);
	IF @service_id1='тепл'
		INSERT INTO @t_serv_choice(service_id) VALUES('тепл')
	ELSE
		INSERT INTO @t_serv_choice(service_id) VALUES(@service_id1), (@service_pk)

	-- список услуг по перерасчётам
	DECLARE @t_serv_add TABLE (
		  service_id VARCHAR(10)
	);
	IF @service_id1 IN ('хвс2', 'хвод')
		INSERT INTO @t_serv_add(service_id)	VALUES ('хвс2'), ('хвод')
	IF @service_id1 IN ('гвс2', 'гвод')
		INSERT INTO @t_serv_add(service_id) VALUES ('гвс2'), ('гвод')

	IF NOT EXISTS (
			SELECT 1
			FROM @t_serv_add
			WHERE service_id = @service_id1
		)
		INSERT INTO @t_serv_add
			(service_id)
			VALUES (@service_id1)

	IF @service_id1 in ('отоп','тепл')
		SET @serv_dom=''

	--IF @service_kol IS NULL SET @service_kol=@service_id1
	--IF @debug = 1 PRINT '1'
	-- находим кол-во
	INSERT INTO @t
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
	   , kol_people
	   , tarif
	   , koef_day
	   , proptype_id
	   , roomtype_id
	   , kol_old)
	SELECT oh.occ
		 , @service_id1
		 , COALESCE(ph.sup_id, 0)
		 , SUM(COALESCE(ph.kol, 0))
		 , COALESCE(ph.is_counter, 0)
		 , SUM(COALESCE(ph.value, 0))
		 , SUM(COALESCE(t_add.value, 0))  -- value_add
		 , SUM(COALESCE(t_add.kol, 0)) -- value_add_kol
		 , oh.nom_kvr
		 , ph.metod                 -- когда по норме должен быть NULL
		 , ph.unit_id
		 , COALESCE((
			   SELECT COUNT(id)
			   FROM dbo.View_people_all AS P 
					JOIN dbo.Person_calc AS PC ON 
						P.status2_id = PC.status_id
			   WHERE P.occ = oh.occ
				   AND P.fin_id = @fin_id1
				   --AND P.Del = 0
				   AND PC.service_id = @service_id1
				   AND PC.have_paym = 1
		   ), 0) AS kol_people
		 , CASE
               WHEN COALESCE(@tarif, 0) = 0 THEN COALESCE(ph.tarif, 0)
               ELSE @tarif
        END                         -- если тариф не задан на входе
		 , MAX(CASE
                   WHEN @is_IVC = 0 THEN 1
                   ELSE COALESCE(ph.koef_day, 1)
        END)
		 , MAX(oh.proptype_id)
		 , MAX(oh.roomtype_id)		 
		 , SUM(COALESCE(ph.kol, 0)) -- kol_old
	FROM dbo.View_occ_all AS oh 
		LEFT JOIN dbo.View_paym AS ph ON 
			oh.fin_id = ph.fin_id		
			AND oh.occ = ph.occ
			--AND ph.service_id IN (@service_id1, @service_pk)
			AND (@sup_id IS NULL OR ph.sup_id = @sup_id)
		JOIN @t_serv_choice as s ON 
			ph.service_id=s.service_id
		OUTER APPLY (
			SELECT SUM(ap.value) AS value
				 , SUM(COALESCE(ap.kol,0)) AS kol
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
	WHERE 
		oh.bldn_id = @bldn_id1
		AND oh.fin_id = @fin_id1
		AND oh.status_id <> 'закр'
		AND oh.total_sq>0  -- 21.09.2022
	GROUP BY oh.occ
			 --, ph.service_id
		   , ph.sup_id
		   , ph.is_counter
		   , oh.nom_kvr
		   , ph.metod
		   , ph.unit_id
		   , ph.tarif;

	-- 23.12.2013				
	UPDATE t
	SET kol = 0--,value=0,value_add=0
	FROM @t AS t
		JOIN @t_occ_opu_no AS t_no ON t.occ = t_no.occ;

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
	FROM @t AS t
		JOIN dbo.View_consmodes_all AS cl ON 
			t.occ = cl.occ
	WHERE cl.fin_id = @fin_id1
		AND cl.service_id = @service_id1
		AND cl.sup_id = t.sup_id;

	UPDATE t
	SET total_sq = o.total_sq
	  , kol_itog = kol
	FROM @t AS t
		JOIN dbo.Occupations AS o ON 
			t.occ = o.occ;

	UPDATE t
	SET kol_norma_odn = vp.kol
	FROM @t AS t
		JOIN dbo.View_paym vp ON 
			t.occ = vp.occ
			AND vp.fin_id = @fin_current
			AND vp.service_id = @serv_dom
			AND t.sup_id = vp.sup_id;

	if @debug=1
		SELECT 'vp @serv_dom',t.*, vp.kol
		FROM @t AS t
			JOIN dbo.View_paym vp ON 
				t.occ = vp.occ
				AND vp.fin_id = @fin_current
				AND vp.service_id = @serv_dom
				AND t.sup_id = vp.sup_id;

	DECLARE @unit_id VARCHAR(10) = 'кубм';

	IF @service_id1 IN ('отоп')
		SET @unit_id = 'ггкл';

	--IF @debug=1 SELECT * FROM @t

	IF COALESCE(@tarif, 0) = 0 -- если тариф не задан на входе
	BEGIN
		IF @service_id1 IN ('элек', 'элмп', 'эле2', 'Эдом')
		BEGIN
			IF @is_boiler = 1
				SET @is_boiler = 0

			SELECT @unit_id = 'квтч'

			IF COALESCE(@tarif, 0) = 0
			BEGIN
				UPDATE t
				SET tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, @service_id1, @unit_id)
				FROM @t AS t;
				--WHERE tarif = 0
				--OR tarif IS NULL
			END

		END
		ELSE
		BEGIN
			UPDATE t
			SET tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, CASE
				WHEN @service_id1 = N'гвс2' THEN N'гвод'
				WHEN @service_id1 = N'хвс2' THEN N'хвод'
				ELSE @service_id1
			END, @unit_id)
			FROM @t AS t
			WHERE coalesce(tarif,0)=0
			AND (t.value<>0 OR t.value_add<>0)
		END
	END
	
	IF COALESCE(@volume_odn, 0)<>0 
	BEGIN  -- берём тариф по общедомовой услуги
		UPDATE t
		SET tarif = p.tarif
		FROM @t AS t
			JOIN dbo.Paym_list as p ON 
				t.occ=p.occ 
				AND p.service_id=@serv_dom 
				and p.fin_id=@fin_id1
		WHERE (t.tarif = 0 OR t.tarif IS NULL);
	END

	SELECT TOP (1) @tarif = COALESCE(tarif, 0)
	FROM @t
	WHERE tarif > 0
	ORDER BY tarif DESC;

	IF @debug=1 PRINT 'tarif='+str(@tarif,12,4);

	IF COALESCE(@tarif, 0) = 0 AND COALESCE(@volume_odn, 0)=0
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@serv_dom)
		RAISERROR (N'Не удалось определить тариф по услуге %s', 16, 1, @comments);
		RETURN -1
	END;

	UPDATE t
	SET norma = dbo.Fun_GetNormaSingle(@unit_id, t.mode_id, 1, @tip_id, @fin_id1)
	FROM @t AS t
	WHERE unit_id = 'люди';

	--IF @debug=1 SELECT * FROM @t

	IF @use_add = 0
		UPDATE t
		SET value_add_kol = 0
		FROM @t AS t
		WHERE value_add_kol <> 0;

	UPDATE t
	SET kol_itog = kol * norma
	FROM @t AS t
	WHERE unit_id = 'люди';

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
	FROM @t AS t
	
	--IF @debug = 1
	--	SELECT coalesce(sum(value_add_kol), 0) AS value_add_kol
	--	FROM
	--		@t

	IF @debug = 1
		SELECT '@t', *
		FROM @t
		ORDER BY dbo.Fun_SortDom(nom_kvr);

	--IF @debug=1 SELECT COALESCE(SUM(kol), 0) AS kol FROM @t;
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod is null
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod=3
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=1 or metod=3

	SELECT @total_sq = SUM(CAST(total_sq * koef_day AS DECIMAL(9,2)) ) --12.10.2022
	,@Total_sq_noliving = SUM(CASE
                                  WHEN roomtype_id NOT IN (N'комм', N'об06', N'об10', N'отдк')
                                      THEN CAST(total_sq * koef_day AS DECIMAL(9, 2))
                                  ELSE 0
        END)
	,@S_arenda_occ = COALESCE(SUM(CASE
                                      WHEN proptype_id = N'арен' THEN CAST(total_sq * koef_day AS DECIMAL(9, 2))
                                      ELSE 0
        END), 0)
	FROM @t
	WHERE (source_id%1000)<>0  -- добавил условие 12.10.2022

	IF @block_noliving=1 and @Total_sq_noliving<>0
	BEGIN
		if @debug=1 SELECT @total_sq as 'Площадь до уменьшения', @Total_sq_noliving as Total_sq_noliving
		SELECT @total_sq = @total_sq - @Total_sq_noliving
		--DELETE t FROM @t as t WHERE roomtype_id NOT IN (N'комм', N'об06', N'об10', N'отдк')		
	END

	SELECT @KolPeopleItog = SUM(kol_people)
	FROM @t
	WHERE is_counter =
          CASE
              WHEN @flag = 0 THEN 0
              ELSE is_counter
              END -- раскидка на лицевые без счётчиков

	SELECT @Vnn = COALESCE(SUM(kol_itog), 0), @CountOccNoCounter=COALESCE(COUNT(occ),0), @SquareOccNoCounter=COALESCE(SUM(total_sq),0)
	FROM @t
	WHERE (is_counter = 0 AND metod IS NULL)
	AND (mode_id%1000<>0)
	--(is_counter = 1	AND metod=1)

	SELECT @Vnr = COALESCE(SUM(kol_itog), 0), @CountOccCounter=COALESCE(COUNT(occ),0), @SquareOccCounter=COALESCE(SUM(total_sq),0)
	FROM @t
	WHERE NOT (is_counter = 0 AND metod IS NULL)
	AND (mode_id%1000<>0)
	--is_counter = 1
	--	OR metod IN (2, 3, 4)

	SELECT @value_add_kol = SUM(value_add_kol)
	FROM @t AS t;

	IF @debug = 1
		SELECT COALESCE(SUM(kol_itog), 0) AS kol_itog
			 , @Vnn as Vnn
			 , @Vnr as Vnr
			 , @odn_big_norma AS odn_big_norma
			 , @is_not_allocate_economy AS is_not_allocate_economy
			 , @is_ValueBuildMinus AS is_ValueBuildMinus
			 , COALESCE(SUM(value_add), 0) AS value_add
			 , COALESCE(SUM(value_add_kol), 0) AS value_add_kol
			 , @is_boiler AS is_boiler			 
			 , @flag AS flag
			 , @soi_is_transfer_economy AS soi_is_transfer_economy
			 , @value_start as value_start
			 , @service_id2 AS service_id2
			 , @service_id1 AS service_id1
			 , @service_in AS service_in
			 , @serv_dom AS serv_dom
			 , @volume_direct_contract AS volume_direct_contract
			 , @volume_odn AS volume_odn
			 , @unit_id AS unit_id
			 , @S_arenda_occ AS S_arenda_occ
			 , @total_sq AS total_sq
			 , @Total_sq_noliving AS Total_sq_noliving
			 , @build_total_sq_serv AS build_total_sq_serv
			 , @avg_volume_m2 AS avg_volume_m2
		FROM @t

	IF (@service_id1 = 'отоп') 
	BEGIN							
		SELECT @CountOccCounterMetodAVG = SUM(CASE WHEN is_counter = 1 AND metod <> 3 THEN 1 ELSE 0 END)
			, @CountOccCounter = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN 1 ELSE 0 END)
			, @CountOccNoCounter = SUM(CASE WHEN is_counter = 0 THEN 1 ELSE 0 END)
			, @Vnr = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN kol_itog ELSE 0 END)
			, @SquareOccCounter = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN total_sq ELSE 0 END)
			, @SquareOccNoCounter = SUM(CASE WHEN is_counter = 0 OR (is_counter = 1 AND metod <> 3) THEN total_sq ELSE 0 END)
		FROM @t
		WHERE (mode_id%1000<>0) 
		
		IF @debug = 1 
			SELECT @CountOccCounter as CountOccCounter, @CountOccNoCounter as CountOccNoCounter, @CountOccCounterMetodAVG AS CountOccCounterMetodAVG

		IF (@CountOccCounter>0) AND ((@CountOccNoCounter>0) OR (@CountOccCounterMetodAVG>0))
		BEGIN
			IF @debug = 1 PRINT 'по отоплению есть ИПУ и есть по норме'
		
			IF @avg_volume_m2=0
			BEGIN
				--SELECT @avg_volume_m2 = CAST(@Vnr/@SquareOccCounter AS DECIMAL(15,6))

				SELECT @avg_volume_m2 = CAST(sum(kol)/sum(total_sq) AS DECIMAL(15,6))  -- kol берём объём без разовых
				FROM @t
				WHERE is_counter = 1 AND metod=3
					--AND (mode_id%1000<>0) --закомментировал 28.03.23
			END
			
			UPDATE t 
			SET kol = total_sq * @avg_volume_m2 * COALESCE(t.koef_day,1)
				,kol_old = total_sq * @avg_volume_m2 * COALESCE(t.koef_day,1)
			FROM @t AS t
			WHERE (mode_id%1000<>0)	AND t.unit_id=N'ггкл'
			AND (
			(is_counter = 0 AND metod IS NULL) 
			OR (is_counter = 1 AND metod<>3) -- где расчет по среднему тоже меняем
			)
		
			-- снова подсчитаем объёмы
			UPDATE t SET kol_itog = kol + value_add_kol -- количество с учетом разовых
			FROM @t AS t
		
			IF @debug = 1
				SELECT '3_7 до', @Vnr as Vnr, @Vnn as Vnn, @CountOccNoCounter as CountOccNoCounter, @SquareOccNoCounter as SquareOccNoCounter
				    ,@avg_volume_m2 AS avg_m2
					,@SquareOccCounter as SquareOccCounter

			
			--SELECT @Vnn = COALESCE(SUM(kol_itog), 0), @CountOccNoCounter=COALESCE(COUNT(occ),0), @SquareOccNoCounter=COALESCE(SUM(total_sq),0)
			--FROM @t
			--WHERE (is_counter = 0 AND metod IS NULL)
			--	AND (mode_id%1000<>0)

			--SELECT @Vnr = COALESCE(SUM(kol_itog), 0) --, @CountOccCounter=COALESCE(COUNT(occ),0), @SquareOccCounter=COALESCE(SUM(total_sq),0)
			--FROM @t
			--WHERE NOT (is_counter = 0 AND metod IS NULL)
			--AND (mode_id%1000<>0)

			SELECT @CountOccCounterMetodAVG=SUM(CASE WHEN is_counter = 1 AND metod = 2 THEN 1 ELSE 0 END)
				, @CountOccCounter = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN 1 ELSE 0 END)
				, @CountOccNoCounter = SUM(CASE WHEN is_counter = 0 THEN 1 ELSE 0 END)				
				, @Vnr = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN kol_itog ELSE 0 END)
				, @SquareOccCounter = SUM(CASE WHEN is_counter = 1 AND metod = 3 THEN total_sq ELSE 0 END)				
				, @Vnn = SUM(CASE WHEN is_counter = 0 OR (is_counter = 1 AND metod <> 3) THEN kol_itog ELSE 0 END)
				, @SquareOccNoCounter = SUM(CASE WHEN is_counter = 0 OR (is_counter = 1 AND metod <> 3) THEN total_sq ELSE 0 END)
			FROM @t
			WHERE (mode_id%1000<>0) 

			IF @debug = 1
				SELECT '3_7 после', @Vnr as Vnr, @Vnn as Vnn, @CountOccNoCounter as CountOccNoCounter, @SquareOccNoCounter as SquareOccNoCounter
				    ,@avg_volume_m2 AS avg_m2
					,@SquareOccCounter as SquareOccCounter
		END
		ELSE
		BEGIN 
			IF @debug = 1 PRINT 'отоп 3_1'

			-- закоментировал 27.03.2023 ========================
			UPDATE t SET kol_itog = COALESCE(value_add_kol,0) + kol  -- оставляем только разовые 
				--, kol = 0  -- 31/10/23
			FROM @t AS t
			WHERE (mode_id%1000<>0)
			--AND (is_counter=0 AND metod IS NULL)

			--SELECT @Vnn=COALESCE(SUM(kol_itog), 0)
			--FROM @t
			--WHERE (mode_id%1000<>0)
			--AND (is_counter = 0 AND metod IS NULL)
			--======================================================
			SELECT @Vnn=COALESCE(SUM(kol_itog), 0) FROM @t WHERE (mode_id%1000<>0)  -- добавил 27.03.23
		END
	END	

	IF (@Vnn = 0 AND @Vnr = 0) AND COALESCE(@volume_odn, 0)=0 AND (@service_id1 <> 'отоп') 
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@service_id1)
		RAISERROR (N'Начислений по услуге %s не было', 16, 1, @comments);
		RETURN -1
	END;

	SET @total_sq_save=@total_sq
	if @build_total_sq_serv>0 -- берём площадь из услуги по дому
		SET @total_sq=@build_total_sq_serv 

	-- В домах где есть бойлер надо суммировать ещё объём другой услуги ГВС или ХВС
	DECLARE @Vnr_serv2 DECIMAL(15, 4) = 0
		  , @value_add_kol_boiler DECIMAL(15, 4) = 0
		  , @tarif_boiler DECIMAL(15, 4) = 0

	-- бойлер **************************************************************************
	-- список услуг по бойлер
	DECLARE @t_serv_boiler TABLE (
			service_id VARCHAR(10)
	);
	
	IF @is_boiler = 1 AND @service_id1 in (N'хвс2', N'хвод', N'гвс2', N'гвод')
	BEGIN
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
					   JOIN dbo.View_occ_all AS oh1 ON 
							ap.occ = oh1.occ
							AND ap.fin_id = oh1.fin_id
				   WHERE ap.fin_id = @fin_id1
					   AND oh1.bldn_id = @bldn_id1
					   AND ap.service_id IN (SELECT service_id FROM @t_serv_boiler)
					   --AND ap.sup_id = ph.sup_id -- @sup_id_boiler
					   AND add_type NOT IN (11, 15)
			   ), 0)
		FROM dbo.View_occ_all AS oh 
			JOIN dbo.View_paym AS ph ON 
				oh.fin_id = ph.fin_id
				AND oh.occ = ph.occ
				--AND ph.sup_id = @sup_id_boiler
		WHERE 
			oh.bldn_id = @bldn_id1
			AND oh.fin_id = @fin_id1
			AND (ph.Paid <> 0 AND ph.kol <> 0)
			AND ph.service_id IN (SELECT service_id FROM @t_serv_boiler)

		IF (@service_id1 = N'вотв')
			AND (@serv_dom = N'одвж')
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
	END
	ELSE
	IF @is_boiler = 1 AND @service_id1 in ('отоп')
	BEGIN
		INSERT INTO @t_serv_boiler(service_id)	VALUES (N'тепл'),(N'одтж')
		
		SELECT @Vnr_serv2 = SUM(COALESCE(ph.kol, 0))
			 , @tarif_boiler = MAX(ph.tarif)
			 , @value_add_kol_boiler = COALESCE((
				   SELECT SUM(ap.kol)
				   FROM dbo.View_added AS ap
					   JOIN dbo.View_occ_all AS oh1 ON 
							ap.occ = oh1.occ
							AND ap.fin_id = oh1.fin_id
				   WHERE ap.fin_id = @fin_id1
					   AND oh1.bldn_id = @bldn_id1
					   AND ap.service_id IN (SELECT service_id FROM @t_serv_boiler)
					   AND add_type NOT IN (11, 15)
			   ), 0)
		FROM dbo.View_occ_all AS oh
			JOIN dbo.View_paym AS ph ON oh.fin_id = ph.fin_id
				AND oh.occ = ph.occ
		WHERE oh.bldn_id = @bldn_id1
			AND oh.fin_id = @fin_id1
			AND (ph.kol <> 0 OR ph.kol_added<>0)
			AND ph.service_id IN (SELECT service_id FROM @t_serv_boiler)

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
		IF @debug = 1 PRINT '@Vnr_serv2: ' + STR(@Vnr_serv2, 10, 4)
	END
	--ELSE
	-- бойлер **************************************************************************
	--SELECT @Vob = @value_source1 - (@volume_arenda + @Vnn + @Vnr + @value_add_kol)
	IF COALESCE(@volume_odn, 0) <> 0
	BEGIN
		SELECT @Vob = @value_start + @volume_odn, @str_koef = dbo.FSTR(@volume_odn, 9, 2) --, @value_source1=0
	END
	ELSE
	BEGIN
		SELECT @Vob = @value_start + @value_source1 - @volume_arenda - @volume_gvs - @Vnn - @Vnr - @Vnr_serv2

		SELECT @str_koef = dbo.FSTR(@value_source1,9,2)+'-'+dbo.FSTR(@volume_arenda,9,2) + 
		'-'+dbo.FSTR(@volume_gvs,9,2)+'-'+dbo.FSTR(@Vnn,9,2)+'-'+dbo.FSTR(@Vnr,9,2)  -- @Vnr_serv2 вычитаем ниже				
	END
	if @debug=1 SELECT @Vob as Vob, @str_koef as str_koef, @volume_odn as volume_odn

	IF @is_boiler = 1 AND @service_id1 in ('тепл')
	BEGIN  
		if @debug=1 PRINT 'Вычисление строки формулы по услуге Теплоэнергия на ГВС (летний период когда отопление не начисляем)'
		
		DECLARE @add_tepl DECIMAL(12,6)=0  -- перерасчеты по тепл
		DECLARE @val_soi_tepl DECIMAL(12,6)=0  -- СОИ по тепл
		DECLARE @val_gvs DECIMAL(12,6)=0  -- Объём гвод
		
		SELECT @val_soi_tepl=SUM(CASE WHEN (ph.service_id='одтж') THEN ph.kol ELSE 0 END)
			,@val_gvs=SUM(CASE WHEN (ph.service_id='гвод') THEN ph.kol ELSE 0 END)
			,@add_tepl=SUM(CASE WHEN (ph.service_id='тепл') THEN COALESCE(t_add.kol,0) ELSE 0 END)
		FROM dbo.View_paym AS ph
			CROSS APPLY (
				SELECT SUM(COALESCE(ap.kol,0)) AS kol
				FROM dbo.View_added AS ap 
				WHERE ap.occ = ph.occ
					AND ap.fin_id = ph.fin_id
					AND ap.service_id = ph.service_id
					AND ap.add_type NOT IN (11, 15)
				) AS t_add
		WHERE ph.build_id = @bldn_id1
			AND ph.fin_id = @fin_id1
			AND ph.service_id in ('гвод','одтж','тепл')
		
		-- берём объёмы с ГВС
		UPDATE t
		SET kol = ph.kol
		FROM @t AS t
		JOIN dbo.View_paym AS ph ON 
			t.occ=ph.Occ
		WHERE ph.build_id = @bldn_id1
			AND ph.fin_id = @fin_id1
			AND ph.service_id='гвод';

		SELECT @Vob = (@value_source1 - @add_tepl - @val_soi_tepl) / @val_gvs
		SELECT @str_koef = '('+dbo.FSTR(@value_source1,9,2)+'-'+dbo.FSTR(@add_tepl,12,6)+'-'+dbo.FSTR(@val_soi_tepl,12,6)+')/'+dbo.FSTR(@val_gvs,12,6)
		if @debug=1 PRINT @str_koef	+ ' = ' + dbo.FSTR(@Vob,12,6)	
	END

	IF @set_soi_zero=1
	BEGIN
		if @debug=1 PRINT '@set_soi_zero=1'
		GOTO LABEL_SET_ZERO
	END

	IF @value_start<>0
		SELECT @str_koef=dbo.FSTR(@value_start, 10, 4)+'+'+@str_koef

	IF @is_boiler = 1
	BEGIN
		IF (@service_id1 = N'вотв')
			AND (@serv_dom = N'одвж')
			SELECT @str_formula = N'Ф11_1'
				 , @str_koef = '(' + @str_koef + '-' + dbo.FSTR(@Vnr_serv2, 9, 2) + ')'
		ELSE
		IF @service_id1 in (N'хвс2', N'хвод', N'гвс2', N'гвод')
			SELECT @Vob = @Vob * 0.5
				 , @str_formula = N'Ф11_1'
				 , @str_koef = '(' + @str_koef + '-' + dbo.FSTR(@Vnr_serv2, 9, 2) + ')*0,5'
		ELSE
		IF @service_id1 in ('тепл')
			SELECT @Vob = @Vob
				 , @str_formula = 'Ф20'
				 , @str_koef = @str_koef
		ELSE
			SELECT @str_formula = N'Ф11_1'
				 , @str_koef = '(' + @str_koef + '-' + dbo.FSTR(@Vnr_serv2, 9, 2) + ')'  -- в @Vnr_serv2 сидит теплоэнергия
	END

	if @debug=1 SELECT @Vob as Vob, @str_koef as str_koef

	if @Vob<0 -- AND @soi_is_transfer_economy=1
	BEGIN
		SELECT @VobEconomy=@Vob
		IF @debug=1 PRINT CONCAT('Экономия на след.месяц: ', dbo.NSTR(@VobEconomy))
	END

	-- Ф11_1: (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)
	-- Ф11_1(Бойлер): (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*0,5
	IF @Vob > 0
		AND @service_in NOT IN ('отоп','тепл')
	BEGIN
		IF @debug = 1
			PRINT N'раскидка по площади на общедомовые нужды ' + dbo.FSTR(@Vob, 15, 4)

		IF @norma_odn>0
		BEGIN
			IF @debug=1 PRINT '@norma_odn > 0'
			
			UPDATE t
			SET kol_add = @norma_odn * total_sq
			  , comments = dbo.FSTR(t.tarif, 6, 2) +'*'+dbo.FSTR(@norma_odn, 12, 6) + '*' + dbo.FSTR(total_sq, 9, 2)
			FROM @t t			

		END
		ELSE
		IF (@total_sq + @S_arenda) > 0
			UPDATE t
			SET --kol_add 
			kol_tmp = @Vob * total_sq / (@total_sq + @S_arenda)
		  , comments = @str_formula + ':((' + @str_koef + ')*' + dbo.FSTR(total_sq, 9, 2) + '/(' +
			dbo.FSTR(@total_sq, 9, 2) + '+' + dbo.FSTR(@S_arenda, 9, 2) + ')'
			FROM @t AS t;
		-- Ф11_1 (Площадь): (ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*ПлощКв/(ПлощДом+ПлощАренда)
		
		IF @odn_big_norma = 1
			UPDATE t
			SET kol_add = kol_tmp
			FROM @t AS t;

		ELSE
			IF (@is_boiler = 0)
				UPDATE t
				SET kol_add =
                    CASE
                        WHEN kol_tmp > kol_norma_odn THEN kol_norma_odn
                        ELSE kol_tmp
                        END
				  , kol_excess =
                    CASE
                        WHEN kol_tmp > kol_norma_odn THEN kol_tmp - kol_norma_odn
                        ELSE 0
                        END
				FROM @t AS t;
			ELSE
				UPDATE t
				SET kol_add = COALESCE(kol_tmp, 0)
				FROM @t AS t;

		--IF @debug=1 SELECT kol_tmp,kol_add FROM @t

		IF (@odn_big_norma = 1 OR @volume_odn>0) AND (@total_sq_save=@total_sq)
		BEGIN  -- когда площадь по паспорту другая, не будем раскидывать остаток
			SELECT @ostatok_arenda = SUM(kol_add)
			FROM @t;
			SELECT @ostatok_arenda = @Vob - @ostatok_arenda;

			IF @S_arenda = 0
				AND @ostatok_arenda <> 0
			BEGIN
				IF @debug = 1
					PRINT N'надо раскидать остаток';

				;WITH cte AS (
					SELECT TOP (1) * FROM @t AS t WHERE kol_add <> 0
				)
				UPDATE cte
				SET kol_add = kol_add + @ostatok_arenda;								
			END;
		END;
		-- сохраняем распределяемый объём
		SELECT @value_raspred = SUM(kol_add)
		FROM @t;

		UPDATE @t
		SET service_id = @serv_dom;
	END
	ELSE
	BEGIN
		IF @service_in NOT IN  ('отоп','тепл')
		BEGIN
			IF @debug = 1
				PRINT CONCAT('Раскидка по людям ', @Vob, ' + объём ИПУ. Надо уменьшать суммы и убирать ОДН')

			UPDATE t
			SET kol_add = @Vob * kol_people / @KolPeopleItog + kol
			  , comments = @str_formula + ':((' + @str_koef + ')*(' + LTRIM(STR(kol_people, 3)) + '/' +
				LTRIM(STR(@KolPeopleItog, 4)) + ')+' + dbo.FSTR(kol, 9, 2)
			FROM @t AS t
			WHERE is_counter =
							  CASE
								  WHEN @flag = 0 THEN 0 -- раскидка на лицевые без счётчиков
								  ELSE is_counter
							  END
				AND @KolPeopleItog > 0
			--AND kol_people>0 AND kol>0
			-- Ф11_1 (Люди): ((ОбщийОбъём-ОбъёмАренды-ОбъёмГвс-ОбъёмНорматив-ОбъёмПУ)*(КолЧел/КолЧелДом)+ОбъёмУслуги)
			--IF @debug = 1
			--BEGIN
			--	SELECT N'люди2'
			--		 , *
			--		 , '@Vob' = @Vob
			--		 , '@KolPeopleItog' = @KolPeopleItog
			--		 , '@flag' = @flag
			--	FROM @t
			--	WHERE occ = @occ_test
			--END

			-- возможно надо закомментировать
			IF @is_ValueBuildMinus = 0 -- закоментровал 30.06.16
				UPDATE t
				SET kol_add = 0
				FROM @t AS t
				WHERE kol_add < 0;

			IF @flag = 0
				UPDATE t
				SET kol_add = kol
				  , comments = N'Оставили показания начисленные по счётчикам'
				FROM @t AS t
				WHERE is_counter = 1;

			IF @is_not_allocate_economy = 1
				--AND @is_ValueBuildMinus = 0  -- 26/11/2014
				UPDATE t
				SET kol_add = kol
				  , comments = N'Оставили начисление'
				FROM @t AS t;

			IF @debug = 1
			BEGIN
				SELECT N'люди3'
					 , *
					 , @Vob
					 , @KolPeopleItog
				FROM @t
				WHERE occ = @occ_test
			END

			--IF @DB_NAME NOT IN ('KR1','ARX_KR1')
			IF @is_ValueBuildMinus = 1
			BEGIN
				IF @debug = 1
					PRINT N'Разрешить ОДН с минусом'
				--IF @debug=1 SELECT nom_kvr,occ,kol,kol_add,service_id,value, value_add_kol, value_add, sum_value FROM @t				
				INSERT INTO @t
					(occ
				   , service_id
				   , kol
				   , kol_add
				   , nom_kvr
				   , comments
				   , sup_id
				   , kol_people)
				SELECT occ
					 , @serv_dom
					 , kol = kol
					   --CASE
					   --	WHEN (kol_add < 0) AND
					   --	ABS(kol_add - kol) > kol THEN -kol
					   --	ELSE (kol_add - kol)
					   --END
					 , kol_add =
                    CASE
                        WHEN (kol_add < 0) AND
                             ABS(kol_add - kol) > kol THEN -kol
                        ELSE (kol_add - kol)
                        END
					 , nom_kvr
					 , comments = comments + ')-' + dbo.FSTR(kol, 9, 2)
					 , sup_id
					 , kol_people
				FROM @t AS t1
				WHERE kol_add - kol <= 0

				--UPDATE t1 SET service_id=@serv_dom
				--FROM
				--	@t AS t1
				--WHERE
				--	service_id <> @serv_dom and kol=0 and value=0				

				DELETE FROM @t
				WHERE service_id <> @serv_dom;

				-- Проверяем остаток
				IF (@total_sq_save=@total_sq)
				BEGIN
					--DECLARE @ostatok DECIMAL(15,4)=0
					SELECT @ostatok = SUM(kol_add)
					FROM @t AS t
					IF @debug = 1
						PRINT 'остаток: ' + STR(@ostatok, 15, 4)
					SELECT @ostatok = @Vob - @ostatok
					IF @debug = 1
						PRINT 'остаток: ' + STR(@ostatok, 15, 4)

					IF @ostatok < 0
						AND @is_not_allocate_economy = 1
						SET @ostatok = 0

					IF @ostatok <> 0
						UPDATE t
						SET kol_add = kol_add + @ostatok
						  , comments = t.comments + ' +остаток'
						FROM (
							SELECT TOP (1) *
							FROM @t
							WHERE ABS(kol_add + @ostatok) <= kol
							ORDER BY kol DESC
						) AS t
				END  --IF (@total_sq_save=@total_sq)
			END
		END
		ELSE
		BEGIN	
			IF @service_id1='тепл'
			BEGIN
				IF @debug = 1 PRINT 'услуга = '+@service_id1
				SET @str_formula = 'Ф20'
				
				UPDATE t
				SET kol_add = @Vob * kol
				  , comments = @str_formula + ': ('+ @str_koef+ ')*' + dbo.FSTR(kol, 12, 6)
				FROM @t AS t
				WHERE (t.mode_id%1000)<>0

			END
			ELSE
			IF @service_in = 'отоп'
			BEGIN			
				IF (@CountOccNoCounter>0) AND (@CountOccCounter>0)
					SET @str_formula = 'Ф3_7'
				ELSE
					SET @str_formula = 'Ф3_1'

				
					UPDATE t
					SET kol_add = @Vob * (total_sq*t.koef_day) / (@total_sq + @S_arenda) + CASE WHEN(t.unit_id=N'ггкл') THEN kol ELSE 0 END
					  , comments = CASE 
					  WHEN @str_formula=N'Ф3_1' 
						THEN @str_formula + ': ('+ @str_koef+ ')*('+ dbo.FSTR(total_sq, 9, 2)+ CASE
																									   WHEN t.koef_day < 1
                                                                                                       THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
                                                                                                   ELSE ''
                          END + ')/('+ dbo.FSTR(@total_sq, 9, 2)+ '+'+ dbo.FSTR(@S_arenda, 9, 2)+ ')+'+ dbo.FSTR(kol, 9, 4)
					  
					  WHEN @str_formula=N'Ф3_7' AND ((is_counter = 0 AND metod IS NULL) or (is_counter = 1 AND metod<>3))
						THEN @str_formula + ': ('+ @str_koef+ ')*('+ dbo.FSTR(total_sq,9,2)+ CASE
                                                                                                 WHEN t.koef_day < 1
                                                                                                     THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
                                                                                                 ELSE ''
                          END + ')/('+ dbo.FSTR(@total_sq, 9, 2)+ '+'+ dbo.FSTR(@S_arenda, 9, 2)+ ')'+
                             CASE
                                 WHEN kol <> 0 AND t.unit_id = N'ггкл' THEN '+(' + dbo.FSTR(total_sq, 9, 2) + '*' +
                                                                            dbo.FSTR(@avg_volume_m2, 9, 4) +
                                                                            CASE
                                                                                WHEN t.koef_day < 1
                                                                                    THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
                                                                                ELSE ''
                                                                                END +
                                                                            ')'
                                 ELSE ''
                                 END
					  
					  WHEN @str_formula=N'Ф3_7' AND (is_counter = 1 AND metod = 3)
						THEN @str_formula + ': ('+ @str_koef+ ')*('+ dbo.FSTR(total_sq,9,2)+ CASE
                                                                                                 WHEN t.koef_day < 1
                                                                                                     THEN '*' + dbo.FSTR(t.koef_day, 9, 4)
                                                                                                 ELSE ''
                          END + ')/('+ dbo.FSTR(@total_sq, 9, 2)+ '+'+ dbo.FSTR(@S_arenda, 9, 2)+ ')+'+ dbo.FSTR(kol, 9, 4)		  
					  ELSE ''
						END
					FROM @t AS t
					WHERE (t.mode_id%1000)<>0
						--AND t.unit_id=N'ггкл'

			END

			--UPDATE t SET kol_add = 0 FROM @t AS t WHERE kol_add < 0;

		END;
	END; -- раскидка по людям
	--IF @debug = 1
	--BEGIN
	--	SELECT N'люди4'
	--		 , *
	--		 , @Vob
	--		 , @KolPeopleItog
	--	FROM @t
	--	WHERE occ = @occ_test
	--END
	--********************************************************
	IF @is_boiler = 1
	BEGIN
		IF @debug = 1
			PRINT N'Бойлер. Находим нормативы на ГВС на ОДН и ХВС на ОДН';

		IF @debug = 1
		BEGIN
			SELECT 'люди5'
				 , *
				 , koef = (@NormaGvsOdn / (@NormaGvsOdn + @NormaXvsOdn))
			FROM @t
			WHERE occ = @occ_test
		END

		if @service_id1 in ('отоп','тепл')
			UPDATE t
			SET kol_excess = kol_add - kol_old
			FROM @t AS t
		else
			UPDATE t
			SET kol_add =
                CASE
                    WHEN kol_add > kol_norma_odn THEN kol_norma_odn
                    ELSE kol_add
                    END
			  , kol_excess =
                CASE
                    WHEN kol_add > kol_norma_odn THEN kol_add - kol_norma_odn
                    ELSE 0
                    END
			FROM @t AS t

		-- сохраняем распределяемый объём
		SELECT @value_raspred = SUM(kol_add)
		FROM @t;

	END;
	--********************************************************		


	UPDATE t
	SET tarif = @tarif
	FROM @t AS t
	WHERE tarif = 0
		AND kol_add <> 0;

	UPDATE t
	SET sum_value = tarif * kol_add
	FROM @t AS t
	WHERE kol_add <> 0;

	SELECT @sum_add = SUM(sum_add)
		 , @sum_value = SUM(sum_value)
		 , @sum_kol = SUM(kol_add)		 
	FROM @t;

	IF @debug = 1
		SELECT @value_start AS '@value_start'
			 , @value_source1 AS '@value_source1'
			 , @volume_arenda AS '@volume_arenda'
			 , @Vnn AS '@Vnn'
			 , @Vnr AS '@Vnr'
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
			 , @sum_add AS '@sum_add'
			 , @sum_value AS '@sum_value'
			 , @sum_kol AS '@sum_kol'

	IF @debug = 1
		SELECT t = '@t'
			 , *
		FROM @t
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
		FROM @t AS t;
		SELECT @addyes = @@rowcount;

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
		JOIN @t AS t ON pcb.occ = t.occ
	WHERE pcb.fin_id = @fin_current
		AND (pcb.service_id IN (@service_id1, @serv_dom) OR pcb.service_id='');

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
		 , tarif
		 , t.sum_value
		 , t.comments
		 , t.unit_id
		 , 'ka_add_P354' AS procedura
		 , CASE
				WHEN service_id=@serv_dom THEN t.kol_norma_odn - t.kol_add
				ELSE t.kol - t.kol_add
		   END AS kol_add
		 , t.metod
		 , @service_in
		 , t.kol_excess
		 , COALESCE(t.sup_id, 0)
		 , t.koef_day
		 , t.kol_old
	FROM @t AS t
	WHERE t.service_id<>''
	SELECT @addyes = @@rowcount;

	COMMIT TRAN;
	--PRINT '@addyes='+str(@addyes)

LABEL_SET_ZERO:
	IF (@service_id1 <> @serv_dom AND @serv_dom<>'') 
		OR (@set_soi_zero=1) AND (@serv_dom<>'')
	BEGIN
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
			 , N'Обнуляем чтобы не было ОДН по норме'
			 , t.unit_id --= @unit_id
			 , 'ka_add_P354' AS procedura
			 , 0
			 , t.metod
			 , @service_in
			 , COALESCE(t.sup_id, 0)
			 , - t.kol_old  --t.kol_norma_odn
			 , t.koef_day
			 , t.kol_old
		FROM @t AS t
		WHERE service_id <> @serv_dom
			AND @serv_dom<>''
		SELECT @addyes = @@rowcount;
	END

	--PRINT '@addyes='+str(@addyes)+' @service_id1='+@service_id1+' @serv_dom='+@serv_dom

	IF @debug = 1
		PRINT N'сохраняем итоговые данные по дому , использованные в расчёте'
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
			  , value_raspred = @value_raspred
			  , value_start = @value_start
			  , value_odn = @volume_odn
			  , avg_volume_m2 = @avg_volume_m2
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
			   , value_odn
			   , avg_volume_m2)
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
					  , @value_raspred
					  , COALESCE(@volume_odn, 0)
					  , @avg_volume_m2);

	--**************************************************************
	DECLARE @counter_id1 INT = NULL;
	SELECT @counter_id1 = id
	FROM dbo.View_counter_build AS vcb
	WHERE build_id = @bldn_id1
		AND service_id = @service_in
		AND unit_id = @unit_id
		AND vcb.date_del is NULL

	IF @counter_id1 IS NULL
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
		RAISERROR (N'Добавляем показание по счётчику', 0, 1) WITH NOWAIT;
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
			JOIN @t_counter AS t ON ci.id = t.id;

		--DELETE FROM @t_counter;
		SET @Sum_Actual_value = 0;
	END;

	IF @Sum_Actual_value = 0
	BEGIN
		IF @debug = 1
			RAISERROR (N'заполняем данные по ОПУ', 0, 1) WITH NOWAIT;

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
		RAISERROR (N'заполняем данные по нежилым помещениям дома', 0, 1) WITH NOWAIT;
	MERGE dbo.Build_arenda AS ba USING (
		SELECT @bldn_id1 AS bldn_id1
			 , @fin_current AS fin_current
			 , @service_in AS service_in
			 , @volume_arenda AS volume_arenda
			 , @ostatok_arenda AS ostatok_arenda
			 , @S_arenda AS S_arenda
			 , @volume_gvs AS volume_gvs
	) AS t2
	ON ba.build_id = t2.bldn_id1
		AND fin_id = t2.fin_current
		AND service_id = t2.service_in
	WHEN MATCHED
		THEN UPDATE
			SET kol = t2.volume_arenda
			  , kol_dom = t2.ostatok_arenda
			  , arenda_sq = t2.S_arenda
			  , volume_gvs = t2.volume_gvs
	WHEN NOT MATCHED
		THEN INSERT
				(build_id
			   , fin_id
			   , service_id
			   , kol
			   , kol_dom
			   , arenda_sq
			   , volume_gvs)
				VALUES (t2.bldn_id1
					  , t2.fin_current
					  , t2.service_in
					  , t2.volume_arenda
					  , t2.ostatok_arenda
					  , t2.S_arenda
					  , t2.volume_gvs);

LABEL_END:

	IF @doc_no1 NOT IN ('99999','88888')
	BEGIN
		IF @debug = 1
			RAISERROR (N'делаем расчёт по дому', 0, 1) WITH NOWAIT;
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
		  , kol_norma = COALESCE(pcb.kol_old,0)  -- сохраняем расчитанный объём
		FROM dbo.Paym_list AS pl
			JOIN dbo.Paym_occ_build AS pcb ON pcb.fin_id = pl.fin_id
				AND pl.occ = pcb.occ
				AND pl.service_id = pcb.service_id
		WHERE pcb.fin_id = @fin_id1
		AND pcb.tarif > 0
	END
END
go

