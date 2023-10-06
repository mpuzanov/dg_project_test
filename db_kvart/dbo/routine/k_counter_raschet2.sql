CREATE   PROCEDURE [dbo].[k_counter_raschet2]
(
	  @flat_id1 INT -- код квартиры
	, @service_id1 VARCHAR(10) -- услуга
	, @tip_value1 SMALLINT = 0 -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
	, @fin_current SMALLINT = NULL
	, @isRasHistory BIT = 0 -- расчет по всем показаниям с историей
)
AS
	/*
	Расчет по внутренним счетчикам
	
	EXEC k_counter_raschet2 8941,'хвод',1,1
	EXEC k_counter_raschet2 @flat_id1=79620,@service_id1='гвод',@tip_value1=1,@debug=1,@isRasHistory=1
	
	*/

	SET NOCOUNT ON

	IF @debug = 1
		PRINT 'k_counter_raschet2 ' + @service_id1

	DECLARE @strerror VARCHAR(8000)
		  , @counter_id1 INT
		  , @err INT = 0
		  , @kol_insp INT -- кол-во показаний инспектора
		  , @first_internal BIT
		  , @checked_fin_id SMALLINT
		  , @kol_occ TINYINT
		  , @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME

	IF @fin_current IS NULL
		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, @flat_id1, NULL)

	SELECT @start_date = start_date
		 , @end_date = end_date
	FROM dbo.Global_values gv
	WHERE gv.fin_id = @fin_current

	IF @isRasHistory IS NULL
		SET @isRasHistory = 0

	-- Выбираем счетчики с показаниями счетчиков в этой квартире по услуге
	DECLARE @counter_value TABLE (
		  counter_id INT NOT NULL
		, build_id INT
		, fin_id SMALLINT
		, kod_insp INT
		, inspector_date SMALLDATETIME
		, inspector_value DECIMAL(12, 4)
		, blocked BIT
		, checked_fin_id SMALLINT
		, PeriodCheck SMALLDATETIME DEFAULT NULL
		, KolmesForPeriodCheck SMALLINT DEFAULT 0
	)

	-- начисления по лицевым счетам по счетчику
	DECLARE @paym TABLE (
		  fin_id SMALLINT NOT NULL
		, occ INT NOT NULL
		, service_id VARCHAR(10) NOT NULL
		, counter_id INT NOT NULL		
		, mode_id INT NOT NULL DEFAULT 0
		, tarif DECIMAL(9, 4) NOT NULL DEFAULT 0

		, kol DECIMAL(9, 4) DEFAULT 0
		, kol_people TINYINT DEFAULT 0
		, TOTAL_SQ DECIMAL(10, 4) DEFAULT 0
		, value_norma DECIMAL(9, 2) DEFAULT 0
		, kol_counter SMALLINT DEFAULT 0
		, kol_inspector SMALLINT DEFAULT 0
		, counter_sum DECIMAL(10, 2) DEFAULT 0
		, PRIMARY KEY (fin_id, occ, service_id, counter_id, mode_id, tarif)
	)
	-- для хранения
	DECLARE @paym_temp TABLE (
		  fin_id SMALLINT NOT NULL
		, occ INT NOT NULL
		, service_id VARCHAR(10) NOT NULL
		, counter_id INT NOT NULL		
		, mode_id INT NOT NULL DEFAULT 0
		, tarif DECIMAL(9, 4) NOT NULL DEFAULT 0

		, kol DECIMAL(9, 4) DEFAULT 0
		, kol_people TINYINT DEFAULT 0
		, TOTAL_SQ DECIMAL(10, 4) DEFAULT 0		
		, value_norma DECIMAL(9, 2) DEFAULT 0
		, kol_counter SMALLINT DEFAULT 0
		, kol_inspector SMALLINT DEFAULT 0
		, counter_sum DECIMAL(10, 2) DEFAULT 0
		, PRIMARY KEY (fin_id, occ, service_id, counter_id, mode_id, tarif)
	)

	BEGIN TRY

		--IF @debug=1 print 'начали '+str(@fin_current)

		IF @isRasHistory = 0
			INSERT INTO @counter_value (counter_id
									  , build_id
									  , fin_id
									  , kod_insp
									  , inspector_date
									  , inspector_value
									  , blocked
									  , checked_fin_id
									  , PeriodCheck
									  , KolmesForPeriodCheck)
			SELECT c.id
				 , c.build_id
				 , B.fin_current
				 , ci.id AS kod_insp
				 , ci.inspector_date
				 , ci.inspector_value
				 , ci.blocked
				 , c.checked_fin_id
				 , COALESCE(c.PeriodCheck, '20500101')
				 , cl.KolmesForPeriodCheck
			FROM dbo.Counters AS c 
				LEFT JOIN dbo.Counter_inspector AS ci ON c.id = ci.counter_id
					AND fin_id = @fin_current
				JOIN dbo.Buildings AS B ON c.build_id = B.id
				JOIN dbo.Occupations o ON c.flat_id = o.flat_id
				JOIN dbo.Counter_list_all AS cl  ON o.occ = cl.occ
					AND cl.fin_id = B.fin_current
					AND c.id = cl.counter_id
			WHERE c.flat_id = @flat_id1
				AND c.service_id = @service_id1
				AND c.internal = CAST(1 AS BIT)
				AND B.is_paym_build = CAST(1 AS BIT)

		IF @isRasHistory = 1
			INSERT INTO @counter_value (counter_id
									  , build_id
									  , fin_id
									  , kod_insp
									  , inspector_date
									  , inspector_value
									  , blocked
									  , checked_fin_id
									  , PeriodCheck
									  , KolmesForPeriodCheck)
			SELECT c.id
				 , c.build_id
				 , ci.fin_id   --B.fin_current
				 , ci.id AS kod_insp
				 , ci.inspector_date
				 , ci.inspector_value
				 , ci.blocked
				 , c.checked_fin_id
				 , COALESCE(c.PeriodCheck, '20500101')
				 , cl.KolmesForPeriodCheck
			FROM dbo.Counters AS c
				LEFT JOIN dbo.Counter_inspector AS ci ON c.id = ci.counter_id
				--AND fin_id = @fin_current
				JOIN dbo.Buildings AS B ON c.build_id = B.id
				JOIN dbo.Occupations o ON c.flat_id = o.flat_id
				JOIN dbo.Counter_list_all AS cl ON o.occ = cl.occ
					AND cl.fin_id = B.fin_current
					AND c.id = cl.counter_id
			WHERE c.flat_id = @flat_id1
				AND c.service_id = @service_id1
				AND c.internal = CAST(1 AS BIT)
				AND B.is_paym_build = CAST(1 AS BIT)

		IF @debug = 1
			SELECT 'counter_value' AS tbl
				 , *
			FROM @counter_value
		--******************************************************
		-- убираем записи с истёкшей датой поверки

		DELETE c
		FROM @counter_value AS c
			JOIN dbo.Buildings AS B ON c.build_id = B.id
			JOIN dbo.Occupation_Types AS OT ON B.tip_id = OT.id
		WHERE c.KolmesForPeriodCheck <= 0
			AND (
			(OT.ras_no_counter_poverka = CAST(1 AS BIT)
			AND c.PeriodCheck <= OT.start_date)
			OR (B.ras_no_counter_poverka = 1
			AND c.PeriodCheck <= OT.start_date)
			)
			AND c.PeriodCheck < '20200401'  -- 22.04.20 приостановка в связи с короновирусом

		IF @debug = 1
			SELECT 'counter_value2' AS tabl_counter_value
				 , *
			FROM @counter_value
		--*******************************************************
		UPDATE ci
		SET value_paym = 0
		FROM dbo.Counters AS c 
			JOIN dbo.Counter_inspector AS ci ON c.id = ci.counter_id
		WHERE c.flat_id = @flat_id1
			AND ci.fin_id = @fin_current
			AND c.service_id = @service_id1

		DELETE cp
		FROM dbo.Counter_paym AS cp
			JOIN (
				SELECT counter_id
					 , COUNT(kod_insp) AS kol
				FROM @counter_value
				WHERE kod_insp IS NOT NULL
				GROUP BY counter_id
			) AS c ON cp.counter_id = c.counter_id
		WHERE c.kol = 0
			AND tip_value = @tip_value1
			AND cp.fin_id = @fin_current

		DELETE cp2
		FROM dbo.Counter_paym2 AS cp2
			JOIN dbo.Occupations AS o ON cp2.occ = o.occ
		WHERE cp2.fin_id = @fin_current
			AND cp2.service_id = @service_id1
			AND o.flat_id = @flat_id1
			AND cp2.tip_value = @tip_value1
		--*******************************************************

		-- Если расчёт по показаниям квартиросьёмщика, а показаний нет, то не считаем 
		IF @tip_value1 = 1
			DELETE FROM @counter_value
			WHERE kod_insp IS NULL

		DECLARE curs1 CURSOR LOCAL FOR
			SELECT DISTINCT counter_id
			FROM @counter_value

		OPEN curs1
		FETCH NEXT FROM curs1 INTO @counter_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			IF @debug = 1
				PRINT CONCAT('Код счётчика: ', @counter_id1,', @isRasHistory: ', @isRasHistory)

			IF @isRasHistory = 0
			BEGIN
				IF @debug = 1
					PRINT CONCAT('k_counter_raschet_id_new @counter_id1=', @counter_id1,', @tip_value1=', @tip_value1,', @debug=1')

				EXEC @err = dbo.k_counter_raschet_id_new @counter_id1 = @counter_id1
													   , @tip_value1 = @tip_value1
													   , @debug = 0 --@debug
			END
			ELSE
			BEGIN
				IF @debug = 1
					PRINT CONCAT('k_counter_raschet_id @counter_id1=', @counter_id1,', @tip_value1=', @tip_value1,', @debug=1')

				EXEC @err = dbo.k_counter_raschet_id @counter_id1 = @counter_id1
												   , @tip_value1 = @tip_value1
												   , @debug = 0 --@debug

			END
			IF @err <> 0
			BEGIN
				DEALLOCATE curs1
				SET @strerror = 'Ошибка при перерасчете ПУ: ' + STR(@counter_id1)
				EXEC dbo.k_adderrors_card @strerror
				RETURN @err
			END

			-- 'Раскидываем по лицевым счетам'
			DELETE FROM @paym_temp

			INSERT INTO @paym_temp (fin_id
								  , occ
								  , service_id
								  , counter_id								  
								  , tarif
								  , kol
								  , counter_sum
								  , mode_id)
			SELECT @fin_current
				 , cl.occ
				 , @service_id1
				 , cl.counter_id
				 , t.tarif
				 --, CASE
					--   WHEN SUM(COALESCE(ci.tarif, 0)) = 0 THEN 0
					--   WHEN COUNT(ci.id) = 1 THEN (SUM(COALESCE(ci.tarif, 0)) / COUNT(ci.id))
					--   WHEN SUM(COALESCE(ci.tarif, 0)) > 0 THEN (AVG(COALESCE(ci.tarif, 0)))  --03.03.14
					--   WHEN SUM(ci.actual_value) > 0 THEN (SUM(ci.value_paym) / SUM(ci.actual_value))
					--   ELSE (SUM(COALESCE(ci.tarif, 0)) / COUNT(ci.id))
				 --  END AS tarif				 				
				 , SUM(t.kol) --, SUM(ci.actual_value)
				 , SUM(t.value)	--, SUM(ci.value_paym)			 				 
				 , ci.mode_id
			FROM dbo.Counter_inspector AS ci 
				JOIN (SELECT DISTINCT counter_id FROM @counter_value) AS c ON ci.counter_id = c.counter_id
				JOIN dbo.Counter_list_all AS cl ON c.counter_id = cl.counter_id
					AND ci.fin_id = cl.fin_id
				JOIN dbo.Occupations AS o ON cl.occ = o.occ
				CROSS APPLY (SELECT cp.tarif, CAST(cp.kol_day*cp.value_vday AS DECIMAL(12,6)) as kol, cp.value 
					FROM dbo.Counter_paym as cp
					WHERE cp.counter_id=ci.counter_id and cp.kod_insp=ci.id) AS t
			WHERE ci.fin_id = @fin_current
				AND ci.tip_value = @tip_value1
				AND cl.counter_id = @counter_id1
				AND o.STATUS_ID <> 'закр'
			--AND o.total_sq <> 0   -- 29/09/2021
			GROUP BY cl.occ
				   , cl.counter_id
				   , ci.mode_id
				   , t.tarif

			--UPDATE t
			--SET mode_id=cml.MODE_ID
			--FROM @paym_temp AS t
			--JOIN dbo.CONSMODES_LIST AS cml ON t.occ=cml.occ AND t.service_id=cml.service_id 
			--WHERE (cml.MODE_ID % 1000) != 0 

			IF @debug = 1 SELECT '@paym_temp' as tbl, * FROM @paym_temp

			SELECT @kol_occ = COUNT(distinct occ) FROM @paym_temp WHERE counter_id = @counter_id1
			IF @debug = 1
				PRINT '@kol_occ: ' + STR(@kol_occ)

			-- если в квартире несколько лицевых
			--if exists(select service_id, count(occ) from @paym group by service_id having count(occ)>1)
			IF @kol_occ > 1
			BEGIN -- Надо раскидывать сумму на лиц.счета
				IF @debug = 1
					PRINT 'Раскидываем по лицевым по счетчику:' + STR(@counter_id1)

				DECLARE @sum DECIMAL(10, 2)
					  , @kol DECIMAL(9, 4)
					  , @sum_value_norma DECIMAL(10, 2)
					  , @sum_total_sq DECIMAL(10, 4)
					  , @kol_people TINYINT
					  , @ostatok DECIMAL(10, 2)

				SELECT TOP (1) @sum = COALESCE(counter_sum, 0)
						   , @kol = COALESCE(kol, 0)
				FROM @paym_temp
				--select @sum, @kol

				UPDATE t
				SET TOTAL_SQ = o.TOTAL_SQ
				  , kol_people = (
						SELECT COUNT(p.id)
						FROM dbo.People AS p 
							JOIN dbo.Person_statuses AS ps ON p.Status2_id = ps.id
							JOIN dbo.Person_calc AS pc ON ps.id = pc.STATUS_ID
						WHERE p.occ = t.occ
							AND (p.Del = CAST(0 AS BIT) OR p.DateDel BETWEEN @start_date AND @end_date)
							AND pc.service_id = t.service_id
							AND pc.have_paym = CAST(1 AS BIT)
					)
				  , value_norma = COALESCE(pc.value, 0)
				FROM @paym_temp AS t
					JOIN dbo.Occupations AS o ON t.occ = o.occ
					LEFT JOIN dbo.Paym_counter_all AS pc ON t.occ = pc.occ
						AND t.service_id = pc.service_id
						AND t.fin_id = pc.fin_id
				WHERE mode_id IS NOT NULL

				--if @debug=1  select '1'
				if @debug=1  select '@paym_temp 2' as tbl, * from @paym_temp

				UPDATE t
				SET kol_people = 0
				  , counter_sum = 0
				  , TOTAL_SQ = 0
				FROM @paym_temp AS t
				WHERE mode_id IS NULL

				SELECT @sum_total_sq = SUM(TOTAL_SQ)
					 , @kol_people = SUM(COALESCE(kol_people, 0))
					 , @sum_value_norma = SUM(COALESCE(value_norma, 0))
				FROM @paym_temp

				if @debug=1  SELECT @sum_total_sq AS sum_total_sq, @kol_people AS kol_people, @sum_value_norma AS sum_value_norma, @kol AS kol

				IF @service_id1 = 'отоп'
				BEGIN
					UPDATE t -- раскидываем по площади
					SET kol = TOTAL_SQ * (@kol / @sum_total_sq)
					  , counter_sum = tarif * (TOTAL_SQ * (@kol / @sum_total_sq))
					FROM @paym_temp AS t
				END
				ELSE
				--IF @service_id1 = 'элек'
				--	AND @sum_value_norma != 0
				--BEGIN -- раскидываем по начислению по норме
				--	UPDATE t
				--	SET	kol				= coalesce(value_norma, 0) * (@kol / @sum_value_norma)
				--		,counter_sum	= tarif * (coalesce(value_norma, 0) * (@kol / @sum_value_norma))
				--	FROM @paym_temp AS t
				--END
				--ELSE
				BEGIN -- раскидываем по людям 
					IF @kol_people > 0
					BEGIN
						UPDATE t
						SET kol = kol_people * (@kol / @kol_people)
						  , counter_sum = tarif * (kol_people * (@kol / @kol_people))
						FROM @paym_temp AS t
					END
					ELSE
					BEGIN
						--IF @debug=1 PRINT @kol_occ
						UPDATE t -- делим на кол.лицевых
						SET kol = @kol / @kol_occ
						  , counter_sum = tarif * (@kol / @kol_occ)
						FROM @paym_temp AS t
					END
				END

			--IF @debug=1 SELECT * FROM @paym_temp
			END

			INSERT INTO @paym
			SELECT *
			FROM @paym_temp

			-- читаем следующий счетчик
			FETCH NEXT FROM curs1 INTO @counter_id1
		END

		CLOSE curs1
		DEALLOCATE curs1

		UPDATE pt
		SET kol_counter = t2.kol_counter
		  , kol_inspector = t2.kol_inspector
		FROM @paym pt
			CROSS APPLY (
				SELECT SUM(kol) AS kol_inspector
					 , COUNT(counter_id) AS kol_counter
				FROM (
					SELECT cla.counter_id
						 , CASE
							   WHEN COUNT(COALESCE(ci.id, 0)) >= 1 THEN 1
							   ELSE 0
						   END AS kol
					FROM dbo.Counter_list_all cla
						LEFT JOIN dbo.Counter_inspector AS ci ON ci.fin_id = cla.fin_id
							AND ci.counter_id = cla.counter_id
					WHERE cla.fin_id = pt.fin_id
						AND cla.service_id = pt.service_id
						AND cla.occ = pt.occ
					GROUP BY cla.counter_id
				) AS t
			) AS t2

		-- раскидка потребления по лицевым по месяцам
		IF EXISTS (SELECT 1 FROM @counter_value)
			EXEC dbo.k_counter_occ_kol2 @flat_id1
								  , @service_id1
								  , @tip_value1
								  , @debug = @debug
								  , @fin_current = @fin_current

		IF @debug = 1 SELECT '@paym', * FROM @paym

		-- Записываем в dbo.COUNTER_PAYM2

		DELETE cp2
		FROM dbo.Counter_paym2 AS cp2
			JOIN @paym AS p ON cp2.fin_id = p.fin_id
				AND cp2.occ = p.occ
				AND cp2.service_id = p.service_id
		WHERE cp2.tip_value = @tip_value1

		IF @debug = 1
			SELECT 'Counter_paym2', cp2.*
			FROM dbo.Counter_paym2 AS cp2
				JOIN @paym AS p ON cp2.fin_id = p.fin_id
					AND cp2.occ = p.occ
					AND cp2.service_id = p.service_id

		INSERT INTO dbo.Counter_paym2 (fin_id
									 , occ
									 , service_id
									 , tip_value
									 , value
									 , added
									 , paid
									 , kol
									 , tarif
									 , kol_counter
									 , kol_inspector)
		SELECT fin_id
			 , occ
			 , service_id
			 , @tip_value1
			 , SUM(counter_sum)
			 , 0
			 , SUM(counter_sum)
			 , SUM(kol)
			 , tarif AS tarif
			 , MAX(kol_counter)
			 , MAX(kol_inspector)
		FROM @paym AS p
		GROUP BY occ
			   , fin_id
			   , service_id
			   , tarif

		IF @debug = 1
			SELECT 'Counter_paym2 2', cp2.*
			FROM dbo.Counter_paym2 AS cp2 
				JOIN (SELECT DISTINCT occ FROM @paym) AS p ON cp2.occ = p.occ

		SELECT TOP 1 @checked_fin_id = checked_fin_id
		FROM @counter_value

		--SELECT
		--	@first_internal = [dbo].[Fun_FirstInternalCounter](@flat_id1, @service_id1, @fin_current)
		-- закоментировал 10/01/2013

		SELECT @first_internal = 0

		IF @tip_value1 = 1
			AND @first_internal = 1
			AND @checked_fin_id IS NULL
		BEGIN -- суммы по показаниям инспектора кидаем в разовые по показаниям квартиросъемщика     
			UPDATE cp1
			SET added = cp2.paid - (cp1.value - cp1.discount)
			  , paid = cp2.paid
			FROM dbo.Counter_paym2 AS cp1
				JOIN dbo.Counter_paym2 AS cp2 ON cp1.occ = cp2.occ
					AND cp1.fin_id = cp2.fin_id
					AND cp1.service_id = cp2.service_id
				JOIN (SELECT DISTINCT occ, service_id FROM @paym) AS p ON cp1.occ = p.occ
					AND cp1.service_id = p.service_id
			WHERE cp1.tip_value = 1
				AND cp2.tip_value = 0
				--and (cp1.kol=0 and  cp1.paid=0) 
				AND (cp2.kol > 0 AND cp2.paid > 0)
			IF @@rowcount > 0
			BEGIN
				--print 'суммы по показаниям инспектора кидаем в разовые по показаниям квартиросъемщика'

				DECLARE @fin_start SMALLINT = 1

				WHILE @fin_start < @fin_current
				BEGIN
					UPDATE cp2
					SET saldo =
					COALESCE((
						SELECT TOP (1) cp1.debt
						FROM dbo.Counter_paym2 AS cp1 
						WHERE cp1.fin_id < cp2.fin_id
							AND cp1.occ = cp2.occ
							AND cp1.tip_value = @tip_value1
							AND cp1.service_id = cp2.service_id
						ORDER BY cp1.fin_id DESC
					), 0)
					FROM dbo.Counter_paym2 AS cp2
						JOIN (SELECT DISTINCT occ, service_id FROM @paym) AS p ON cp2.occ = p.occ
							AND cp2.service_id = p.service_id
							AND cp2.tip_value = @tip_value1
					WHERE cp2.fin_id = @fin_start

					SET @fin_start = @fin_start + 1
				END

			END
		END

	END TRY

	BEGIN CATCH
		SET @strerror = CONCAT('Код квартиры: ', @flat_id1,', Адрес: ',  dbo.Fun_GetAdresFlat(@flat_id1))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
		RETURN @err

	END CATCH
go

