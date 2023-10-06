CREATE   PROCEDURE [dbo].[k_counter_raschet_id]
(
	  @counter_id1 INT -- код счетчика
	, @tip_value1 SMALLINT = 0  -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
)
AS
	/*
	
	!!!  СТАРАЯ ПРОЦЕДУРА
	
	Расчет по внутренним счетчикам
	
	k_counter_raschet_id @counter_id1=63935,@tip_value1=1,@debug=1
	
	*/

	SET NOCOUNT ON

	IF @tip_value1 IS NULL
		SET @tip_value1 = 1

	DECLARE @strerror VARCHAR(8000)
		  , @date_first SMALLDATETIME -- дата снятия предпоследнего показания
		  , @value_first DECIMAL(12, 4)  -- значение предпоследнего показания
		  , @date_last SMALLDATETIME  -- дата снятия последнего показания
		  , @value_last DECIMAL(12, 4)  -- значение последнего показания
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
		  , @max_value_vday INT  -- ограничение значений показателя в день
		  , @kol_day SMALLINT
		  , @build_id1 INT  -- код дома
		  , @ostatok DECIMAL(14, 6)
		  , @mode_id INT -- код режима показания
		  , @source_id INT -- код поставщика на услуге
		  , @mode_counter INT -- код режима ПУ
		  , @max_error INT -- ограничение значений показателя
		  , @fin_id SMALLINT
		  , @tip_id SMALLINT
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @fin_current SMALLINT
		  , @ppu_value_allow_negativ BIT

	-- запоминаем параметры счетчика
	SELECT @service_id = c.service_id
		 , @date_first = c.date_create
		 , @value_first = count_value
		 , @unit_id = c.unit_id
		 , @service_id = c.service_id
		 , @max_value1 = c.max_value
		 , @build_id1 = c.build_id
		 , @fin_current = b.fin_current
		 , @mode_counter = c.mode_id
		 , @ppu_value_allow_negativ = ot.ppu_value_allow_negativ
		 , @tip_id = b.tip_id
	FROM dbo.Counters AS c 
		JOIN dbo.Buildings AS b ON c.build_id = b.id
		JOIN dbo.Occupation_Types ot ON ot.id = b.tip_id
	WHERE c.id = @counter_id1

	SELECT @max_value_vday =
							CASE
								WHEN @unit_id = 'квтч' THEN 200
								ELSE 20
							END

	SELECT TOP(1)
		@source_id = ch.source_id
		,@mode_id = ch.mode_id
	FROM dbo.Consmodes_list AS ch 
	JOIN dbo.Counter_list_all AS clh
		ON clh.service_id = ch.service_id
		AND clh.occ = ch.occ
	WHERE clh.fin_id = @fin_current
		AND clh.counter_id = @counter_id1
		AND (ch.mode_id % 1000) != 0
		AND (ch.source_id % 1000) != 0

	DECLARE @t TABLE (
		  fin_id SMALLINT
		, kod_insp INT
		, tarif DECIMAL(9, 4)
		, inspector_date SMALLDATETIME
		, d1 SMALLDATETIME
		, d2 SMALLDATETIME
		, kol_day SMALLINT
		, value_vday DECIMAL(14, 8)		
		, VALUE DECIMAL(12, 4)
		, mode_id INT DEFAULT NULL
		, fin_id_insp SMALLINT DEFAULT NULL
		, PRIMARY KEY (fin_id, kod_insp, tarif)
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
	)

	DECLARE @d1 SMALLDATETIME
		  , @d2 SMALLDATETIME -- временные переменные дат
		  , @Norma_extr_tarif DECIMAL(12, 6) = 0  -- норма для расчета по сверх нормативному
		  , @Norma_full_tarif DECIMAL(12, 6) = 0  -- норма для расчете по 100% тарифу
	
	DECLARE @tar1 DECIMAL(10, 4)=0, @extr_tar DECIMAL(9,2)=0, @full_tar DECIMAL(9,2)=0, @value1 DECIMAL(9,2)=0

	BEGIN TRY

		DECLARE curs2 CURSOR LOCAL FOR
			SELECT id
				 , ci.inspector_date
				 , ci.inspector_value
				 , ci.blocked
				 , CASE
                       WHEN ci.mode_id = 0 THEN CASE
                                                    WHEN @mode_counter > 0 THEN @mode_counter
                                                    ELSE @mode_id
                           END
                       ELSE ci.mode_id
                END
				 , ci.fin_id
			FROM dbo.Counter_inspector ci 
			WHERE ci.counter_id = @counter_id1
				AND ci.tip_value = @tip_value1      --11/04/2016
				AND ci.fin_id<@fin_current  -- 26/04/2023
			ORDER BY ci.inspector_date
				   , ci.id
		OPEN curs2
		FETCH NEXT FROM curs2 INTO @kod_inspector, @date_last, @value_last, @blocked_last, @mode_id, @fin_id

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT @Norma_extr_tarif=0, @Norma_full_tarif=0, @extr_tar=0, @full_tar=0
			if @service_id in ('элек')
			BEGIN
				SELECT @Norma_extr_tarif=COALESCE(norma_extr_tarif,0)
					, @Norma_full_tarif=COALESCE(norma_full_tarif,0)
				FROM dbo.Fun_GetNorma_tf(@unit_id, @mode_id, 1, @tip_id, @fin_id)

				SELECT @tar1=t1, @extr_tar=t2, @full_tar=t3 from dbo.Fun_GetCounterTarif_tf(@fin_id, @counter_id1, NULL, @fin_id,
                                                                                            CASE
                                                                                                WHEN @mode_counter > 0
                                                                                                    THEN @mode_counter
                                                                                                ELSE @mode_id
                                                                                                END, @source_id)
				
				IF @debug=1 
					SELECT @unit_id,@mode_id,@tip_id,@fin_current,@Norma_extr_tarif,@Norma_full_tarif
					--print @unit_id +' '+ str(@mode_id)+' '+ str(@tip_id)+' '+ str(@fin_id)+' '+dbo.FSTR(@Norma_extr_tarif,9,2)+' '+dbo.FSTR(@Norma_full_tarif,9,2)
			END;

			if (@Norma_extr_tarif>0 OR @Norma_full_tarif>=0) AND @extr_tar>0
			BEGIN
				if @debug=1 PRINT 'Нужен расчет по сверх нормативным тарифам'
			END
			ELSE
			BEGIN
				SELECT @d1 = SMALLDATETIMEFROMPARTS(YEAR(@date_first), MONTH(@date_first), 1, 0, 0)
					 , @d2 = SMALLDATETIMEFROMPARTS(YEAR(@date_last), MONTH(@date_last), 1, 0, 0)

				IF @debug = 1
					PRINT CONCAT('d1=', CONVERT(VARCHAR(10), @date_first, 104),'d2=', CONVERT(VARCHAR(10), @date_last, 104) )

				INSERT INTO @t (fin_id, kod_insp, inspector_date, d1, d2, kol_day, value_vday, tarif, mode_id, fin_id_insp)
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
					 , tarif = 0
					 , @mode_id
					 , @fin_id
				FROM dbo.Global_values 
				WHERE start_date BETWEEN @d1 AND @d2

				--*****************
				SET @date_first = DATEADD(DAY, 1, @date_last)  -- 16/02/2011
				--SET @date_first=@date_last

				UPDATE @t
				SET d2 = d1
				WHERE d2 < d1

				UPDATE @t
				SET @kol_day = kol_day = DATEDIFF(DAY, d1, d2) + 1   -- 30/06/2005
				WHERE kod_insp = @kod_inspector

				IF @debug=1 PRINT CONCAT('value_last=', @value_last,' value_first=', @value_first)
			
				IF @ppu_value_allow_negativ = 1
				BEGIN
					SET @actual_value1 = @value_last - @value_first
					SET @value_vday = @actual_value1 / @kol_day

					IF ABS(@value_vday) > @max_value_vday  -- то считаем что показания перешли макс значение
						SET @actual_value1 = @max_value1 + 1 + @value_last - @value_first
				END
				ELSE
				BEGIN
					IF @value_last >= @value_first
						SET @actual_value1 = @value_last - @value_first
					ELSE
						SET @actual_value1 = @max_value1 + 1 + @value_last - @value_first
				END
				SET @value_vday = @actual_value1 / @kol_day
				IF @debug = 1
					PRINT CONCAT('actual_value=', @actual_value1,' value_vday=', @value_vday)				

				IF (ABS(@value_vday) > @max_value_vday) AND (@tip_value1=1) -- ограничиваем только показания жителей
				BEGIN
					IF @debug = 1
						PRINT 'защита от переполнения: в день ' + dbo.FSTR(@value_vday, 14, 8) + ', max:' + dbo.FSTR(@max_value_vday, 9, 0)
					SET @actual_value1 = 0  -- защита от переполнения  15.03.2021
					SET @value_vday = 0 -- @max_value_vday
				END


				IF @blocked_first = 1
					SET @actual_value1 = 0

				INSERT INTO @t2 (kod_insp, kol_day, actual_value, value_vday)
				SELECT kod_insp
					 , SUM(kol_day)
					 , @actual_value1
					 , 0
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

				SELECT @value_first = @value_last
					 , @blocked_first = @blocked_last

				-- Проверяем и Корректируем значения в день
				SELECT @ostatok = SUM(value_vday * kol_day)
				FROM @t AS t
				WHERE kod_insp = @kod_inspector

				IF @actual_value1 <> @ostatok
				BEGIN
					IF @debug = 1
						PRINT '@ostatok: ' + STR(@ostatok, 14, 6) + '   @actual_value1:' + STR(@actual_value1, 14, 6)
				END
				IF @debug = 1
					PRINT '@kod_inspector:' + STR(@kod_inspector)
			END

			-- читаем следующий показатель
			FETCH NEXT FROM curs2 INTO @kod_inspector, @date_last, @value_last, @blocked_last, @mode_id, @fin_id
		END

		CLOSE curs2
		DEALLOCATE curs2

		--*************************************************************************************
		IF @debug = 1 select '@t 1111',* from @t
		IF @debug = 1 select '@t2 111', * from @t2

		UPDATE t
		SET
		--tarif=dbo.Fun_GetCounterTarifMode( @counter_id1, NULL, mode_id)
			tarif = dbo.Fun_GetCounterTarifMode(t.fin_id, @counter_id1, NULL, mode_id, t.fin_id_insp)
		FROM @t AS t
		WHERE tarif=0 OR tarif is NULL

		UPDATE t
		SET VALUE = CASE
                        WHEN t2.actual_value <> 0 THEN t.kol_day * t.tarif * t2.value_vday
                        ELSE 0
            END
		FROM @t AS t
			JOIN @t2 AS t2 ON t.kod_insp = t2.kod_insp

		UPDATE @t2
		SET value_paym = (
			SELECT SUM(t.VALUE)
			FROM @t AS t
			WHERE t.kod_insp = t2.kod_insp
		)
		FROM @t2 AS t2

		IF @debug = 1 -- тестируем
		BEGIN
			SELECT '@t' AS t, * FROM @t
		END

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

		DELETE FROM dbo.Counter_paym
		WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1

		INSERT INTO dbo.Counter_paym (fin_id, counter_id, kod_insp, tip_value, kol_day, value_vday, tarif, VALUE)
		SELECT fin_id
			 , @counter_id1
			 , kod_insp
			 , @tip_value1
			 , kol_day
			 , value_vday
			 , tarif
			 , VALUE
		FROM @t

		IF @debug = 1 -- тестируем
		BEGIN
			SELECT '@t' AS t, *	FROM @t		
			SELECT '@t2' AS t, t2.*	FROM @t2 t2	ORDER BY kod_insp
		END

		UPDATE ci
		SET kol_day = t2.kol_day
		  , actual_value = t2.actual_value
		  , value_vday = t2.value_vday
			--tarif=dbo.Fun_GetCounterTarifInspector(ci.id), --t2.tarif,
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

	-- OK! выходим
	RETURN


QuitRollBack:
go

