CREATE   PROCEDURE [dbo].[k_counter_copy]
(
	@build_id1		INT
   ,@flat_id1		INT
   ,@service_id1	VARCHAR(10)
   ,@serial_number1 VARCHAR(20)
   ,@type1			VARCHAR(30)
   ,@max_value1		INT
   ,@koef1			DECIMAL(9, 4)
   ,@unit_id1		VARCHAR(10)
   ,@count_value1   INT
   ,@date_create1   DATETIME
   ,@PeriodCheck	DATETIME
   ,@comments1		VARCHAR(100) = NULL
   ,@internal		BIT			 = NULL
   ,@counter_id_out	INT	         = NULL OUTPUT -- новый код счетчика
)
AS
	/*
	Копирование счетчика
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1)
		RETURN
	END

	IF LEN(LTRIM(@serial_number1)) = 0
	BEGIN
		RAISERROR ('Заполните серийный номер ПУ', 16, 10)
		RETURN -1
	END

	-- Проверяем есть ли счетчик с таким номером на этой квартире
	IF EXISTS (SELECT
				*
			FROM dbo.COUNTERS AS c 
			WHERE c.serial_number = @serial_number1
			AND c.service_id = @service_id1
			AND c.type = @type1
			AND c.date_del IS NULL -- открыт
			AND c.flat_id = @flat_id1
			AND c.build_id = @build_id1)
	BEGIN
		RAISERROR ('Рабочий счетчик с таким номером уже есть!', 16, 10)
		RETURN -1
	END

	DECLARE @user_id1   SMALLINT
		    ,@date_edit1 SMALLDATETIME

	SELECT
		@date_edit1 = dbo.Fun_GetOnlyDate(current_timestamp)
		,@user_id1 = dbo.Fun_GetCurrentUserId()
		,@date_create1 = dbo.Fun_GetOnlyDate(@date_create1)

	IF @flat_id1 IS NULL
		SET @flat_id1 = 0

	BEGIN TRY

		IF @trancount = 0
			BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_counter_copy;

			INSERT INTO dbo.COUNTERS
			(build_id
			,flat_id
			,service_id
			,serial_number
			,type
			,max_value
			,koef
			,unit_id
			,count_value
			,date_create
			,PeriodCheck
			,user_edit
			,date_edit
			,comments
			,internal)
			VALUES (@build_id1
				   ,@flat_id1
				   ,@service_id1
				   ,@serial_number1
				   ,@type1
				   ,@max_value1
				   ,@koef1
				   ,@unit_id1
				   ,@count_value1
				   ,@date_create1
				   ,@PeriodCheck
				   ,@user_id1
				   ,@date_edit1
				   ,@comments1
				   ,@internal)

			SELECT
				@counter_id_out = SCOPE_IDENTITY()

			-- добавляем лицевые из этой квартиры
			INSERT INTO dbo.Counter_list_all
			(fin_id
			,counter_id
			,occ
			,service_id
			,occ_counter
			,internal)
				SELECT
					O.fin_id
				   ,@counter_id_out
				   ,occ
				   ,@service_id1
				   ,dbo.Fun_GetService_Occ(occ, @service_id1)
				   ,@internal
				FROM dbo.Occupations AS o 	
				WHERE o.flat_id = @flat_id1
				AND o.status_id <> 'закр'

			UPDATE cm
			SET is_counter  =
					CASE
						WHEN @internal = 1 THEN 2
						ELSE 1
					END
			   ,subsid_only =
					CASE
						WHEN @internal = 1 THEN 0 --  убираем признак внешней услуги
						ELSE cm.subsid_only
					END
			FROM dbo.CONSMODES_LIST AS cm
			JOIN dbo.OCCUPATIONS AS o
				ON cm.occ = o.occ
			WHERE o.flat_id = @flat_id1
			AND o.status_id <> 'закр'
			AND cm.service_id = @service_id1

			IF @trancount = 0
			COMMIT TRAN

		-- сохраняем в историю изменений
		DECLARE @str1 VARCHAR(100)
		SET @str1 = 'Добавили:' + @serial_number1 + ' услуга: ' + @service_id1
		IF system_user <> 'sa'
			EXEC k_counter_write_log @counter_id_out
									,'счре'
									,@str1

	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_counter_copy;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0--@debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

