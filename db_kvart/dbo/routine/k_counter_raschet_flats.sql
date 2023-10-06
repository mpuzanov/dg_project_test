CREATE   PROCEDURE [dbo].[k_counter_raschet_flats]
(
	  @flat_id1 INT -- код квартиры 
	, @tip_value1 SMALLINT = 0 -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
)
AS
	/*
Расчет(распределение начислений) по счетчикам на лицевых счетах в квартире

проводится после расчета всех счетчиков
процедурой k_counter_raschet

дата: 13.04.2005, 30/06/2005,   14/08/2006, 3/06/2009
автор: Пузанов

*/
	SET NOCOUNT ON

	BEGIN TRY

		DECLARE @err INT
			  , @fin_current SMALLINT -- текущий фин. период
			  , @strerror VARCHAR(8000)

		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, @flat_id1, NULL)

		-- Выбираем все счетчики по квартире
		DECLARE @counter_flats TABLE (
			  counter_id INT
			, service_id VARCHAR(10)
			, occ INT
			, fin_id SMALLINT
		)

		INSERT INTO @counter_flats (counter_id
								  , service_id
								  , occ
								  , fin_id)
		SELECT c.id
			 , c.service_id
			 , cla.occ
			 , cla.fin_id
		FROM dbo.Counters AS c
			JOIN dbo.Counter_list_all AS cla 
				ON c.id = cla.counter_id
			JOIN dbo.Buildings AS B 
				ON c.build_id = B.id
			JOIN dbo.Occupation_Types ot 
				ON B.tip_id = ot.id
		WHERE c.flat_id = @flat_id1
			AND (c.internal = 0 OR c.internal IS NULL) --and internal=0
			AND B.is_paym_build = 1
			AND ot.payms_value = 1

		IF @debug = 1
			SELECT *
			FROM @counter_flats
			ORDER BY fin_id

		-- делаем перерасчет по счетчикам в квартире
		DECLARE @cur_id1 INT
		DECLARE some_cur CURSOR FOR
			SELECT counter_id
			FROM @counter_flats
		OPEN some_cur

		WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM some_cur INTO @cur_id1

			IF @@fetch_status <> 0
				BREAK

			EXEC @err = dbo.k_counter_raschet @counter_id1 = @cur_id1
											, @tip_value1 = @tip_value1

			IF @err <> 0
			BEGIN
				DEALLOCATE some_cur
				SET @strerror = 'Ошибка при перерасчете счетчика : ' + STR(@cur_id1)
				EXEC dbo.k_adderrors_card @strerror
				RETURN @err
			END

		END
		DEALLOCATE some_cur

		IF NOT EXISTS (SELECT * FROM @counter_flats)
			RETURN


		IF @debug = 1
			PRINT 'Расчитываем по счетчикам'

		-- начисления по лицевым счетам в квартире
		DECLARE @paym TABLE (
			  fin_id SMALLINT
			, occ INT
			, service_id VARCHAR(10)
			, counter_sum DECIMAL(10, 2) DEFAULT 0
			, value_norma DECIMAL(10, 2) DEFAULT 0
			, value_counter DECIMAL(10, 2) DEFAULT 0
			, norma_discount DECIMAL(10, 2) DEFAULT 0
			, counter_discount DECIMAL(10, 2) DEFAULT 0
			, added DECIMAL(10, 2) DEFAULT 0
			, tarif DECIMAL(9, 4) DEFAULT 0
			, kol DECIMAL(9, 4) DEFAULT 0
			, counter_id INT DEFAULT NULL
			, PRIMARY KEY (fin_id, occ, service_id, counter_id)
		)

		INSERT INTO @paym (fin_id
						 , occ
						 , service_id
						 , counter_sum
						 , value_norma
						 , value_counter
						 , norma_discount
						 , counter_discount
						 , added
						 , tarif
						 , kol
						 , counter_id)
		SELECT cl.fin_id
			 , cl.occ
			 , cl.service_id
			 , 0
			 , COALESCE(Value, 0)
			 , 0
			 , COALESCE(Discount, 0)
			 , 0
			 , COALESCE(added, 0)
			 , 0
			 , 0
			 , cl.counter_id
		FROM @counter_flats AS cl
			JOIN dbo.View_paym_counter AS ph2 
				ON cl.occ = ph2.occ
				AND cl.service_id = ph2.service_id
				AND cl.fin_id = ph2.fin_id

		--if @debug=1 select * from @paym
		/* 
ситуация когда добавили счетчик в конце месяца:
фин. период уже закрыт
начислений по норме нет по этому месяцу
лицевых так же нет
*/
		INSERT INTO @paym (fin_id
						 , occ
						 , service_id
						 , counter_sum
						 , counter_id)
		SELECT cp.fin_id
			 , cl.occ
			 , cf.service_id
			 , COALESCE(SUM(Value), 0)
			 , cf.counter_id
		FROM dbo.Counter_paym AS cp 
			JOIN @counter_flats AS cf 
				ON cp.counter_id = cf.counter_id
			JOIN dbo.Counter_list_all AS cl 
				ON cp.counter_id = cl.counter_id
		WHERE cp.tip_value = @tip_value1
			AND cl.fin_id = cp.fin_id --(cp.fin_id+1)   --  берем лицевые из след. месяца
			AND NOT EXISTS (
				SELECT 1
				FROM @paym
				WHERE fin_id = cp.fin_id
					AND service_id = cf.service_id
			)
			AND cl.internal = 0 -- только внешние счётчики  14.02.2011
		GROUP BY cp.fin_id
			   , cl.occ
			   , cf.service_id
			   , cf.counter_id

		--if @debug=1 select * from @paym

		IF NOT EXISTS (
				SELECT *
				FROM @paym
				WHERE fin_id = @fin_current
			)
		BEGIN
			--print @fin_current 
			INSERT INTO @paym (fin_id
							 , occ
							 , service_id
							 , counter_sum
							 , counter_id)
			SELECT @fin_current
				 , cl.occ
				 , cf.service_id
				 , 0
				 , cf.counter_id
			FROM @counter_flats AS cf
				JOIN dbo.Counter_list_all AS cl 
					ON cf.counter_id = cl.counter_id
			WHERE cl.fin_id = @fin_current - 1
				AND NOT EXISTS (
					SELECT 1
					FROM @paym
					WHERE fin_id = @fin_current
				)
				AND cl.internal = 0 -- только внешние счётчики  14.02.2011
			GROUP BY cl.fin_id
				   , cl.occ
				   , cf.service_id
				   , cf.counter_id
		END

		--if @debug=1 select * from @paym

		UPDATE p
		SET counter_sum = (
				SELECT COALESCE(SUM(Value), 0)
				FROM dbo.Counter_paym AS cp
				   , @counter_flats AS cf
				WHERE cp.fin_id = p.fin_id
					AND cp.fin_id = cf.fin_id
					AND cf.occ = p.occ
					AND cp.counter_id = cf.counter_id
					AND cp.tip_value = @tip_value1
					AND cf.service_id = p.service_id
					AND cp.counter_id = p.counter_id
				GROUP BY cp.fin_id
			)
		  , kol = (
				SELECT COALESCE(SUM(value_vday * kol_day), 0)
				FROM dbo.Counter_paym AS cp 
				   , @counter_flats AS cf
				WHERE cp.fin_id = p.fin_id
					AND cp.fin_id = cf.fin_id
					AND cf.occ = p.occ
					AND cp.counter_id = cf.counter_id
					AND cp.tip_value = @tip_value1
					AND cf.service_id = p.service_id
					AND cp.counter_id = p.counter_id
				GROUP BY cp.fin_id
			)
		  , tarif = dbo.Fun_GetCounterTarf(p.fin_id, p.counter_id, NULL) --t.inspector_date)                                
		FROM @paym AS p
		--where value_norma>0

		--if @debug=1 print '2'
		IF @debug = 1
			SELECT *
			FROM @paym

		--**********************************************

		DECLARE @fin1 SMALLINT
			  , @sum1 DECIMAL(9, 2)
			  , @sum_counter DECIMAL(9, 2)
			  , @koef1 DECIMAL(10, 4)
			  , @ostatok DECIMAL(9, 2)
			  , @service_id1 VARCHAR(10)
			  , @occ2 INT
			  , @counter_id1 INT

		DECLARE some_cur CURSOR FOR
			SELECT DISTINCT fin_id
						  , service_id
						  , counter_id
			FROM @paym
			WHERE counter_sum > 0

		OPEN some_cur

		WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM some_cur INTO @fin1, @service_id1, @counter_id1

			IF @@fetch_status <> 0
				BREAK

			SELECT @sum1 = SUM(COALESCE(value_norma, 0))
			FROM @paym
			WHERE fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1

			SELECT TOP (1) @sum_counter = counter_sum
			FROM @paym
			WHERE fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1
			ORDER BY counter_sum DESC

			--if @debug=1 print '@sum_counter'+str(@sum_counter,9,4)
			--if @debug=1 print '@sum1'+str(@sum1,9,4)

			IF @sum1 = 0
				SET @sum1 = 1

			SELECT @koef1 = @sum_counter / @sum1
			--if @debug=1 print @koef1   
			--if @debug=1 select * from @paym 

			UPDATE @paym
			SET value_counter =
							   CASE
								   WHEN @sum1 <> 1 THEN @koef1 * value_norma
								   ELSE counter_sum
							   END
			WHERE 
				fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1

			UPDATE @paym
			SET kol = kol * (value_counter / counter_sum)
			WHERE 
				fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1
				AND value_counter > 0

			--select
			--kol=kol*(value_counter/counter_sum),kol,value_counter,counter_sum
			--from @paym
			--where fin_id=@fin1
			--  and service_id=@service_id1
			--   and counter_id=@counter_id1

			--if @debug=1 select * from @paym     

			-- Проверяем копейки  **************
			SELECT @ostatok = SUM(COALESCE(value_counter, 0))
			FROM @paym
			WHERE fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1

			SET @ostatok = @sum_counter - @ostatok

			IF @ostatok <> 0
			BEGIN
				--if @debug=1 print '@ostatok:'+ str(@ostatok,9,4)

				;with cte as (
					SELECT TOP(1) *
					FROM @paym AS p
					WHERE fin_id = @fin1
						AND service_id = @service_id1
						AND counter_id = @counter_id1
						AND p.value_counter > ABS(@ostatok)
				)
				UPDATE cte
				SET value_counter = value_counter + @ostatok;
				
			END
			--if @debug=1 select * from @paym  
			--**********************************

			-- Льгота
			SELECT @koef1 = 0
			SELECT @koef1 = (norma_discount * 100 / value_norma)
			FROM @paym
			WHERE fin_id = @fin1
				AND service_id = @service_id1
				AND value_norma > 0
				AND counter_id = @counter_id1
			--   print @fin1
			--   print @koef1

			UPDATE p
			SET counter_discount = value_counter * @koef1 * 0.01
			FROM @paym AS p
			WHERE fin_id = @fin1
				AND service_id = @service_id1
				AND counter_id = @counter_id1
				AND value_counter > 0
				AND norma_discount > 0;

		--**********************************

		END
		DEALLOCATE some_cur

		IF @debug = 1
			SELECT *
			FROM @paym
		--***********************************************

		--if @debug=1 
		--select cp2.* from dbo.COUNTER_PAYM2 as cp2 
		--where cp2.occ=60437 and cp2.tip_value=@tip_value1 and cp2.service_id='элек'

		-- записать в COUNTER_PAYM2
		DELETE cp2
		FROM dbo.Counter_paym2 AS cp2
			JOIN @paym AS p2 ON cp2.occ = p2.occ
				AND cp2.fin_id = p2.fin_id
				AND cp2.service_id = p2.service_id
				AND cp2.tip_value = @tip_value1;

		INSERT INTO dbo.Counter_paym2 (fin_id
									 , occ
									 , service_id
									 , tip_value
									 , tarif
									 , Value
									 , Discount
									 , added
									 , Paid
									 , kol)
		SELECT DISTINCT -- добавил distinct 4.06.09
			fin_id
		  , occ
		  , service_id
		  , @tip_value1
		  , tarif
		  , SUM(COALESCE(value_counter, 0))
		  , SUM(COALESCE(counter_discount, 0))
		  , SUM(COALESCE(added, 0))
		  , paid = SUM(COALESCE(value_counter, 0) - COALESCE(counter_discount, 0)) --+coalesce(added,0),                 
		  , kol = SUM(COALESCE(kol, 0)) -- 27/07/09
		FROM @paym AS p2
		GROUP BY fin_id
			   , occ
			   , service_id
			   , tarif;

		--if @debug=1 print '1'

		-- вычисляем сальдо и заносим разовые из истории на каждый месяц
		UPDATE dbo.Counter_paym2
		SET added = COALESCE((
				SELECT SUM(t2.Value)
				FROM dbo.Added_Counters_All AS t2 
				WHERE t2.occ = cp2.occ
					AND t2.service_id = cp2.service_id
					AND t2.fin_id = cp2.fin_id
			), 0)
		  , PaymAccount = COALESCE((
				SELECT SUM(ps.Value)
				FROM dbo.Paying_serv AS ps
				JOIN dbo.Payings AS p 
					ON ps.paying_id = p.id
				WHERE 
					p.fin_id = p2.fin_id
					AND p.occ = p2.occ
					AND ps.service_id = p2.service_id
			), 0)
		  , tarif = p2.tarif
		--,kol=p2.kol     -- 27/07/09  
		FROM dbo.Counter_paym2 AS cp2
		   , @paym AS p2
		WHERE 
			cp2.fin_id = p2.fin_id
			AND cp2.service_id = p2.service_id
			AND cp2.occ = p2.occ
			AND cp2.tip_value = @tip_value1;


		UPDATE dbo.Counter_paym2
		SET SALDO = COALESCE((
			SELECT SUM(Debt)
			FROM dbo.Counter_paym2 
			WHERE fin_id < cp2.fin_id
				AND occ = cp2.occ
				AND tip_value = @tip_value1
				AND service_id = cp2.service_id
		), 0)
		FROM dbo.Counter_paym2 AS cp2
			JOIN @paym AS p2 
				ON cp2.fin_id = p2.fin_id
				AND cp2.service_id = p2.service_id
				AND cp2.occ = p2.occ
				AND cp2.tip_value = @tip_value1


		-- заносим разовые за текущий месяц
		UPDATE dbo.Counter_paym2
		SET added = COALESCE((
			SELECT SUM(t2.Value)
			FROM dbo.Added_Counters_All AS t2 
			WHERE t2.occ = cp2.occ
				AND t2.service_id = cp2.service_id
				AND t2.fin_id = @fin_current
				AND cp2.fin_id = @fin_current
		), 0)
		FROM dbo.Counter_paym2 AS cp2
			JOIN @paym AS p2 
				ON cp2.fin_id = p2.fin_id
				AND cp2.service_id = p2.service_id
				AND cp2.occ = p2.occ
				AND cp2.tip_value = @tip_value1;

		-- Обновляем PAID
		UPDATE cp2
		SET Paid = cp2.Value + cp2.added - cp2.Discount
		FROM dbo.Counter_paym2 AS cp2
			JOIN @paym AS p2 
				ON cp2.fin_id = p2.fin_id
				AND cp2.service_id = p2.service_id
				AND cp2.occ = p2.occ
				AND cp2.tip_value = @tip_value1;

		IF @debug = 1
			SELECT p1.*
			FROM dbo.Counter_paym2 AS p1 
			   , @paym AS p2
			WHERE p1.occ = p2.occ
				AND p1.fin_id = p2.fin_id
				AND p1.service_id = p2.service_id
				AND p1.tip_value = @tip_value1
			ORDER BY p1.fin_id;

	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + 'Код квартиры: ' + LTRIM(STR(@flat_id1)) + ' Адрес:' + dbo.Fun_GetAdresFlat(@flat_id1)

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

		RETURN @err

	END CATCH

	-- OK! выходим
	RETURN


QuitRollBack:
go

