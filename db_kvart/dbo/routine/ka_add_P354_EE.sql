CREATE   PROCEDURE [dbo].[ka_add_P354_EE]
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
	, @occ_test INT = 0  -- лиц.счёт для тестирования расчётов
	, @tarif DECIMAL(9, 4) = 0
	, @volume_odn DECIMAL(14, 6) = 0 -- объём по ОДН
	, @norma_odn DECIMAL(12, 6) = 0 -- норматив для расчета ОДН (по площади)
	, @set_soi_zero BIT = 0 -- установка СОИ в ноль
/*

Вызов процедуры:

DECLARE	@addyes int 
exec [dbo].ka_add_P354_EE @bldn_id1 = 7262,@service_id1 = N'элек',@fin_id1 = 173,
		@value_source1 = 12379,@doc1 = N'Тест',@doc_no1=99999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0, @volume_gvs=0, @serv_dom='Эдом',@flag=1,@use_add=1,@occ_test=344910
select @addyes		
		

*/
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF @service_id1 NOT IN ('элек', 'элмп', 'эле2', 'Эдом')
		RETURN;

	DECLARE @add_type1 TINYINT = 11
		  , @Vnr DECIMAL(15, 4)
		  , @Vnn DECIMAL(15, 4)
		  , @Vob DECIMAL(15, 4) = 0
		  , @value_raspred DECIMAL(15, 4) = 0
		  , @value_add_kol DECIMAL(15, 4) = 0
		  , @occ INT
		  , @total_sq DECIMAL(10, 4)
		  , @KolPeopleItog SMALLINT
		  , @i INT = 0
		  , @comments VARCHAR(100) = ''
		  , @ostatok_arenda DECIMAL(15, 4) = 0
		  , @sum_add DECIMAL(15, 2)
		  , @sum_value DECIMAL(15, 2)
		  , @ostatok DECIMAL(9, 2)
		  , @tip_id SMALLINT
		  , @fin_current SMALLINT
		  , @str_koef VARCHAR(40)
		  , @service_in VARCHAR(10) -- Код услуги на входе			
		  , @flat_id1 INT
		  , @KolDayFinPeriod TINYINT -- кол-во дней в фин периоде			
		  , @start_date SMALLDATETIME
		  , @DB_NAME VARCHAR(30) = UPPER(DB_NAME())
		  , @is_ValueBuildMinus BIT -- Разрешить ОДН с минусом
		  , @service_id_str VARCHAR(15) = ''
		  , @odn_big_norma BIT -- ОДН может быть больше нормы
			--@odn_min_norma_no	BIT,  -- не распределять ОДН если она меньше чем ОДН по норме
		  , @is_not_allocate_economy BIT = 1 -- не распределять экономию (по людям). Оставлять по норме. 
		  , @service_pk VARCHAR(10)		-- услуга с превышением норматива
		  , @is_boiler BIT -- есть бойлер
		  , @NormaGvsOdn DECIMAL(12, 6) = 0 -- норматив на ГВС на ОДН
		  , @NormaXvsOdn DECIMAL(12, 6) = 0; -- норматив на ХВС на ОДН

	SELECT @addyes = 0
		 , @service_in = @service_id1;

	SELECT @service_pk = '';
	--CASE
	--	WHEN @service_id1 = 'хвод' THEN 'хвпк'
	--	WHEN @service_id1 = 'гвод' THEN 'гвпк'
	--	ELSE ''
	--END

	IF @volume_arenda IS NULL
		SET @volume_arenda = 0;

	IF @volume_gvs IS NULL
		SET @volume_gvs = 0;

	IF @flag IS NULL
		SET @flag = 0;

	IF @use_add IS NULL
		SET @use_add = 1;

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL);

	SELECT @start_date = start_date
	FROM dbo.Global_values AS GV 
	WHERE fin_id = @fin_current;

	SELECT @odn_big_norma = COALESCE(odn_big_norma, 0)
		 , @is_boiler = COALESCE(is_boiler, 0)
	FROM dbo.Buildings B 
	WHERE id = @bldn_id1;

	SELECT @KolDayFinPeriod = DATEDIFF(DAY, @start_date, DATEADD(MONTH, 1, @start_date));

	IF @fin_id1 = @fin_current
	BEGIN
		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb 
			JOIN dbo.View_occ_all AS o 
				ON pcb.fin_id = o.fin_id
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

	--IF @fin_current <> @fin_id1
	--BEGIN
	--	RAISERROR ('Задайте текущий фин период в доме!', 16, 1)
	--	RETURN -1
	--END

	IF (@fin_current = @fin_id1)
		AND @doc_no1 <> '99999'
	BEGIN
		-- нужен перерасчёт по дому 		
		DECLARE curs CURSOR LOCAL FOR
			SELECT voa.occ
				 , voa.flat_id
			FROM dbo.VOcc voa 
				JOIN dbo.Occupation_Types AS ot 
					ON voa.tip_id = ot.id
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
			EXEC dbo.k_raschet_1 @occ1 = @occ
							   , @fin_id1 = @fin_current;

			FETCH NEXT FROM curs INTO @occ, @flat_id1;
		END;

		CLOSE curs;
		DEALLOCATE curs;
	END;

	SELECT @tip_id = tip_id
		 , @S_arenda =
					  CASE
						  WHEN @S_arenda IS NULL THEN COALESCE(arenda_sq, 0)
						  ELSE @S_arenda
					  END
		 , @is_ValueBuildMinus = COALESCE(OT.is_ValueBuildMinus, 0)
		 , @is_not_allocate_economy = COALESCE(OT.is_not_allocate_economy, 0)
		 , @total_sq = vb.build_total_sq
	FROM dbo.View_build_all AS vb 
		JOIN dbo.Occupation_Types OT 
			ON vb.tip_id = OT.id
	WHERE vb.fin_id = @fin_id1
		AND vb.bldn_id = @bldn_id1;

	-- Если есть специальная площадь по услуге по нежилым
	IF @S_arenda IS NULL
		SELECT @S_arenda = arenda_sq
		FROM [dbo].[Build_arenda] AS ba
		WHERE fin_id = @fin_id1
			AND build_id = @bldn_id1
			AND service_id = @service_in;
	IF @S_arenda IS NULL
		SET @S_arenda = 0;

	--IF @volume_odn>0
	--BEGIN
	--	IF @debug=1 PRINT '@volume_odn > 0, запускаем раскидку'
	--	DECLARE @bldn_str VARCHAR(100) = LTRIM(STR(@bldn_id1))

	--	EXEC dbo.ka_add_added_6 @fin_id=@fin_id1, 
	--		@bldn_str1=@bldn_str,
	--		@service_id=@serv_dom,
	--		@summa=@volume_odn,
	--		@metod=1,  -- по общей площади
	--		@doc1=@doc1,
	--		@debug=0,
	--		@ras_add=0, --текущих начислений
	--		@service_kol=@serv_dom,
	--		@is_counter_metod=0, -- 0-все лицевые
	--		@is_ras_kol=1, --1-раскидка количества
	--		@KolAdd = @addyes OUTPUT
	--	RETURN
	--END


	DECLARE @t_opu_itog TABLE (
		  mode_id INT
		, KolPeopleItog INT DEFAULT 0
		, value_source DECIMAL(15, 2)
		, value_arenda DECIMAL(15, 2) DEFAULT 0
		, Vnn DECIMAL(15, 2) DEFAULT 0
		, Vnr DECIMAL(15, 2) DEFAULT 0
		, Vob AS (value_source - value_arenda - Vnn - Vnr)
		, kol_add DECIMAL(15, 2) DEFAULT 0
		, ostatok AS (value_source - value_arenda - Vnn - Vnr - kol_add)
	);
	INSERT INTO @t_opu_itog (mode_id
						   , value_source
						   , value_arenda)
	SELECT c.mode_id
		 , SUM(COALESCE(ci.actual_value, 0))
		 , SUM(COALESCE(ci.volume_arenda, 0))
	FROM dbo.Counters c
		LEFT JOIN dbo.Counter_inspector ci ON 
			c.id = ci.counter_id
			AND ci.fin_id = @fin_id1
	WHERE (c.is_build = 1)
		AND c.service_id = @service_in
		AND c.build_id = @bldn_id1
	GROUP BY c.mode_id
	IF @debug = 1
		SELECT *
		FROM @t_opu_itog


	DECLARE @t TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, mode_id INT DEFAULT 0
		, nom_kvr VARCHAR(20) DEFAULT ''
		, tarif DECIMAL(10, 4) DEFAULT 0
		, kol DECIMAL(15, 4) DEFAULT 0
		, kol_itog DECIMAL(15, 4) DEFAULT 0
		, is_counter BIT DEFAULT 0
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, value DECIMAL(9, 2) DEFAULT 0
		, value_add DECIMAL(9, 2) DEFAULT 0
		, value_add_kol DECIMAL(15, 4) DEFAULT 0
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, sum_value DECIMAL(9, 2) DEFAULT 0
		, kol_add DECIMAL(15, 4) DEFAULT 0
		, comments VARCHAR(100) DEFAULT ''
		, norma DECIMAL(9, 2) DEFAULT 0
		, metod SMALLINT DEFAULT 0
		, unit_id VARCHAR(10) DEFAULT 'квтч'
		, kol_people TINYINT DEFAULT 0
		, source_id INT DEFAULT 0
		, kol_norma_odn DECIMAL(15, 4) DEFAULT 0
		, kol_tmp DECIMAL(15, 4) DEFAULT 0
		, kol_excess DECIMAL(15, 4) DEFAULT 0 -- превышение ОДН
		, UNIQUE (occ, service_id, mode_id)
	);

	-- Таблица лицевых для которых не надо считать общедомовые нужды	
	DECLARE @t_occ_opu_no TABLE (
		  occ INT
	);

	--IF @service_kol IS NULL SET @service_kol=@service_id1
	--PRINT '1'
	-- находим кол-во
	INSERT INTO @t (occ
				  , service_id
				  , mode_id
				  , is_counter
				  , kol
				  , tarif
				  , value)
	SELECT ci.occ
		 , ci.service_id
		 , ci.mode_id
		 , is_counter = 1
		 , SUM(ci.actual_value)
		 , MIN(ci.tarif)
		 , SUM(ci.value_paym)
	FROM View_counter_inspector ci
	WHERE ci.bldn_id = @bldn_id1
		AND ci.fin_id = @fin_id1
		AND ci.service_id = @service_in
	GROUP BY ci.occ
		   , ci.service_id
		   , ci.mode_id
	IF @debug = 1
		SELECT *
		FROM @t
		ORDER BY occ

	UPDATE t
	SET value_add = COALESCE((
			SELECT SUM(COALESCE(value, 0))
			FROM dbo.View_added AS ap 
			WHERE ap.occ = t.occ
				AND ap.fin_id = @fin_id1
				AND ap.service_id IN (@service_id1, @service_pk)
				AND add_type NOT IN (11, 15)
		), 0)
		--			,metod=ph.metod -- когда по норме должен быть NULL
	  , kol_people = COALESCE((
			SELECT COUNT(id)
			FROM dbo.View_people_all AS P 
				JOIN dbo.Person_calc AS PC 
					ON P.status2_id = PC.status_id
			WHERE P.occ = t.occ
				AND P.fin_id = @fin_id1
				--AND P.Del = 0
				AND PC.service_id = @service_id1
				AND PC.have_paym = 1
		), 0)
	FROM @t AS t


	UPDATE t
	SET kol = 0
	FROM @t AS t
		JOIN @t_occ_opu_no AS t_no ON t.occ = t_no.occ;

	DECLARE @service_id2 VARCHAR(10);
	SET @service_id2 = @service_id1;

	--*************************************************
	DECLARE @unit_id VARCHAR(10) = 'квтч';

	UPDATE t
	SET total_sq = o.total_sq
	  , kol_itog = kol
	  , nom_kvr = f.nom_kvr
	FROM @t AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Flats f
			ON o.flat_id = f.id

	UPDATE t
	SET kol_norma_odn = vp.kol
	FROM @t AS t
		JOIN dbo.View_paym vp 
			ON t.occ = vp.occ
			AND vp.fin_id = @fin_current
			AND vp.service_id = @serv_dom;

	UPDATE t
	SET metod = vp.metod
	FROM @t AS t
		JOIN dbo.View_paym vp 
			ON t.occ = vp.occ
			AND vp.fin_id = @fin_current
			AND vp.service_id = @service_in;


	IF @service_id1 IN ('элек', 'элмп', 'эле2', 'Эдом')
	BEGIN
		UPDATE t
		SET tarif = CASE
                        WHEN @tarif > 0 THEN @tarif
                        ELSE dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, @service_id1, @unit_id)
            END
		FROM @t AS t
		WHERE COALESCE(tarif, 0) = 0
	END;

	IF (EXISTS (
			SELECT 1
			FROM @t
			WHERE COALESCE(tarif, 0) = 0
		))
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@service_id1)
		RAISERROR ('Не удалось определить тариф по услуге %s', 16, 1, @comments);
		RETURN;
	END;

	UPDATE t2
	SET Vnn = COALESCE((
			SELECT SUM(kol)
			FROM @t t
			WHERE is_counter = 0
				AND t.mode_id = t2.mode_id
		), 0)
	  , Vnr = COALESCE((
			SELECT SUM(kol)
			FROM @t t
			WHERE is_counter = 1
				AND t.mode_id = t2.mode_id
		), 0)
	  , KolPeopleItog = (
			SELECT SUM(kol_people)
			FROM @t t
			WHERE t.mode_id = t2.mode_id
		)
	FROM @t_opu_itog t2

	IF @debug = 1
		SELECT t2.*
			 , t.*
		FROM @t t
			JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
		ORDER BY occ

	IF @use_add = 1
		UPDATE t
		SET value_add_kol =
						   CASE
							   WHEN tarif > 0 THEN value_add / tarif
							   WHEN @tarif > 0 THEN value_add / @tarif
							   ELSE 0
						   END
		FROM @t AS t;


	UPDATE t
	SET kol_itog = kol_itog + value_add_kol -- количество с учетом разовых
	FROM @t AS t;

	SELECT @value_source1 = SUM(value_source)
		 , @volume_arenda = SUM(t2.value_arenda)
		 , @Vnn = SUM(Vnn)
		 , @Vnr = SUM(Vnr)
		 , @Vob = SUM(value_source) - SUM(t2.value_arenda) - SUM(Vnn) - SUM(Vnr)
	FROM @t_opu_itog t2

	-- 		SELECT (t2.value_source-t2.value_arenda-t2.Vnn-t2.Vnr)
	-- 		FROM @t_opu_itog t2
	--WHERE t2.mode_id=@mode_id1

	IF @debug = 1
		SELECT @value_source1 value_source1
			 , @volume_arenda volume_arenda
			 , @Vnn Vnn
			 , @Vnr Vnr
			 , @Vob Vob
			 , @odn_big_norma AS odn_big_norma

	SELECT @value_add_kol = SUM(value_add_kol)
	FROM @t AS t;

	IF @set_soi_zero=1
	BEGIN
		if @debug=1 PRINT '@set_soi_zero=1'
		GOTO LABEL_SET_ZERO
	END

	IF @Vnn = 0
		AND @Vnr = 0
	BEGIN
		SET @comments = dbo.Fun_GetServiceName(@service_id1)
		RAISERROR ('Начислений по услуге %s не было', 16, 1, @comments);
		RETURN;
	END;

	DECLARE @occ1 INT
		  , @mode_id1 INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT t.occ
			 , t.mode_id
		FROM @t t
			JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
		ORDER BY occ

	OPEN cur

	FETCH NEXT FROM cur INTO @occ1, @mode_id1

	WHILE @@fetch_status = 0
	BEGIN
		IF @norma_odn>0
		BEGIN
			IF @debug=1 PRINT '@norma_odn > 0'
			
			UPDATE t
			SET kol_add = @norma_odn * total_sq
			  , comments = dbo.FSTR(t.tarif, 6, 2) +'*'+dbo.FSTR(@norma_odn, 12, 6) + '*' + dbo.FSTR(total_sq, 9, 2)
			FROM @t t
				JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
			WHERE t.occ = @occ1
				AND t.mode_id = @mode_id1
		END
		ELSE
		IF (@total_sq + @S_arenda) > 0
		BEGIN

			UPDATE t
			SET kol_add = (t2.value_source - t2.value_arenda - t2.Vnn - t2.Vnr) * total_sq / (@total_sq + @S_arenda)
			  , comments = dbo.FSTR(t.tarif, 6, 2) + '*((' + dbo.FSTR(t2.value_source, 9, 0) + '-' + dbo.FSTR(t2.value_arenda, 9, 0) + '-' + dbo.FSTR(t2.Vnn, 9, 0) + '-' + dbo.FSTR(t2.Vnr, 9, 0)
				+ ')*' + dbo.FSTR(total_sq, 9, 2) + '/(' + dbo.FSTR(@total_sq, 9, 2) + '+' + dbo.FSTR(@S_arenda, 9, 2) + '))'
			FROM @t t
				JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
			WHERE t.occ = @occ1
				AND t.mode_id = @mode_id1
				AND (t2.value_source - t2.value_arenda - t2.Vnn - t2.Vnr) > 0

			-- <=0
			UPDATE t
			SET kol_add = (t2.value_source - t2.value_arenda - t2.Vnn - t2.Vnr) * t.kol_people / t2.KolPeopleItog --- kol
			  , comments = dbo.FSTR(t.tarif, 6, 2) + '*(' + dbo.FSTR(t2.value_source, 9, 2) + '-' + dbo.FSTR(t2.value_arenda, 9, 2) + '-' + dbo.FSTR(t2.Vnn, 9, 2) + '-' + dbo.FSTR(t2.Vnr, 9, 2)
				+ ')*(' + LTRIM(STR(t.kol_people, 3)) + '/' + LTRIM(STR(t2.KolPeopleItog, 4)) + ')' --+' + LTRIM(dbo.FSTR(kol, 9, 2))
			FROM @t t
				JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
			WHERE t.occ = @occ1
				AND t.mode_id = @mode_id1
				AND (t2.value_source - t2.value_arenda - t2.Vnn - t2.Vnr) <= 0
				AND t2.KolPeopleItog > 0;

		END

		FETCH NEXT FROM cur INTO @occ1, @mode_id1

	END

	CLOSE cur
	DEALLOCATE cur

	UPDATE ti
	SET kol_add = (
		SELECT SUM(t.kol_add)
		FROM @t t
		WHERE ti.mode_id = t.mode_id
	)
	FROM @t_opu_itog ti

	IF @debug = 1
		SELECT *
		FROM @t_opu_itog

	DECLARE cur CURSOR LOCAL FOR
		SELECT ti.mode_id
			 , ti.ostatok
		FROM @t_opu_itog ti
		WHERE ti.ostatok <> 0
	OPEN cur
	FETCH NEXT FROM cur INTO @mode_id1, @ostatok_arenda
	WHILE @@fetch_status = 0
	BEGIN

		IF @debug = 1
			PRINT 'надо раскидать остаток: ' + STR(@ostatok_arenda, 9, 4) + ' по режиму: ' + STR(@mode_id1);
		
		;WITH cte AS (
			SELECT TOP (1) * FROM @t AS t WHERE kol_add <> 0 AND t.mode_id = @mode_id1
		)
		UPDATE cte
		SET kol_add = kol_add + @ostatok_arenda;
		
		FETCH NEXT FROM cur INTO @mode_id1, @ostatok_arenda
	END
	CLOSE cur;
	DEALLOCATE cur;

	-- сохраняем распределяемый объём
	SELECT @value_raspred = SUM(kol_add)
	FROM @t;

	UPDATE @t
	SET service_id = @serv_dom;

	UPDATE t
	SET sum_value = tarif * kol_add
	FROM @t AS t
	WHERE kol_add <> 0;

	IF @debug = 1
		SELECT t2.*
			 , t.*
		FROM @t t
			JOIN @t_opu_itog t2 ON t.mode_id = t2.mode_id
		ORDER BY occ

	----********************************************************
	SELECT @value_raspred = SUM(kol_add)
		 , @sum_value = SUM(sum_value)
	FROM @t;

	SELECT @tarif = @sum_value / @value_raspred

	UPDATE t
	SET tarif = @tarif
	FROM @t AS t
	--WHERE kol_add <> 0;

	DECLARE @user_edit1 SMALLINT;
	SELECT @user_edit1 = dbo.Fun_GetCurrentUserId();

	--RETURN  -- для тестирования

	IF @fin_current > @fin_id1
	BEGIN
		-- Формируем перерасчёты в текущем месяце по общедомовым
		INSERT INTO dbo.Added_Payments (occ
									  , service_id
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
		SELECT @addyes = CASE
                             WHEN @addyes = 0 THEN @@rowcount
                             ELSE @addyes
            END;

		GOTO LABEL_END;
	END;

	BEGIN TRAN;

	DELETE pcb
	FROM dbo.Paym_occ_build AS pcb
		JOIN @t AS t ON pcb.occ = t.occ
	WHERE pcb.fin_id = @fin_current
		AND pcb.service_id IN (@service_id1, @serv_dom);

	INSERT INTO dbo.Paym_occ_build (fin_id
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
									, kol_excess)
	SELECT @fin_current
		 , t.occ
		 , t.service_id
		 , SUM(t.kol_add)
		 , MIN(t.tarif)
		 , SUM(t.sum_value)
		 , SUBSTRING((
			   SELECT '+' + t2.comments
			   FROM @t AS t2
			   WHERE t2.occ = t.occ
			   GROUP BY t2.comments
					  , t2.tarif
			   FOR XML PATH ('')
		   ), 2, 400) as comments
		 , @unit_id as unit_id
		 , 'ka_add_P354_EE' as procedura
		 , SUM(t.kol_add) - MIN(t.kol_norma_odn) --SUM(t.kol_add) - SUM(t.kol)
		 , MIN(metod)
		 , @service_in
		 , SUM(t.kol_add) - MIN(t.kol_norma_odn)
	FROM @t AS t
	GROUP BY t.occ
		   , t.service_id
	SELECT @addyes = CASE
                         WHEN @addyes = 0 THEN @@rowcount
                         ELSE @addyes
        END;

	SELECT @service_id1
		 , @serv_dom
		 , @value_raspred

	COMMIT TRAN;

LABEL_SET_ZERO:
	IF (@service_id1 <> @serv_dom) OR (@set_soi_zero=1)
	BEGIN
		INSERT INTO dbo.Paym_occ_build WITH (ROWLOCK) (fin_id
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
													 , service_in)
		SELECT @fin_current
			 , t.occ
			 , @serv_dom
			 , 0
			 , tarif
			 , 0
			 , 'Обнуляем чтобы не было ОДН по норме'
			 , @unit_id as unit_id
			 , 'ka_add_P354_EE' as procedura
			 , 0
			 , metod
			 , @service_in
		FROM @t AS t
		WHERE service_id <> @serv_dom
		SELECT @addyes = CASE
                             WHEN @addyes = 0 THEN @@rowcount
                             ELSE @addyes
            END;
	END

	IF @debug = 1
		PRINT 'сохраняем итоговые данные по дому , использованные в расчёте'
	MERGE dbo.Build_source_value AS bs USING (
		SELECT bldn_id1 = @bldn_id1
			 , fin_current = @fin_current
			 , service_in = @service_in
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
	WHEN NOT MATCHED
		THEN INSERT (fin_id
				   , build_id
				   , service_id
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
				   , value_raspred)
			VALUES(@fin_current
				 , @bldn_id1
				 , @service_in
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
				 , @value_raspred);


	IF @debug = 1
		RAISERROR ('заполняем данные по нежилым помещениям дома', 10, 1) WITH NOWAIT;
	MERGE dbo.Build_arenda AS ba USING (
		SELECT bldn_id1 = @bldn_id1
			 , fin_current = @fin_current
			 , service_in = @service_in
			 , volume_arenda = @volume_arenda
			 , ostatok_arenda = @ostatok_arenda
			 , S_arenda = @S_arenda
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
		THEN INSERT (build_id
				   , fin_id
				   , service_id
				   , kol
				   , kol_dom
				   , arenda_sq)
			VALUES(t2.bldn_id1
				 , t2.fin_current
				 , t2.service_in
				 , t2.volume_arenda
				 , t2.ostatok_arenda
				 , t2.S_arenda);

LABEL_END:;

	IF @doc_no1 NOT IN ('99999','88888')
	BEGIN
		IF @debug = 1
			RAISERROR ('делаем перерасчёт по дому', 10, 1) WITH NOWAIT;
		EXEC dbo.k_raschet_build @build_id = @bldn_id1;
	END

END;
go

