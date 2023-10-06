CREATE   PROCEDURE [dbo].[k_counter_raschet]
(
	  @counter_id1 INT -- код счетчика
	, @tip_value1 SMALLINT = 0 -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
)
AS
	/*
	
    Перерасчет по счетчику
	
    k_counter_raschet @counter_id1=6933,@tip_value1=1,@debug=1

	Изменял  15.12.06 
	Чтобы Тарифы брать с учетом типа жилого фонда по месяцам
	а так же поставщикам и режимам
	
	*/

	SET NOCOUNT ON

	DECLARE @date_first SMALLDATETIME -- дата снятия предпоследнего показания
		  , @value_first INT -- значение предпоследнего показания
		  , @date_last SMALLDATETIME -- дата снятия последнего показания
		  , @value_last INT -- значение последнего показания
		  , @blocked_first BIT = 0
		  , @blocked_last BIT
		  , @err INT
		  , @res INT
		  , @kol_insp INT -- кол-во показаний инспектора
		  , @kod_inspector INT -- код показателя инспектора
		  , @unit_id VARCHAR(10) -- ед.измерения
		  , @service_id VARCHAR(10) -- код услуги
		  , @actual_value1 DECIMAL(15, 6)
		  , @max_value1 INT -- максимальное значение счетчика
		  , @fin_current SMALLINT -- текущий фин. период
		  , @build_id1 INT -- код дома
		  , @internal BIT -- внутренний или внешний счетчик
		  , @checked_fin_id SMALLINT

BEGIN TRY

	SET @err = 0
	SELECT @fin_current = fin_id
	FROM dbo.Global_values 
	WHERE closed = 0

	-- Проверяем есть ли показания инспектора по заданному счетчику
	SELECT @kol_insp = COALESCE(COUNT(id), 0)
	FROM dbo.Counter_inspector 
	WHERE counter_id = @counter_id1

	IF @debug = 1
		SELECT '@kol_insp' = COALESCE(@kol_insp, 0)

	IF @kol_insp = 0
	BEGIN
		DELETE FROM dbo.Counter_paym
		WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1
		RETURN
	END

	-- запоминаем параметры счетчика
	SELECT @date_first = c.date_create
		 , @value_first = c.count_value
		 , @unit_id = c.unit_id
		 , @service_id = c.service_id
		 , @max_value1 = max_value
		 , @build_id1 = build_id
		 , @internal = internal
		 , @checked_fin_id = checked_fin_id
	FROM dbo.Counters AS c 
	WHERE c.id = @counter_id1

	--if @tip_value1=1 and @service_id='элек'  -- 6.05.09
	-- IF @tip_value1 = 1
	-- 	AND @internal = 1 --@service_id='элек'  -- 23.11.2010 
	-- BEGIN
	-- 	--EXEC dbo.k_counter_raschet_people @counter_id1, 1, @debug
	-- 	RETURN
	-- END

	DECLARE @t TABLE (
		  fin_id SMALLINT
		, kod_insp INT
		, inspector_date SMALLDATETIME
		, d1 SMALLDATETIME
		, d2 SMALLDATETIME
		, kol_day SMALLINT
		, value_vday DECIMAL(14, 6)
		, tarif DECIMAL(9, 4)
		, VALUE DECIMAL(14, 6)
		, PRIMARY KEY (fin_id, kod_insp)
	)

	-- Сводные данные по показателю
	DECLARE @t2 TABLE (
		  kod_insp INT PRIMARY KEY
		, kol_day SMALLINT
		, actual_value DECIMAL(14, 6)
		, value_vday DECIMAL(14, 6)
		, tarif DECIMAL(9, 4)
		, value_paym DECIMAL(9, 2) DEFAULT 0
	)

	DECLARE @d1 SMALLDATETIME
		  , @d2 SMALLDATETIME -- временные переменные дат

	DECLARE curs CURSOR LOCAL FOR
		SELECT id
			 , inspector_date
			 , inspector_value
			 , blocked
		FROM dbo.Counter_inspector 
		WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1
			AND fin_id > COALESCE(@checked_fin_id, 0)
		ORDER BY id
	OPEN curs
	FETCH NEXT FROM curs INTO @kod_inspector, @date_last, @value_last, @blocked_last

	WHILE (@@fetch_status = 0)
	BEGIN

		SELECT @d1 = SMALLDATETIMEFROMPARTS(YEAR(@date_first), MONTH(@date_first), 1, 0, 0)
			 , @d2 = SMALLDATETIMEFROMPARTS(YEAR(@date_last), MONTH(@date_last), 1, 0, 0)

		INSERT INTO @t (fin_id
					  , kod_insp
					  , inspector_date
					  , d1
					  , d2
					  , kol_day
					  , value_vday
					  , tarif)
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
		FROM dbo.Global_values 
		WHERE start_date BETWEEN @d1 AND @d2

		--*****************
		SET @date_first = DATEADD(dd, 1, @date_last) -- 16/02/2011
		--SET @date_first=@date_last

		UPDATE @t
		SET d2 = d1
		WHERE d2 < d1

		UPDATE @t
		SET kol_day = DATEDIFF(D, d1, d2) + 1 -- 30/06/2005
		WHERE kod_insp = @kod_inspector

		--print @value_last
		--print @value_first

		IF @value_last >= @value_first
			SET @actual_value1 = @value_last - @value_first
		ELSE
			SET @actual_value1 = @max_value1 + @value_last - @value_first
		--print @actual_value1

		IF @actual_value1 > 10000
			SET @actual_value1 = 0 -- защита от переполнения  21.02.2011

		IF @blocked_first = 1
			SET @actual_value1 = 0

		--set @value_vday1=@actual_value1/@kol_day1

		INSERT INTO @t2 (kod_insp
					   , kol_day
					   , actual_value
					   , value_vday)
		SELECT kod_insp
			 , SUM(kol_day)
			 , @actual_value1
			 , 0
		FROM @t
		WHERE kod_insp = @kod_inspector
		GROUP BY kod_insp

		UPDATE @t2
		SET value_vday = actual_value / kol_day
		--,tarif=dbo.Fun_GetCounterTarf(@fin_current, @counter_id1, @date_last)
		WHERE kod_insp = @kod_inspector

		UPDATE t
		SET value_vday = t2.value_vday
		FROM @t AS t
			JOIN @t2 AS t2 ON t.kod_insp = t2.kod_insp
				AND t.kod_insp = @kod_inspector


		SET @value_first = @value_last
		SET @blocked_first = @blocked_last

		-- читаем следующий показатель
		FETCH NEXT FROM curs INTO @kod_inspector, @date_last, @value_last, @blocked_last
	END

	CLOSE curs
	DEALLOCATE curs

	--update @t set kol_day=datediff(d,d1,d2)+1

	--*********************************************

	UPDATE t
	SET tarif = dbo.Fun_GetCounterTarf(t.fin_id, @counter_id1, NULL) --t.inspector_date)
	FROM @t AS t
	   , dbo.Counters AS c 
	WHERE c.id = @counter_id1


	UPDATE t
	SET VALUE = t.kol_day * t.tarif * t2.value_vday
	FROM @t AS t
		JOIN @t2 AS t2 ON t.kod_insp = t2.kod_insp

	UPDATE @t2
	SET tarif = (
			SELECT AVG(t.tarif)
			FROM @t AS t
			WHERE t.kod_insp = t2.kod_insp
		)
	  , value_paym = (
			SELECT SUM(t.VALUE)
			FROM @t AS t
			WHERE t.kod_insp = t2.kod_insp
		)
	FROM @t2 AS t2

	IF @debug = 1 -- тестируем
	BEGIN
		SELECT *
		FROM @t
		SELECT *
		FROM @t2
	END

	UPDATE ci
	SET kol_day = t2.kol_day
	  , actual_value = t2.actual_value
	  , value_vday = t2.value_vday
	  , tarif = t2.tarif
	  , value_paym = t2.value_paym
	FROM dbo.Counter_inspector AS ci
		JOIN @t2 AS t2 ON ci.id = t2.kod_insp


	DELETE FROM dbo.Counter_paym
	WHERE counter_id = @counter_id1
		AND tip_value = @tip_value1

	INSERT INTO dbo.Counter_paym (fin_id
								, counter_id
								, kod_insp
								, tip_value
								, kol_day
								, value_vday
								, tarif
								, VALUE)
	SELECT fin_id
		 , @counter_id1
		 , kod_insp
		 , @tip_value1
		 , kol_day
		 , value_vday
		 , tarif
		 , VALUE
	FROM @t

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

