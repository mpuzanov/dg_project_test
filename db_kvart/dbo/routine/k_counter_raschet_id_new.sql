CREATE   PROCEDURE [dbo].[k_counter_raschet_id_new]
(
	  @counter_id1 INT -- код счетчика
	, @tip_value1 SMALLINT = 1  -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
)
AS
	/*
	Расчет по внутренним счетчикам
	
	exec k_counter_raschet_id_new @counter_id1=6933,@tip_value1=1,@debug=1
	exec k_counter_raschet_id_new @counter_id1=66142,@tip_value1=1,@debug=1
	
	*/

	SET NOCOUNT ON
	
	SET @tip_value1 = COALESCE(@tip_value1, 1)

	DECLARE @strerror VARCHAR(8000)
		  , @date_first SMALLDATETIME -- дата снятия предпоследнего показания
		  , @value_first DECIMAL(12, 4)  -- значение предпоследнего показания
		  , @date_last SMALLDATETIME  -- дата снятия последнего показания
		  , @value_last DECIMAL(12, 4)  -- значение последнего показания
		  , @actual_value_last DECIMAL(12, 4)  -- значение последнего показания
		  , @blocked_first BIT = 0
		  , @blocked_last BIT
		  , @err INT
		  , @res INT
		  , @kol_insp INT -- кол-во показаний инспектора
		  , @kod_inspector INT -- код показателя инспектора
		  , @value_vday DECIMAL(14, 6)  -- значение в день
		  , @unit_id VARCHAR(10) -- ед.измерения
		  , @service_id VARCHAR(10) -- код услуги
		  , @actual_value1 DECIMAL(14, 6)
		  , @max_value1 INT  -- максимальное значение счетчика
		  , @build_id1 INT  -- код дома
		  , @ostatok DECIMAL(9, 4)		  
		  , @source_id INT -- код поставщика на услуге
		  , @mode_counter INT -- код режима ПУ
		  , @mode_id INT -- код режима на лицевом
		  , @max_value_vday INT -- ограничение значений показателя в день
		  , @kol_day SMALLINT
		  , @fin_id SMALLINT
		  , @tip_id SMALLINT
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @fin_current SMALLINT
		  , @ppu_value_allow_negativ BIT
		  , @flat_id INT
		  , @blocked_value_negativ BIT -- блокировать отрицательный объём по ПУ		  

	-- запоминаем параметры счетчика
	SELECT @service_id = c.service_id
		 , @date_first = c.date_create
		 , @value_first = count_value
		 , @unit_id = c.unit_id
		 , @service_id = c.service_id
		 , @max_value1 = c.max_value
		 , @build_id1 = c.build_id
		 , @fin_current = b.fin_current
		 , @tip_id = b.tip_id
		 , @mode_counter = c.mode_id
		 , @ppu_value_allow_negativ = ot.ppu_value_allow_negativ
		 , @flat_id = c.flat_id
	FROM dbo.Counters AS c
		JOIN dbo.Buildings AS b ON c.build_id = b.id
		JOIN dbo.Occupation_Types ot  ON ot.id = b.tip_id
	WHERE c.id = @counter_id1

	SELECT @max_value_vday = max_value_vday
	FROM Fun_GetCounterServValueInDay()
	WHERE service_id = @service_id

	SELECT TOP(1)
		@source_id = ch.source_id
		,@mode_id = ch.mode_id
	FROM dbo.Consmodes_list AS ch 
	JOIN dbo.Counter_list_all AS clh
		ON clh.service_id = ch.service_id
		AND clh.occ = ch.occ
	WHERE clh.fin_id = @fin_current
		AND clh.counter_id = @counter_id1
		--AND (ch.mode_id % 1000) != 0
		--AND (ch.source_id % 1000) != 0

	DECLARE @t TABLE (
		kod_insp INT
		, fin_id SMALLINT
		, tarif DECIMAL(9, 4)
		, inspector_date SMALLDATETIME
		, d1 SMALLDATETIME
		, d2 SMALLDATETIME
		, kol_day SMALLINT
		, value_vday DECIMAL(14, 8)
		, kol DECIMAL(12,6) DEFAULT 0
		, VALUE DECIMAL(12, 4) DEFAULT 0
		, mode_id INT DEFAULT 0
		, fin_id_insp SMALLINT DEFAULT NULL
		, fin_id_insp_last SMALLINT DEFAULT NULL
		, PRIMARY KEY (kod_insp, fin_id, tarif)
	)

	-- Сводные данные по показателю
	DECLARE @t2 TABLE (
		  kod_insp INT PRIMARY KEY
		, kol_day SMALLINT DEFAULT 0
		, actual_value DECIMAL(14, 8) DEFAULT 0
		, value_vday DECIMAL(14, 8) DEFAULT 0
		, tarif DECIMAL(9, 4) DEFAULT 0
		, value_paym DECIMAL(12, 4) DEFAULT 0
		, kod_insp_pred INT DEFAULT 0 -- код предыдущего показания
		, value_last DECIMAL(14, 8) DEFAULT 0
	)

	DECLARE @d1 SMALLDATETIME
		  , @d2 SMALLDATETIME -- временные переменные дат
		  , @pred_fin_ppu SMALLINT
		  , @metod_rasch SMALLINT
		  , @Norma_extr_tarif DECIMAL(12, 6) = 0  -- норма для расчета по сверх нормативному
		  , @Norma_full_tarif DECIMAL(12, 6) = 0  -- норма для расчете по 100% тарифу


	if @service_id in ('элек')
	BEGIN
		SELECT @Norma_extr_tarif=COALESCE(norma_extr_tarif,0)
			, @Norma_full_tarif=COALESCE(norma_full_tarif,0)
		FROM dbo.Fun_GetNorma_tf(@unit_id, @mode_id, 1, @tip_id, @fin_current)	-- нужен режим !
	
		IF @debug=1 
			SELECT @unit_id,@mode_id,@tip_id,@fin_current,@Norma_extr_tarif,@Norma_full_tarif
			--print @unit_id +' '+ str(@mode_id)+' '+ str(@tip_id)+' '+ str(@fin_id)+' '+dbo.FSTR(@Norma_extr_tarif,9,2)+' '+dbo.FSTR(@Norma_full_tarif,9,2)

	END;

	DECLARE @tar1 DECIMAL(10, 4)=0, @extr_tar DECIMAL(9,2)=0, @full_tar DECIMAL(9,2)=0, @value1 DECIMAL(9,2)=0
    SELECT @tar1 = t1, @extr_tar = t2, @full_tar = t3
    from dbo.Fun_GetCounterTarif_tf(@fin_id, @counter_id1, NULL, @fin_id,
                                    CASE WHEN @mode_counter > 0 THEN @mode_counter  ELSE @mode_id END, @source_id)
	if @debug=1
		SELECT @mode_id as mode_id, @mode_counter as mode_counter, @source_id as source_id, @tar1 as tar1

	BEGIN TRY

		DECLARE curs2 CURSOR FOR
			SELECT ci.id
				 , ci.inspector_date
				 , ci.inspector_value
				 , ci.blocked
				 , CASE
                       WHEN ci.mode_id = 0 THEN CASE WHEN @mode_counter > 0 THEN @mode_counter ELSE @mode_id END 
                       ELSE ci.mode_id
                END AS mode_id
				 , ci.fin_id
				 , ci_pred.inspector_date  AS pred_inspector_date
				 , ci_pred.inspector_value AS pred_inspector_value
				 , ci_pred.fin_ppu         AS pred_fin_ppu
				 , COALESCE(ci.blocked_value_negativ, 0) AS blocked_value_negativ
				 , CASE
                       WHEN ci_pred.fin_ppu IS NULL THEN NULL
                       ELSE ci_pred.actual_value
                END AS actual_value_last -- если это нач.показания ПУ то будет NULL
				 , ci.metod_rasch
			FROM dbo.Counter_inspector AS ci
				--OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(@counter_id1, @fin_current) AS ci_pred
				OUTER APPLY [dbo].Fun_GetCounterTableValue_PredCI(@counter_id1, ci.id, ci.inspector_date) AS ci_pred		
			WHERE 
				ci.counter_id = @counter_id1
				AND ci.fin_id = @fin_current
				AND ci.tip_value = @tip_value1				
			ORDER BY ci.inspector_date
				   , ci.id
		OPEN curs2
		FETCH NEXT FROM curs2 INTO @kod_inspector, @date_last, @value_last, @blocked_last, @mode_id, @fin_id, @date_first, @value_first, @pred_fin_ppu, @blocked_value_negativ, @actual_value_last, @metod_rasch

		WHILE (@@fetch_status = 0)
		BEGIN
			-- есть сверх нормативный тариф
			if (@Norma_extr_tarif>0 OR @Norma_full_tarif>=0) AND @extr_tar>0
			BEGIN
				DECLARE @kol1 DECIMAL(12,6)=0 --, @kol2 DECIMAL(12,6)=0, @kol3 DECIMAL(12,6)=0

				SELECT @actual_value1 = @value_last - @value_first, @kol_day = (DATEDIFF(DAY, @date_first, @date_last) + 1)
				
				IF @actual_value1<@Norma_extr_tarif
				BEGIN
					SET @kol1=@actual_value1
					SET @value1 = @tar1 * @kol1

					INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
					VALUES(@fin_id, @kod_inspector, @date_last, @date_first, @date_last
						 , @kol_day
						 , (@kol1 / @kol_day)
						 , @tar1, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)
				END
				ELSE			
					IF @actual_value1>=@Norma_extr_tarif and @actual_value1<@Norma_full_tarif
					BEGIN
						SET @kol1= @Norma_extr_tarif
						SET @value1 = @tar1 * @kol1

						INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
						VALUES (@fin_id, @kod_inspector, @date_last, @date_first, @date_last
						 , @kol_day
						 , @kol1 / @kol_day
						 , @tar1, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)

						SET @kol1= (@actual_value1-@Norma_extr_tarif)
						SET @value1 = @extr_tar * @kol1

						INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
						VALUES (@fin_id, @kod_inspector, @date_last, @date_first, @date_last
							, @kol_day
							, (@kol1 / @kol_day) 
							, @extr_tar, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)
					END
					ELSE
					IF @actual_value1>@Norma_full_tarif
						BEGIN															
							SET @kol1= @Norma_extr_tarif
							SET @value1 = @tar1 * @kol1

							INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
							VALUES (@fin_id, @kod_inspector, @date_last, @date_first, @date_last
							 , @kol_day
							 , (@kol1 / @kol_day)
							 , @tar1, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)

							SET @kol1= (@Norma_full_tarif-@Norma_extr_tarif)
							SET @value1 = @extr_tar * @kol1

							INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
							VALUES (@fin_id, @kod_inspector, @date_last, @date_first, @date_last
								, @kol_day
								, (@kol1 / @kol_day)
								, @extr_tar, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)

							SET @kol1 = (@actual_value1-@Norma_full_tarif)
							SET @value1 = @extr_tar * @kol1

							--SELECT @value1 = (@tar1 * @Norma_extr_tarif)+(@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif))+(@full_tar*(@actual_value1-@Norma_full_tarif))

							INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, kol, value, mode_id, fin_id_insp, fin_id_insp_last)
							VALUES (@fin_id, @kod_inspector, @date_last, @date_first, @date_last
								, @kol_day
								, (@kol1 / @kol_day)
								, @full_tar, @kol1, @value1, @mode_id, @fin_id, @pred_fin_ppu)

						END
				
				IF @debug=1
				BEGIN
					PRINT str(@tar1,9,2)+' * '+dbo.FSTR(@Norma_extr_tarif,9,2)+' = '+dbo.FSTR((@tar1 * @Norma_extr_tarif),9,2)
					PRINT str(@extr_tar,9,2)+' * '+dbo.FSTR(@Norma_full_tarif-@Norma_extr_tarif,9,2)+' = '+dbo.FSTR((@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif)),9,2)
					PRINT str(@full_tar,9,2)+' * '+dbo.FSTR(@actual_value1-@Norma_full_tarif,9,2)+' = '+dbo.FSTR((@full_tar*(@actual_value1-@Norma_full_tarif)),9,2)
					PRINT str(@value1,9,2)
				END

				INSERT INTO @t2 (kod_insp
							   , kol_day
							   , actual_value
							   , value_vday
							   , value_last)
				SELECT kod_insp
					 , SUM(kol_day)
					 , @actual_value1
					 , @actual_value1 / (DATEDIFF(DAY, @date_first, @date_last) + 1)
					 , @value_last
				FROM @t
				WHERE kod_insp = @kod_inspector
				GROUP BY kod_insp

			END
			ELSE
			BEGIN
				SET @date_first = DATEADD(DAY, 1, @date_first)
				SELECT @d1 = SMALLDATETIMEFROMPARTS(YEAR(@date_first), MONTH(@date_first), 1, 0, 0)
					 , @d2 = SMALLDATETIMEFROMPARTS(YEAR(@date_last), MONTH(@date_last), 1, 0, 0)

				IF @debug = 1
					PRINT CONCAT('@fin_id=', STR(@fin_id),'@value_last=', STR(@value_last, 9, 2),'@value_first=', STR(@value_first, 9, 2))
				IF @debug = 1
					PRINT CONCAT('@d1=', CONVERT(VARCHAR(10), @date_first, 104),'@d2=', CONVERT(VARCHAR(10), @date_last, 104) )

				INSERT INTO @t (fin_id
							  , kod_insp
							  , inspector_date
							  , d1
							  , d2
							  , kol_day
							  , value_vday
							  , tarif
							  , mode_id
							  , fin_id_insp
							  , fin_id_insp_last)
				SELECT fin_id
					 , @kod_inspector
					 , @date_last
					 , d1 =
						   CASE
							   WHEN (start_date <= @date_first AND @date_first <= end_date) THEN @date_first
							   ELSE start_date
						   END
					 , d2 =
						   CASE
							   WHEN (start_date <= @date_last AND @date_last <= end_date) THEN @date_last
							   ELSE end_date
						   END
					 , kol_day = 0
					 , value_vday = 0
					 , @tar1 AS tarif
					 , @mode_id
					 , @fin_id
					 , @pred_fin_ppu
				FROM dbo.Global_values 
				WHERE start_date BETWEEN @d1 AND @d2

				--*****************			
				--SET @date_first=@date_last

				UPDATE @t
				SET d2 = d1
				WHERE d2 < d1

				UPDATE @t
				SET kol_day = DATEDIFF(DAY, d1, d2) + 1   -- 30/06/2005
				WHERE kod_insp = @kod_inspector

				SELECT @kol_day = SUM(kol_day)
				FROM @t
				WHERE kod_insp = @kod_inspector

				IF @debug = 1
					PRINT CONCAT('kol_day=', @kol_day,' value_last=', @value_last,' value_first=', @value_first)

				IF @value_last < @value_first
				BEGIN
					IF @ppu_value_allow_negativ = 1
						AND @actual_value_last IS NOT NULL -- если за предыдущее показание начисляли
						AND @blocked_value_negativ = 0 -- разрешён отрицательный объем
					BEGIN
						-- надо определить вычитать объем или был переход макс значения и объем прибавляем
						-- там где меньше объем, по нему и считаем
						IF ABS(@value_last - @value_first) < (@max_value1 + 1 + @value_last - @value_first)
						BEGIN
							SET @actual_value1 = @value_last - @value_first
							IF @debug = 1
								PRINT 'Ошибочное показание в прошлый раз'
						END
						ELSE
						BEGIN
							SET @actual_value1 = @max_value1 + 1 + @value_last - @value_first
							IF @debug = 1
								PRINT 'Переход макс. значения. выбрали увеличивать объем'
						END
					END
					ELSE
					BEGIN -- переход на максимальное значение
						-- то считаем что показания перешли макс значение
						SET @actual_value1 = @max_value1 + 1 + @value_last - @value_first
						IF @debug = 1
							PRINT 'Переход макс. значения'
					END
				END
				ELSE
				BEGIN
					SET @actual_value1 = @value_last - @value_first
				END

				SET @value_vday = @actual_value1 / @kol_day
				IF @debug = 1
					PRINT CONCAT('actual_value=', @actual_value1,' value_vday=', @value_vday)

				IF (@value_vday > @max_value_vday)
					AND (@tip_value1 = 1) -- ограничиваем только показания жителей  -- закоментировал 09.12.21
				BEGIN
					IF @debug = 1
						PRINT CONCAT('защита от переполнения: в день ', @value_vday,', max: ', @max_value_vday)
					SET @actual_value1 = 0  -- защита от переполнения  15.03.2021
					SET @value_vday = 0 -- @max_value_vday
				END

				IF @blocked_first = 1
					SET @actual_value1 = 0

				INSERT INTO @t2 (kod_insp
							   , kol_day
							   , actual_value
							   , value_vday
							   , value_last
							   , tarif)
				SELECT kod_insp
					 , SUM(kol_day)
					 , @actual_value1
					 , 0
					 , @value_last
					 , @tar1
				FROM @t
				WHERE kod_insp = @kod_inspector
				GROUP BY kod_insp

				UPDATE @t2
				SET value_vday = actual_value / kol_day
				WHERE kod_insp = @kod_inspector

				UPDATE t
				SET value_vday = t2.value_vday
				FROM @t AS t
					JOIN @t2 AS t2 ON t.kod_insp = t2.kod_insp
						AND t.kod_insp = @kod_inspector

				-- Проверяем и Корректируем значения в день
				SELECT @ostatok = SUM(value_vday * kol_day)
				FROM @t AS t
				WHERE kod_insp = @kod_inspector

				IF @actual_value1 <> @ostatok
				BEGIN
					IF @debug = 1
						PRINT '@ostatok: ' + STR(@ostatok, 9, 4) + ' @actual_value1:' + STR(@actual_value1, 9, 4)
				END
				IF @debug = 1
					PRINT '@kod_inspector:' + STR(@kod_inspector) + ' @tip_value1:' + STR(@tip_value1)

			END  --if @Norma_extr_tarif>0 OR @Norma_full_tarif>=0

			SELECT @value_first = @value_last
				 , @blocked_first = @blocked_last

			-- читаем следующий показатель
			FETCH NEXT FROM curs2 INTO @kod_inspector, @date_last, @value_last, @blocked_last, @mode_id, @fin_id, @date_first, @value_first, @pred_fin_ppu, @blocked_value_negativ, @actual_value_last, @metod_rasch
		END

		CLOSE curs2
		DEALLOCATE curs2

		--*************************************************************************************	
		IF @debug = 1 select '@t 1111',* from @t
		IF @debug = 1 select '@t2 111', * from @t2

		SELECT TOP (1) @actual_value1 = actual_value
				   , @value_last = value_last
				   , @kod_inspector = kod_insp
		FROM @t2
		ORDER BY kod_insp DESC


		---- есть сверх нормативный тариф
		--if @Norma_extr_tarif>0 OR @Norma_full_tarif>=0
		--BEGIN
		--	--DECLARE @tar1 DECIMAL(10, 4)=0, @extr_tar DECIMAL(9,2)=0, @full_tar DECIMAL(9,2)=0, @value1 DECIMAL(9,2)=0

		--	--select @tar1=t1, @extr_tar=t2, @full_tar=t3 from dbo.Fun_GetCounterTarif_tf(@fin_id,@counter_id1,NULL,@fin_id,@mode_id, @source_id)
			
		--	IF @actual_value1<@Norma_extr_tarif
		--		SELECT @value1 = @tar1 * @actual_value1
		--	ELSE			
		--		IF @actual_value1>=@Norma_extr_tarif and @actual_value1<@Norma_full_tarif
		--			SELECT @value1 = (@tar1 * @Norma_extr_tarif)+((@actual_value1-@Norma_extr_tarif)*@extr_tar)
		--		ELSE
		--		IF @actual_value1>@Norma_full_tarif
		--			SELECT @value1 = (@tar1 * @Norma_extr_tarif)+(@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif))+(@full_tar*(@actual_value1-@Norma_full_tarif))					
				
		--	if @debug=1
		--	begin
		--		PRINT str(@tar1,9,2)+' * '+dbo.FSTR(@Norma_extr_tarif,9,2)+' = '+dbo.FSTR((@tar1 * @Norma_extr_tarif),9,2)
		--		PRINT str(@extr_tar,9,2)+' * '+dbo.FSTR(@Norma_full_tarif-@Norma_extr_tarif,9,2)+' = '+dbo.FSTR((@extr_tar*(@Norma_full_tarif-@Norma_extr_tarif)),9,2)
		--		PRINT str(@full_tar,9,2)+' * '+dbo.FSTR(@actual_value1-@Norma_full_tarif,9,2)+' = '+dbo.FSTR((@full_tar*(@actual_value1-@Norma_full_tarif)),9,2)
		--		PRINT str(@value1,9,2)
		--	end
		--END;


		UPDATE t
		SET tarif = CASE
                        WHEN t.value_vday < 0 THEN dbo.Fun_GetCounterTarifMode(t.fin_id_insp_last, @counter_id1, NULL, mode_id, t.fin_id_insp_last)
                        ELSE dbo.Fun_GetCounterTarifMode(t.fin_id, @counter_id1, NULL, mode_id, t.fin_id_insp)
            END -- 15.07.2021
		--tarif = dbo.Fun_GetCounterTarifMode(t.fin_id, @counter_id1, NULL, mode_id, t.fin_id_insp)  -- ставим текущий тариф возможно надо его
		FROM @t AS t
		WHERE t.tarif=0 

		IF @debug = 1 -- тестируем		
			SELECT '@t' AS tbl, * FROM @t		

		UPDATE t
		SET VALUE = CASE
                        WHEN t2.actual_value <> 0 THEN t.kol_day * t.tarif * t2.value_vday
                        ELSE 0
            END
		FROM @t AS t
			JOIN @t2 AS t2 ON t.kod_insp = t2.kod_insp
		WHERE t.[value]=0 OR t.[value] is null

		UPDATE @t2
		SET value_paym = t.value_paym
		FROM @t2 AS t2
		CROSS APPLY (
			SELECT SUM(t.VALUE) AS value_paym
			FROM @t AS t
			WHERE t.kod_insp = t2.kod_insp
		) as t

		UPDATE @t2
		SET tarif =
					CASE
						WHEN (
								SELECT COUNT(DISTINCT t.tarif)
								FROM @t AS t
								WHERE t.kod_insp = t2.kod_insp
									AND t.tarif > 0
								GROUP BY t.kod_insp
							) = 1 THEN (
								SELECT DISTINCT t.tarif
								FROM @t AS t
								WHERE t.kod_insp = t2.kod_insp
									AND t.tarif > 0
							)
						WHEN (actual_value > 0) AND
							(value_paym > 0) THEN value_paym / actual_value
						ELSE (
								SELECT SUM(t.tarif) / COUNT(t.kod_insp)
								FROM @t AS t
								WHERE t.kod_insp = t2.kod_insp
								GROUP BY t.kod_insp
							)
					END
		FROM @t2 AS t2

		IF @debug = 1 -- тестируем
			SELECT '@t' AS tbl, * FROM @t		

		DELETE cp
		FROM dbo.Counter_paym cp
			JOIN @t AS t ON cp.kod_insp = t.kod_insp --AND cp.fin_id = t.fin_id
		WHERE cp.counter_id = @counter_id1
			AND tip_value = @tip_value1

		INSERT INTO dbo.Counter_paym (fin_id
									, counter_id
									, kod_insp
									, tip_value
									, kol_day
									, value_vday
									, tarif
									, VALUE
									, mode_id)
		SELECT fin_id
			 , @counter_id1
			 , kod_insp
			 , @tip_value1
			 , kol_day
			 , value_vday
			 , tarif
			 , VALUE
			 , mode_id
		FROM @t

		IF @debug = 1 -- тестируем
		BEGIN
			SELECT '@t' AS tbl, * FROM @t

			SELECT '@t2', t2.* FROM @t2 t2 ORDER BY kod_insp

			SELECT TOP (100) 'COUNTER_PAYM'
						 , cp.*
			FROM dbo.Counter_paym cp
			WHERE counter_id = @counter_id1
				AND tip_value = @tip_value1
			ORDER BY cp.fin_id DESC
		END

		UPDATE ci
		SET kol_day = t2.kol_day
		  , actual_value = t2.actual_value
		  , value_vday = t2.value_vday
		  , tarif = t2.tarif
		  , value_paym = t2.value_paym
		FROM dbo.Counter_inspector AS ci
			JOIN @t2 AS t2 ON ci.id = t2.kod_insp

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + ' Код счетчика: ' + STR(@counter_id1)

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
		RETURN @err

	END CATCH
go

