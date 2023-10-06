CREATE   PROCEDURE [dbo].[k_counter_raschet_people]
(
	@counter_id1 INT  -- код счетчика
   ,@tip_value1	 SMALLINT = 0
   ,@debug		 BIT	  = 0
)
AS
	/*
	--
	--  Перерасчет по счетчику по показанию квартиросъемщика
	--
	Пузанов
	12.03.09
	*/

	SET NOCOUNT ON

	DECLARE @date_first		SMALLDATETIME
		   , -- дата снятия предпоследнего показания
			@value_first	INT
		   ,  -- значение предпоследнего показания
			@date_last		SMALLDATETIME
		   , -- дата снятия последнего показания
			@value_last		INT
		   ,  -- значение последнего показания
			@blocked_first  BIT
		   ,@blocked_last   BIT
		   ,@err			INT = 0
		   ,@res			INT
		   ,@kol_insp		INT -- кол-во показаний инспектора
		   ,@kod_inspector  INT -- код показателя инспектора
		   ,@inspector_date SMALLDATETIME -- дата показаний 
		   ,@kol_day		INT -- количество дней
		   ,@value_vday		DECIMAL(9, 4)  -- значение в день
		   ,@unit_id		VARCHAR(10) -- ед.измерения
		   ,@service_id		VARCHAR(10) -- код услуги
		   ,@actual_value1  DECIMAL(15, 4)
		   ,@max_value1		INT  -- максимальное значение счетчика
		   ,@fin_current	SMALLINT -- текущий фин. период
		   ,@build_id1		INT  -- код дома
		   ,@mode_id1		INT   -- режим потребления по услуге
		   ,@fin_tarif		SMALLINT -- код фин.периода за который брать тариф

	BEGIN TRY

		SELECT
			@fin_current = b.fin_current
		FROM dbo.COUNTERS AS c 
		JOIN dbo.BUILDINGS AS b 
			ON c.build_id = b.id

		-- Проверяем есть ли показания инспектора по заданному счетчику
		SELECT
			@kol_insp = COUNT(id)
		FROM dbo.COUNTER_INSPECTOR 
		WHERE counter_id = @counter_id1
		AND fin_id = @fin_current

		SELECT TOP 1
			@mode_id1 = COALESCE(mode_id, 0)
		   ,@kod_inspector = id
		   ,@actual_value1 = inspector_value
		   ,@inspector_date = inspector_date
		FROM dbo.COUNTER_INSPECTOR 
		WHERE counter_id = @counter_id1
		AND tip_value = @tip_value1
		AND fin_id = @fin_current
		ORDER BY id DESC --берем последний

		IF @debug = 1  -- тестируем
			SELECT
				'@kol_insp' = @kol_insp
			   ,'@mode_id1' = @mode_id1
			   ,'@kod_inspector' = @kod_inspector


		IF @kol_insp = 0
		BEGIN
			DELETE FROM dbo.COUNTER_PAYM
			WHERE counter_id = @counter_id1
				AND tip_value = @tip_value1
				AND fin_id = @fin_current
			RETURN
		END

		-- запоминаем параметрв счетчика
		SELECT
			@date_first = c.date_create
		   ,@value_first = c.count_value
		   ,@unit_id = c.unit_id
		   ,@service_id = c.service_id
		   ,@max_value1 = max_value
		   ,@build_id1 = build_id
		FROM dbo.COUNTERS AS c 
		WHERE c.id = @counter_id1


		DECLARE @t TABLE
			(
				fin_id		   SMALLINT
			   ,kod_insp	   INT			  DEFAULT 0
			   ,kol_day		   SMALLINT		  DEFAULT 0
			   ,value_vday	   DECIMAL(12, 4) DEFAULT 0
			   ,tarif		   DECIMAL(10, 4) DEFAULT 0
			   ,value		   DECIMAL(10, 2) DEFAULT 0
			   ,mode_id		   INT			  DEFAULT 0
			   ,inspector_date SMALLDATETIME  DEFAULT NULL
			   ,fin_tarif	   SMALLINT		  DEFAULT 0
			   ,PRIMARY KEY (fin_id, kod_insp)
			)


		INSERT INTO @t
		(fin_id
		,kod_insp
		,kol_day
		,value_vday
		,tarif
		,value
		,mode_id
		,inspector_date
		,fin_tarif)
			SELECT TOP 1
				fin_id
			   ,id
			   ,kol_day
			   ,value_vday
			   ,0
			   ,0
			   ,mode_id
			   ,inspector_date
			   ,fin_id
			FROM dbo.COUNTER_INSPECTOR 
			WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1
			AND fin_id = @fin_current
			ORDER BY id DESC --берем последний

		UPDATE @t
		SET fin_tarif = g.fin_id
		FROM dbo.GLOBAL_VALUES AS g
		JOIN @t AS t
			ON t.inspector_date BETWEEN g.start_date AND g.end_date


		-- Находи последнее учтенное значение
		SELECT TOP 1
			@value_last = COALESCE(inspector_value, 0)
		   ,@date_last = inspector_date
		FROM dbo.COUNTER_INSPECTOR 
		WHERE counter_id = @counter_id1
		AND tip_value = @tip_value1
		AND fin_id < @fin_current
		ORDER BY id DESC --берем последний


		IF COALESCE(@value_last, 0) = 0
		BEGIN
			SET @value_last = @value_first
			SET @date_last = @date_first
		END

		IF @actual_value1 >= @value_last
			SET @actual_value1 = @actual_value1 - @value_last
		ELSE
			SET @actual_value1 = @max_value1 + @actual_value1 - @value_last

		SET @kol_day = COALESCE(DATEDIFF(D, @date_last, @inspector_date) + 1, 1)

		IF @debug = 1
			SELECT
				'@actual_value1' = @actual_value1
			   ,'@value_last' = @value_last
			   ,'@date_last' = @date_last
			   ,'@kol_day' = @kol_day


		--if @debug=1  select * from @t_source

		--IF @debug=1  
		--SELECT
		--	--tarif=dbo.Fun_GetCounterTarf(fin_id, @counter_id1, inspector_date)
		--	tarif=dbo.Fun_GetCounterTarf(fin_id, @counter_id1, NULL)
		--	,kol_day=@kol_day
		--FROM @t AS t


		IF @debug = 1
			SELECT
				*
			FROM @t
		--if @debug=1 select * from @t_source

		IF @debug = 1
			SELECT
				@actual_value1 AS '@actual_value1'
			   ,@kol_day AS '@kol_day'

		UPDATE t
		SET value	   = tarif * @actual_value1
		   ,value_vday =
				CASE
					WHEN kol_day = 0 THEN 0
					ELSE @actual_value1 / kol_day
				END
		FROM @t AS t

		BEGIN TRAN

			DELETE FROM dbo.COUNTER_PAYM
			WHERE counter_id = @counter_id1
				AND tip_value = @tip_value1
				AND fin_id = @fin_current

			INSERT INTO dbo.COUNTER_PAYM
			(fin_id
			,counter_id
			,kod_insp
			,tip_value
			,kol_day
			,value_vday
			,tarif
			,value
			,mode_id)
				SELECT
					fin_id
				   ,@counter_id1
				   ,kod_insp
				   ,@tip_value1
				   ,kol_day
				   ,value_vday
				   ,tarif
				   ,value
				   ,mode_id
				FROM @t AS t
				WHERE t.fin_id = @fin_current

			UPDATE ci
			SET kol_day		 = t.kol_day
			   ,actual_value = @actual_value1
			   ,value_vday	 = t.value_vday
			FROM dbo.COUNTER_INSPECTOR AS ci,
			@t AS t
			WHERE ci.id = t.kod_insp

		COMMIT TRAN

		IF @debug = 1
		BEGIN
			SELECT
				*
			FROM @t
			SELECT
				*
			FROM dbo.COUNTER_PAYM
			WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1
		END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

