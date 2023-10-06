CREATE   PROCEDURE [dbo].[k_counter_edit]
(
	  @id1 INT
	, @serial_number1 VARCHAR(20)
	, @type1 VARCHAR(30)
	, @max_value1 INT
	, @koef1 DECIMAL(9, 4)
	, @unit_id1 VARCHAR(10)
	, @count_value1 DECIMAL(13, 5)
	, @date_create1 DATETIME
	, @periodcheck DATETIME = NULL -- Плановый период поверки
	, @comments1 VARCHAR(100) = NULL
	, @internal BIT = 1
	, @is_build BIT = NULL
	, @checked_fin_id SMALLINT = NULL
	, @mode_id INT = 0
	, @flat_new INT = NULL
	, @id_pu_gis VARCHAR(15) = NULL -- код в ГИС ЖКХ

	, @PeriodLastCheck DATETIME = NULL -- дата последней поверки
	, @PeriodInterval SMALLINT = NULL -- межповерочный интервал
	, @is_sensor_temp BIT = NULL -- наличие датчика температуры
	, @is_sensor_press BIT = NULL -- наличие датчика давления
	, @is_remot_reading BIT = NULL -- дистанционный съём показаний 
	, @count_tarif SMALLINT = NULL -- кол-во тарифов (вид ПУ по кол-ву тарифов)
	, @value_serv_many_pu BIT = NULL -- объем ресурса определяется с помощью нескольких ПУ
	, @room_id INT = NULL -- код комнаты
	, @blocker_read_value BIT = NULL -- блокировать ввод показаний
	, @strerror VARCHAR(4000) = '' OUTPUT
)
AS
	/*
		Изменение начальных параметров счетчика
	*/

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1);
		RETURN;
	END;

	IF LEN(LTRIM(@serial_number1)) = 0
		OR LEN(LTRIM(@type1)) = 0
		OR LEN(LTRIM(@unit_id1)) = 0
	BEGIN
		RAISERROR ('Заполните поля!', 16, 10);
		RETURN -1;
	END;

	SET @serial_number1 = RTRIM(LTRIM(@serial_number1))
	SET @serial_number1 = REPLACE(@serial_number1, CHAR(9), '')
	SET @serial_number1 = REPLACE(@serial_number1, CHAR(160), '')

	IF COALESCE(@internal, 0) = 0
		SET @internal = 1;

	DECLARE @build_id1 INT
		  , @flat_id1 INT
		  , @service_id1 VARCHAR(10)
		  , @SerNumOld VARCHAR(20)
		  , @count_valueOld DECIMAL(13, 5)
		  , @date_createOld DATETIME
		  , @unit_idOld VARCHAR(10)


	SELECT @build_id1 = build_id
		 , @flat_id1 = flat_id
		 , @service_id1 = service_id
		 , @SerNumOld = serial_number
		 , @is_build =
					  CASE
						  WHEN @is_build IS NULL THEN is_build
						  ELSE @is_build
					  END
		 , @count_valueOld = count_value
		 , @date_createOld = date_create
		 , @unit_idOld = unit_id
	FROM dbo.Counters 
	WHERE id = @id1;

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1);
		RETURN;
	END;

	-- если общедомовой счётчик
	IF @is_build = 1
		OR @flat_new IS NULL
		SET @flat_new = @flat_id1;

	IF @is_build = 0
		AND @is_sensor_press = 1
		SET @is_sensor_press = 0  -- датчик давления может быть только у ОПУ


	IF @mode_id IS NULL
		SET @mode_id = 0;

	IF EXISTS (
			SELECT 1
			FROM dbo.Counters
			WHERE id = @id1
				AND date_del IS NOT NULL
				AND system_user <> 'sa'
		) -- только sa можно менять закрытые ПУ
	BEGIN
		RAISERROR ('Прибор учета уже закрыт!', 16, 1);
		RETURN -1;
	END;

	-- Проверяем есть ли другой счетчик с таким же номером на этом лицевом
	IF EXISTS (
			SELECT 1
			FROM dbo.Counters AS c 
			WHERE c.serial_number = @serial_number1
				AND c.id <> @id1
				AND ((c.flat_id = @flat_id1) OR (c.is_build = 1))
				AND c.date_del IS NULL
				AND c.service_id = @service_id1
				AND c.build_id = @build_id1
		)
	BEGIN
		RAISERROR ('Рабочий прибор учета с номером %s уже есть!', 16, 10, @serial_number1)
		RETURN -1
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.Counters AS c
			WHERE c.serial_number = @serial_number1
				AND c.id <> @id1
				AND ((c.flat_id = @flat_id1) OR (c.is_build = 1))
				AND (c.service_id <> @service_id1)	-- может быть закрытый с другой услугой
				AND c.build_id = @build_id1
		)
	BEGIN
		RAISERROR ('Прибор учета с номером <%s> уже есть на другой услуге!', 16, 10, @serial_number1)
		RETURN -1
	END


	IF EXISTS (
			SELECT 1
			FROM dbo.Counter_inspector
			WHERE counter_id = @id1
				AND @date_create1 > inspector_date
		)
	BEGIN
		SET @strerror = 'Есть показания ранее даты приемки счетчика'
		RAISERROR (@strerror, 16, 10);
		RETURN -1;
	END;

	IF @count_value1 > @max_value1
	BEGIN
		SET @strerror = CONCAT('Нач.значение <', STR(@count_value1, 9, 2),'> не должно быть больше максимального <', STR(@max_value1),'>!')
		RAISERROR (@strerror, 16, 10);
		RETURN -1;
	END;

	DECLARE @user_id1 SMALLINT
		  , @date_current SMALLDATETIME;

	SELECT @date_current = dbo.Fun_GetOnlyDate(current_timestamp)
		 , @user_id1 = [dbo].[Fun_GetCurrentUserId]()
		 , @date_create1 = dbo.Fun_GetOnlyDate(@date_create1)

	IF @date_create1 > @date_current
	BEGIN
		SET @strerror = CONCAT('Дата приемки счетчика(', CONVERT(VARCHAR(10), @date_create1, 104),') больше текущей даты')
		RAISERROR (@strerror, 16, 10);
		RETURN -1;
	END;

	IF (@PeriodLastCheck IS NOT NULL
		AND @PeriodLastCheck > @date_current)
	BEGIN
		SET @strerror = CONCAT('Последний период поверки ПУ(', CONVERT(VARCHAR(10), @PeriodLastCheck, 104),') не должен превышать текущую дату')		
		RAISERROR (@strerror, 16, 10)
		RETURN -1
	END

	IF (@periodcheck IS NULL
		AND @PeriodLastCheck IS NOT NULL
		AND @PeriodInterval > 0)
		SET @periodcheck = DATEADD(YEAR, @PeriodInterval, @PeriodLastCheck)

	IF @PeriodInterval IS NULL
		AND @periodcheck IS NOT NULL
		AND @PeriodLastCheck IS NOT NULL
		SET @PeriodInterval = DATEDIFF(YEAR, @PeriodLastCheck, @periodcheck)

	BEGIN TRY

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION [k_counter_edit];

		UPDATE dbo.Counters 
		SET serial_number = @serial_number1
		  , [type] = @type1
		  , max_value = @max_value1
		  , Koef = @koef1
		  , unit_id = @unit_id1
		  , count_value = @count_value1
		  , date_create = @date_create1
		  , PeriodCheck = @periodcheck
		  , user_edit = @user_id1
		  , date_edit = @date_current
		  , comments = @comments1
		  , internal = @internal
		  , is_build = @is_build
		  , checked_fin_id = @checked_fin_id
		  , mode_id = @mode_id
		  , flat_id = @flat_new
		  , id_pu_gis = COALESCE(@id_pu_gis, id_pu_gis)
		  , is_sensor_temp = @is_sensor_temp
		  , is_sensor_press = @is_sensor_press
		  , PeriodLastCheck = @PeriodLastCheck
		  , PeriodInterval = @PeriodInterval
		  , is_remot_reading = @is_remot_reading
		  , count_tarif = COALESCE(@count_tarif,1)
		  , value_serv_many_pu = COALESCE(@value_serv_many_pu, 0)
		  , room_id = @room_id
		  , blocker_read_value = @blocker_read_value
		WHERE id = @id1;

		UPDATE cl 
		SET internal = @internal
		FROM dbo.Counter_list_all AS cl
		WHERE counter_id = @id1;

		UPDATE cm 
		SET is_counter =
						CASE
							WHEN @internal = 1 THEN 2
							ELSE 1
						END
		FROM dbo.Consmodes_list AS cm
			JOIN dbo.Occupations AS o ON cm.Occ = o.Occ
		WHERE o.flat_id = @flat_id1
			AND o.status_id <> 'закр'
			AND cm.service_id = @service_id1;

		IF @trancount = 0
			COMMIT TRAN

		-- Добавляем тип(марку) ПУ в справочник
		IF NOT EXISTS (
				SELECT *
				FROM dbo.Counter_type
				WHERE name = @type1
			)
			INSERT INTO dbo.Counter_type
				(name)
				VALUES (@type1)

		-- сохраняем в историю изменений
		DECLARE @comments_log VARCHAR(100) = ''
		IF @SerNumOld <> @serial_number1
			SET @comments_log = @comments_log + ';№ ' + @SerNumOld + '->' + @serial_number1
		IF @count_valueOld <> @count_value1
			SET @comments_log = @comments_log + ';нач.знач.:' + LTRIM(STR(@count_valueOld, 9, 2)) + '->' + LTRIM(STR(@count_value1, 9, 2))
		IF @date_createOld <> @date_create1
			SET @comments_log = @comments_log + ';дата приёмки:' + CONVERT(VARCHAR(10), @date_createOld, 104) + '->' + CONVERT(VARCHAR(10), @date_create1, 104)
		IF @unit_idOld <> @unit_id1
			SET @comments_log = @comments_log + ';ед.изм:' + @unit_idOld + '->' + @unit_id1
		SET @comments_log = STUFF(@comments_log, 1, 1, '') -- убираем первый символ

		EXEC k_counter_write_log @counter_id1 = @id1
							   , @oper1 = 'счре'
							   , @comments1 = @comments_log

	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION [k_counter_edit];

		SET @strerror = CONCAT('ПУ №: ', @serial_number1,' услуга: ', @service_id1);
		EXECUTE k_GetErrorInfo @visible = 0--@debug
							 , @strerror = @strerror OUT;

		RAISERROR (@strerror, 16, 1);

	END CATCH;
go

