CREATE   PROCEDURE [dbo].[k_counter_add]
(
	  @build_id1 INT
	, @flat_id1 INT = 0
	, @service_id1 VARCHAR(10)
	, @serial_number1 VARCHAR(20)
	, @type1 VARCHAR(30)
	, @max_value1 INT
	, @koef1 DECIMAL(9, 4)
	, @unit_id1 VARCHAR(10)
	, @count_value1 DECIMAL(12, 4)
	, @date_create1 DATETIME
	, @periodcheck DATETIME = NULL
	, @comments1 VARCHAR(100) = NULL
	, @internal BIT = 1
	, @is_build BIT = NULL
	, @checked_fin_id SMALLINT = NULL
	, @counter_id_out INT = NULL OUTPUT -- новый код счетчика
	, @mode_id INT = 0
	, @auto_add_added BIT = 0 -- автоматически добавлять разовые по недопоставке за прошлые периоды

	, @PeriodLastCheck DATETIME = NULL  -- дата последней поверки
	, @PeriodInterval SMALLINT = NULL  -- межповерочный интервал
	, @is_sensor_temp BIT = NULL  -- наличие датчика температуры
	, @is_sensor_press BIT = NULL  -- наличие датчика давления
	, @is_remot_reading BIT = NULL  -- дистанционный съём показаний
	, @count_tarif SMALLINT = NULL -- кол-во тарифов (вид ПУ по кол-ву тарифов)
	, @value_serv_many_pu BIT = NULL -- объем ресурса определяется с помощью нескольких ПУ
	, @room_id INT = NULL  -- код комнаты
	, @debug BIT = 0
	, @strerror VARCHAR(4000) = '' OUTPUT

)
AS
	/*
	
	Добавление счетчика
	
	DECLARE	@return_value int,
			@counter_id_out int
	
	EXEC	@return_value = [dbo].[k_counter_add]
			@build_id1 = 3716, --770,
			@flat_id1 = 238522, --66248,
			@service_id1 = N'хвод',
			@serial_number1 = N'9',
			@type1 = N'XXX',
			@max_value1=99999,
			@koef1=1,
			@unit_id1='кубм',
			@count_value1 = 0,
			@date_create1 = '20150218',
			@comments1 = N'тест',
			@counter_id_out = @counter_id_out OUTPUT,
			@auto_add_added = 1,

			@debug=1
	
	SELECT	@counter_id_out as N'@counter_id_out'
	
	SELECT	'Return Value' = @return_value
	
	
	
	*/
	SET XACT_ABORT, NOCOUNT ON;

	DECLARE @tran_count INT;
	DECLARE @TransactionName VARCHAR(20) = 'k_counter_add';
	SET @tran_count = @@trancount;

	IF @is_build IS NULL
		SET @is_build = 0

	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR (N'Для Вас работа со счетчиками запрещена!', 16, 1)
	END

	SET @serial_number1 = RTRIM(LTRIM(@serial_number1))
	SET @serial_number1 = REPLACE(@serial_number1, CHAR(9), '')
	SET @serial_number1 = REPLACE(@serial_number1, CHAR(160), '')
	SET @type1 = LTRIM(RTRIM(@type1))

	IF LEN(LTRIM(@serial_number1)) = 0
		OR LEN(@type1) = 0
		OR LEN(LTRIM(@unit_id1)) = 0
	BEGIN
		SET @strerror = N'Заполните поля!'
		RAISERROR (@strerror, 16, 10)
	END

	IF @count_value1 > @max_value1
	BEGIN
		SET @strerror = CONCAT(N'Нач.значение <', STR(@count_value1, 9, 2),'> не должно быть больше максимального ', STR(@max_value1))
		RAISERROR (@strerror, 16, 10)
	END

	IF @is_build = 0
		AND @service_id1 NOT IN ('хвод', 'гвод', 'пгаз', 'элек', 'отоп')
	BEGIN
		SET @strerror = CONCAT(N'ПУ с услугой <', @service_id1,'> не может быть!')
		RAISERROR (@strerror, 16, 10)
	END
	IF @is_build = 1
		AND @service_id1 NOT IN ('хвод', 'гвод', 'пгаз', 'элек', 'отоп', 'хвс2', 'тепл',
		'газОтоп', 'гГВС')  -- 'газОтоп', 'гГВС' добавил 11.10.2021
	BEGIN
		SET @strerror = CONCAT(N'ПУ с услугой <', @service_id1,'> не может быть!')
		RAISERROR (@strerror, 16, 10)
	END

	IF EXISTS (
			SELECT 1
			FROM [dbo].[Counters] AS t 
			WHERE t.flat_id = @flat_id1
				AND t.serial_number = @serial_number1
				AND t.date_del IS NULL
				AND t.is_build = 0
		)
	BEGIN
		SET @strerror = CONCAT(N'ПУ с серийных номером ', @serial_number1,' уже есть в помещении!')
		RAISERROR (@strerror, 16, 10)
	END

	IF @is_build = 0
		AND @is_sensor_press = 1
		SET @is_sensor_press = 0  -- датчик давления может быть только у ОПУ

	--IF EXISTS (SELECT
	--			1
	--		FROM dbo.SERVICES s
	--		WHERE s.id=@service_id1
	--		AND s.service_type=1)
	--BEGIN
	--	RAISERROR ('У жилищной услуги %s не может быть ПУ!', 16, 10, @service_id1)
	--	RETURN -1
	--END

	-- Проверяем есть ли счетчик с таким номером на этом лицевом
	IF EXISTS (
			SELECT 1
			FROM dbo.Counters AS c
			WHERE c.serial_number = @serial_number1
				AND c.service_id = @service_id1
				AND c.type = @type1
				AND c.date_del IS NULL -- открыт
				AND c.build_id = @build_id1
		)
	BEGIN
		RAISERROR (N'Рабочий счетчик с № %s уже есть!', 16, 10, @serial_number1)
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.Counters AS c
			WHERE c.serial_number = @serial_number1
				AND ((c.flat_id = @flat_id1) OR (c.is_build = 1))
				AND (c.service_id <> @service_id1)	-- может быть закрытый с другой услугой
				AND c.build_id = @build_id1
		)
	BEGIN
		SET @strerror = CONCAT(N'ПУ с номером ', @serial_number1,' уже есть на другой услуге!')
		RAISERROR (@strerror, 16, 10)
	END

	IF (@PeriodLastCheck > current_timestamp)
	BEGIN
		SET @strerror = CONCAT(N'Последний период поверки ПУ(', CONVERT(VARCHAR(10), @PeriodLastCheck, 104),') не должен превышать текущую дату!')
		RAISERROR (@strerror, 16, 10)
	END
	IF (@periodcheck IS NULL
		AND @PeriodLastCheck IS NOT NULL
		AND @PeriodInterval > 0)
		SET @periodcheck = DATEADD(YEAR, @PeriodInterval, @PeriodLastCheck)

	IF COALESCE(@internal, 0) = 0
		SET @internal = 1

	IF @mode_id IS NULL
		SET @mode_id = 0

	-- Проверяем есть ли режим потребления и поставщик по этой услуге
	IF @is_build IS NULL
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Consmodes_list cl 
			WHERE EXISTS (
					SELECT 1
					FROM dbo.Occupations AS o 
						JOIN dbo.Flats AS f ON o.flat_id = f.id
					WHERE o.occ = cl.occ
						AND f.id = CASE
                                       WHEN @flat_id1 = 0 THEN f.id
                                       ELSE @flat_id1
                        END
						AND f.bldn_id = @build_id1
						AND o.status_id <> 'закр'
				)
				AND service_id = @service_id1
				AND ((mode_id % 1000 <> 0) OR (source_id % 1000 <> 0))
		)
	BEGIN
		SET @strerror = N'Нет режима потребления или поставщика в помещении!'
		RAISERROR (@strerror, 16, 10)
	END


	DECLARE @user_id1 SMALLINT
		  , @date_edit1 SMALLDATETIME
		  , @fin_current SMALLINT
		  , @fin_id1 SMALLINT
		  , @doc_no1 VARCHAR(10) = '889'
		  , @occ1 INT

	SELECT @date_edit1 = CAST(current_timestamp AS DATE)
		 , @user_id1 = dbo.Fun_GetCurrentUserId()
		 , @date_create1 = CAST(@date_create1 AS DATE)

	IF @flat_id1 IS NULL
		SET @flat_id1 = 0

	SELECT @fin_current = b.fin_current
	FROM dbo.Buildings AS b 
	WHERE b.id = @build_id1

	BEGIN TRY

		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @TransactionName;

		INSERT INTO dbo.Counters (build_id
								, flat_id
								, service_id
								, serial_number
								, type
								, max_value
								, Koef
								, unit_id
								, count_value
								, date_create
								, PeriodCheck
								, user_edit
								, date_edit
								, comments
								, internal
								, is_build
								, checked_fin_id
								, mode_id
								, is_sensor_temp
								, is_sensor_press
								, PeriodLastCheck
								, PeriodInterval
								, is_remot_reading
								, room_id
								, count_tarif
								, value_serv_many_pu)
		VALUES(@build_id1
			 , @flat_id1
			 , @service_id1
			 , LTRIM(@serial_number1)
			 , @type1
			 , @max_value1
			 , @koef1
			 , @unit_id1
			 , @count_value1
			 , @date_create1
			 , @periodcheck
			 , @user_id1
			 , @date_edit1
			 , @comments1
			 , @internal
			 , COALESCE(@is_build, 0)
			 , @checked_fin_id
			 , @mode_id
			 , @is_sensor_temp
			 , @is_sensor_press
			 , @PeriodLastCheck
			 , @PeriodInterval
			 , @is_remot_reading
			 , @room_id
			 , COALESCE(@count_tarif, 1)
			 , COALESCE(@value_serv_many_pu, 0))

		SELECT @counter_id_out = SCOPE_IDENTITY()

		-- добавляем лицевые из этой квартиры
		INSERT INTO dbo.Counter_list_all (counter_id
										, occ
										, service_id
										, occ_counter
										, internal
										, fin_id)
		SELECT @counter_id_out
			 , occ
			 , @service_id1
			 , dbo.Fun_GetService_Occ(occ, @service_id1)
			 , @internal
			 , O.fin_id
		FROM dbo.Occupations AS o 
		WHERE o.flat_id = @flat_id1
			AND o.status_id <> 'закр'
			AND o.total_sq > 0


		UPDATE cm
		SET is_counter =
            CASE
                WHEN @internal = 1 THEN 2
                ELSE 1
                END
		  , subsid_only = CASE
                              WHEN @internal = 1 THEN 0
                              ELSE cm.subsid_only
            END --  убираем признак внешней услуги
		  , @occ1 = o.occ
		FROM dbo.Consmodes_list AS cm
			JOIN dbo.Occupations AS o ON o.occ = cm.occ
		WHERE o.flat_id = @flat_id1
			AND o.status_id <> 'закр'
			AND cm.service_id = @service_id1

		IF @tran_count = 0
			COMMIT TRAN

		-- Добавляем тип(марку) ПУ в справочник
		IF NOT EXISTS (
				SELECT *
				FROM dbo.Counter_type
				WHERE name = @type1
			)
			INSERT INTO dbo.Counter_type (name)
			VALUES(@type1)

		-- если есть разовые по автовозврату @doc_no = 888 то разовые не делаем
		IF EXISTS (
				SELECT 1
				FROM dbo.Added_Payments ap 
					JOIN dbo.Occupations o ON ap.occ = o.occ
						AND ap.fin_id = o.fin_id
				WHERE o.flat_id = @flat_id1
					AND ap.add_type = 12
					AND ap.doc_no = '888'
					AND ap.service_id = @service_id1  -- 25/09/2022
			)
			SET @auto_add_added = 0


		IF COALESCE(@auto_add_added, 0) = 1
		BEGIN
			/*
		      	Если ПУ создается в уже закрытом периоде
		      	то надо сделать возврат за эти дни(начисленные по норме)

				Если ПУ создается в текущем периоде 
				то надо сделать добор по норме(по среднему) от начала месяца до дня установки ПУ
		      	*/

			DECLARE @addyes BIT				  
				  , @start_date SMALLDATETIME
				  , @end_date SMALLDATETIME
				  , @run_add BIT = 0
				  , @run_add2 BIT = 0
				  , @doc_name NVARCHAR(100) = N'Акт по ИПУ'
				  , @znak1 BIT = 0
				  , @tarif DECIMAL(10, 4) = 0
				  , @is_replace_counter BIT = 0
				  , @avg_vday DECIMAL(12, 6) = 0
				  , @kol_day INT = 0
				  , @kol DECIMAL(12, 6) = 0
				  , @value DECIMAL(9, 2) = 0

			SELECT TOP (1) @is_replace_counter = 1
						 , @avg_vday = cla.avg_vday
			FROM dbo.Counter_list_all cla
			WHERE cla.occ = @occ1
				AND cla.service_id = @service_id1
				AND cla.fin_id = (@fin_current - 1)

			IF @debug = 1
				SELECT @counter_id_out AS counter_id_out
					 , @occ1 AS occ1
					 , @fin_current AS fin_current
					 , @service_id1 AS service_id1
					 , @is_replace_counter AS is_replace_counter
					 , @avg_vday AS avg_vday

			DECLARE cur CURSOR LOCAL FOR
				SELECT o.occ
					 , gv.fin_id
					 , gv.[start_date]
					 , gv.end_date
				FROM dbo.View_occ_all_lite AS o 
					JOIN dbo.Global_values AS gv ON 
						o.fin_id = gv.fin_id
					JOIN dbo.Counters AS c ON 
						o.flat_id = c.flat_id
				WHERE c.id = @counter_id_out
					AND (
					(gv.fin_id < @fin_current AND @date_create1 < gv.end_date) OR (gv.fin_id = @fin_current AND @date_create1 BETWEEN gv.[start_date] AND gv.end_date)
					)
				ORDER BY gv.fin_id

			OPEN cur

			FETCH NEXT FROM cur INTO @occ1, @fin_id1, @start_date, @end_date

			WHILE @@fetch_status = 0
			BEGIN
				IF (@date_create1 BETWEEN @start_date AND @end_date)
					AND (@fin_id1 = @fin_current)
					SELECT @end_date = @date_create1 - 1  -- текущий период
						 , @znak1 = 1
						 , @kol_day = DATEDIFF(DAY, @start_date, @end_date) + 1
				ELSE
				IF (@date_create1 > @start_date)
					AND (@fin_id1 <> @fin_current)
					SELECT @start_date = @date_create1
						 , @znak1 = 0

				SET @run_add = 0

				IF (@service_id1 = N'хвод')
					SELECT TOP 1 @service_id1 = vp.service_id
					FROM dbo.View_paym AS vp 
					WHERE vp.service_id IN (N'хвод', N'хвс2')
						AND vp.fin_id = @fin_id1
						AND vp.occ = @occ1
						AND COALESCE(vp.metod_old, COALESCE(vp.metod, 1)) NOT IN (3)
					ORDER BY vp.value DESC

				IF (@service_id1 = N'гвод')
					SELECT TOP 1 @service_id1 = vp.service_id
					FROM dbo.View_paym AS vp 
					WHERE vp.service_id IN (N'гвод', N'гвс2')
						AND vp.fin_id = @fin_id1
						AND vp.occ = @occ1
						AND COALESCE(vp.metod_old, COALESCE(vp.metod, 1)) NOT IN (3)
					ORDER BY vp.value DESC

				IF EXISTS (
						SELECT 1
						FROM dbo.View_paym AS vp
						WHERE vp.service_id = @service_id1
							AND vp.fin_id = @fin_id1
							AND vp.occ = @occ1
							AND COALESCE(vp.metod_old, COALESCE(vp.metod, 1)) NOT IN (3)
					)
					SET @run_add = 1

				IF @debug = 1
					PRINT @service_id1 + ' ' + STR(@fin_id1) + ' ' + CONVERT(VARCHAR(10), @start_date, 104) + ' ' + CONVERT(VARCHAR(10), @end_date, 104)

				IF EXISTS (
						SELECT 1
						FROM dbo.Added_Payments AS ap 
						WHERE occ = @occ1
							AND ap.fin_id = @fin_current
							AND ap.service_id = @service_id1
							AND ap.add_type = 12
							AND ap.doc_no = @doc_no1
							AND ap.doc = @doc_name
							AND ap.data1 = @start_date
					)
					SET @run_add = 0

				IF EXISTS (
						SELECT 1
						FROM dbo.Added_Payments AS ap 
						WHERE occ = @occ1
							AND ap.fin_id = @fin_current
							AND ap.service_id IN ('хвпк', 'гвпк', 'вопк', 'хпк2', 'тепл', 'элек', 'гГВС')
							AND ap.add_type = 12
							AND ap.doc_no = @doc_no1
							AND ap.doc = @doc_name
							AND ap.data1 = @start_date
					)
					SET @run_add2 = 0
				ELSE
					SET @run_add2 = 1


				IF @debug = 1
					PRINT N'Добавляем разовые -' + STR(@run_add) + ' ' + @service_id1

				DECLARE @serv_tmp VARCHAR(10)
					  , @sup_id INT = 0

				SELECT TOP 1 @sup_id = sup_id
				FROM dbo.View_paym AS vp 
				WHERE vp.service_id = @service_id1
					AND vp.fin_id = @fin_id1
					AND vp.occ = @occ1
					AND vp.value > 0

				IF @run_add = 1
					EXEC dbo.ka_add_added_2 @occ1 = @occ1
										  , @service_id1 = @service_id1
										  , @add_type1 = 12
										  , @doc1 = @doc_name
										  , @doc_no1 = @doc_no1
										  , @fin_id1 = @fin_id1
										  , @data1 = @start_date
										  , @data2 = @end_date
										  , @group1 = 1
										  , @znak1 = @znak1
										  , @tarif_minus1 = 0
										  , @doc_date1 = NULL
										  , @vin1 = NULL
										  , @vin2 = NULL
										  , @mode_history = 1
										  , @hours1 = 0
										  , @manual_sum = 0
										  , @addyes = @addyes OUTPUT
										  , @add_votv_auto = 1
										  , @debug = @debug
										  , @sup_id = @sup_id

				IF @debug = 1
					PRINT @service_id1 + ' результат= ' + CAST(@addyes AS VARCHAR(3))
				--=================================================================	
				-- Проверяем есть ли услуги с повышающим коэф.
				SELECT @serv_tmp = NULL

				SELECT @serv_tmp = vp.service_id
					 , @sup_id = sup_id
				FROM dbo.View_paym AS vp
				WHERE vp.service_id IN ('хвпк', 'хпк2')
					AND vp.fin_id = @fin_id1
					AND vp.occ = @occ1
					AND vp.value > 0
					AND @run_add2 = 1

				IF @serv_tmp IS NOT NULL
					EXEC dbo.ka_add_added_2 @occ1 = @occ1
										  , @service_id1 = @serv_tmp --'хвпк'
										  , @add_type1 = 12
										  , @doc1 = @doc_name
										  , @doc_no1 = @doc_no1
										  , @fin_id1 = @fin_id1
										  , @data1 = @start_date
										  , @data2 = @end_date
										  , @group1 = 1
										  , @znak1 = @znak1
										  , @tarif_minus1 = 0
										  , @doc_date1 = NULL
										  , @vin1 = NULL
										  , @vin2 = NULL
										  , @mode_history = 1
										  , @hours1 = 0
										  , @manual_sum = 0
										  , @addyes = @addyes OUTPUT
										  , @add_votv_auto = 0
										  , @debug = @debug
										  , @sup_id = @sup_id
				IF @debug = 1
					PRINT COALESCE(@serv_tmp, N'хвпк и хпк2') + ' ' + CAST(@addyes AS VARCHAR(3))
				--=================================================================	
				IF EXISTS (
						SELECT vp.service_id
						FROM dbo.View_paym AS vp 
						WHERE vp.service_id IN (N'гвпк')
							AND vp.fin_id = @fin_id1
							AND vp.occ = @occ1
							AND vp.value > 0
					)
					AND @run_add2 = 1
					EXEC dbo.ka_add_added_2 @occ1 = @occ1
										  , @service_id1 = 'гвпк'
										  , @add_type1 = 12
										  , @doc1 = @doc_name
										  , @doc_no1 = @doc_no1
										  , @fin_id1 = @fin_id1
										  , @data1 = @start_date
										  , @data2 = @end_date
										  , @group1 = 1
										  , @znak1 = @znak1
										  , @tarif_minus1 = 0
										  , @doc_date1 = NULL
										  , @vin1 = NULL
										  , @vin2 = NULL
										  , @mode_history = 1
										  , @hours1 = 0
										  , @manual_sum = 0
										  , @addyes = @addyes OUTPUT
										  , @add_votv_auto = 0
										  , @debug = 0
										  , @sup_id = @sup_id
				IF @debug = 1
					PRINT N'гвпк ' + CAST(@addyes AS VARCHAR(3))
				--=================================================================	
				IF EXISTS (
						SELECT vp.service_id
						FROM dbo.View_paym AS vp 
						WHERE vp.service_id IN (N'вопк')
							AND vp.fin_id = @fin_id1
							AND vp.occ = @occ1
							AND vp.value > 0
					)
					AND @run_add2 = 1
					EXEC dbo.ka_add_added_2 @occ1 = @occ1
										  , @service_id1 = 'вопк'
										  , @add_type1 = 12
										  , @doc1 = @doc_name
										  , @doc_no1 = @doc_no1
										  , @fin_id1 = @fin_id1
										  , @data1 = @start_date
										  , @data2 = @end_date
										  , @group1 = 1
										  , @znak1 = @znak1
										  , @tarif_minus1 = 0
										  , @doc_date1 = NULL
										  , @vin1 = NULL
										  , @vin2 = NULL
										  , @mode_history = 1
										  , @hours1 = 0
										  , @manual_sum = 0
										  , @addyes = @addyes OUTPUT
										  , @add_votv_auto = 0
										  , @debug = 0
										  , @sup_id = @sup_id
				IF @debug = 1
					PRINT N'вопк ' + CAST(@addyes AS VARCHAR(3))
				--=================================================================	
				IF (@service_id1 = N'гвод') --добавляли ПУ по ГВС
				BEGIN
					IF EXISTS (
							SELECT vp.service_id
							FROM dbo.View_paym AS vp
							WHERE vp.service_id IN (N'тепл')
								AND vp.fin_id = @fin_id1
								AND vp.occ = @occ1
								AND vp.value > 0
						)
						AND @run_add2 = 1
						EXEC dbo.ka_add_added_2 @occ1 = @occ1
											  , @service_id1 = N'тепл'
											  , @add_type1 = 12
											  , @doc1 = @doc_name
											  , @doc_no1 = @doc_no1
											  , @fin_id1 = @fin_id1
											  , @data1 = @start_date
											  , @data2 = @end_date
											  , @group1 = 1
											  , @znak1 = @znak1
											  , @tarif_minus1 = 0
											  , @doc_date1 = NULL
											  , @vin1 = NULL
											  , @vin2 = NULL
											  , @mode_history = 1
											  , @hours1 = 0
											  , @manual_sum = 0
											  , @addyes = @addyes OUTPUT
											  , @add_votv_auto = 0
											  , @debug = 0
											  , @sup_id = @sup_id
					IF @debug = 1
						PRINT N'тепл ' + CAST(@addyes AS VARCHAR(3))
					--===== гГВС
					IF EXISTS (
							SELECT vp.service_id
							FROM dbo.View_paym AS vp
							WHERE vp.service_id IN ('гГВС')
								AND vp.fin_id = @fin_id1
								AND vp.occ = @occ1
								AND vp.value > 0
						)
						AND @run_add2 = 1
						EXEC dbo.ka_add_added_2 @occ1 = @occ1
											  , @service_id1 = 'гГВС'
											  , @add_type1 = 12
											  , @doc1 = @doc_name
											  , @doc_no1 = @doc_no1
											  , @fin_id1 = @fin_id1
											  , @data1 = @start_date
											  , @data2 = @end_date
											  , @group1 = 1
											  , @znak1 = @znak1
											  , @tarif_minus1 = 0
											  , @doc_date1 = NULL
											  , @vin1 = NULL
											  , @vin2 = NULL
											  , @mode_history = 1
											  , @hours1 = 0
											  , @manual_sum = 0
											  , @addyes = @addyes OUTPUT
											  , @add_votv_auto = 0
											  , @debug = 0
											  , @sup_id = @sup_id
					IF @debug = 1
						PRINT N'гГВС ' + CAST(@addyes AS VARCHAR(3))
					--=================================================	
				END
				--=================================================================
				IF (@service_id1 = N'элек') --добавляли ПУ по элек
				BEGIN
					IF (@fin_id1 = @fin_current)
						AND @is_replace_counter = 1
					BEGIN
						-- начислим по среднему
						SELECT @kol_day = DATEDIFF(DAY, @start_date, @end_date) + 1, @kol = 0, @value = 0
						SELECT @kol = COALESCE(@kol_day, 0) * COALESCE(@avg_vday, 0)

						IF @kol > 0
						BEGIN
							SELECT TOP (1) @tarif = vp.tarif
							FROM dbo.View_paym AS vp 
							WHERE vp.service_id = @service_id1
								AND vp.fin_id = @fin_id1
								AND vp.occ = @occ1

							SELECT @value = @kol * @tarif
						END

						IF @debug = 1
							SELECT @service_id1
								 , @kol_day AS kol_day
								 , @avg_vday AS avg_vday
								 , @kol AS kol
								 , @value AS value
						IF @value <> 0
						BEGIN
							-- Добавляем разовый
							INSERT INTO Added_Payments (occ
													  , service_id
													  , sup_id
													  , add_type
													  , value
													  , doc
													  , doc_no
													  , data1
													  , data2
													  , comments
													  , kol
													  , fin_id)
							VALUES(@occ1
								 , @service_id1
								 , @sup_id
								 , 12
								 , @value
								 , @doc_name
								 , @doc_no1
								 , @start_date
								 , @end_date
								 , ''
								 , @kol
								 , @fin_id1)
						END

					END
					ELSE
					IF EXISTS (
							SELECT vp.service_id
							FROM dbo.View_paym AS vp 
							WHERE vp.service_id IN (N'элек')
								AND vp.fin_id = @fin_id1
								AND vp.occ = @occ1
								AND vp.value > 0
						)
						AND @run_add2 = 1
						EXEC dbo.ka_add_added_2 @occ1 = @occ1
											  , @service_id1 = N'элек'
											  , @add_type1 = 12
											  , @doc1 = @doc_name
											  , @doc_no1 = @doc_no1
											  , @fin_id1 = @fin_id1
											  , @data1 = @start_date
											  , @data2 = @end_date
											  , @group1 = 1
											  , @znak1 = @znak1
											  , @tarif_minus1 = 0
											  , @doc_date1 = NULL
											  , @vin1 = NULL
											  , @vin2 = NULL
											  , @mode_history = 1
											  , @hours1 = 0
											  , @manual_sum = 0
											  , @addyes = @addyes OUTPUT
											  , @add_votv_auto = 0
											  , @debug = 0
											  , @sup_id = @sup_id
					IF @debug = 1
						PRINT N'элек ' + CAST(@addyes AS VARCHAR(3))
				END

				FETCH NEXT FROM cur INTO @occ1, @fin_id1, @start_date, @end_date

			END

			CLOSE cur
			DEALLOCATE cur

		END

		-- сохраняем в историю изменений
		DECLARE @str1 VARCHAR(100)
		SET @str1 = 'Добавили:' + @serial_number1 + ' услуга: ' + @service_id1
		EXEC k_counter_write_log @counter_id1=@counter_id_out
							   , @oper1=N'счре'
							   , @comments1=@str1

	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @TransactionName

		SET @strerror = N'Счетчик:' + @serial_number1 + N',услуга: ' + @service_id1;
		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

