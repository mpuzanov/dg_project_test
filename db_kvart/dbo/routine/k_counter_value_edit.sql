CREATE   PROCEDURE [dbo].[k_counter_value_edit]
(
	  @id1 INT -- код изменяемого показателя
	, @value_new DECIMAL(14, 6) = NULL -- новое значение показания
	, @inspector_date_new SMALLDATETIME = NULL -- новое значение даты
	, @result BIT = 0 OUTPUT
)
AS
	/*
	
	 Изменение показатния(даты) по счетчику
	 
	*/
	SET XACT_ABORT, NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	IF @value_new IS NULL
		AND @inspector_date_new IS NULL
		RETURN

	DECLARE @tran_count INT = @@trancount;

	DECLARE @Str1 VARCHAR(100)
		  , @user_edit SMALLINT
		  , @date1 SMALLDATETIME
		  , @inspector_date1 SMALLDATETIME
		  , @inspector_date_pred SMALLDATETIME
		  , @value_old DECIMAL(14, 6)
		  , @kol_day SMALLINT
		  , @counter_id1 INT
		  , @value_pred DECIMAL(14, 6)
		  , @count_value1 DECIMAL(14, 6)
		  , @tip_value1 TINYINT
		  , @service_id VARCHAR(10)
		  , @internal BIT
		  , @flat_id1 INT
		  , @build_id1 INT
		  , @strerror VARCHAR(4000) = ''

	SELECT @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
		 , @user_edit = [dbo].[Fun_GetCurrentUserId]()


	SELECT @value_old = inspector_value
		 , @inspector_date1 = inspector_date
		 , @counter_id1 = ci.counter_id
		 , @count_value1 = count_value
		 , @tip_value1 = ci.tip_value
		 , @service_id = service_id
		 , @internal = c.internal
		 , @flat_id1 = c.flat_id
		 , @build_id1 = c.build_id
		 , @kol_day = ci.kol_day
	FROM dbo.Counter_inspector AS ci
		JOIN dbo.Counters AS c ON ci.counter_id = c.id
	WHERE ci.id = @id1

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR (N'Для Вас работа со счетчиками запрещена!', 16, 1)
	END

	SELECT TOP (1) @value_pred = inspector_value
				 , @inspector_date_pred = ci.inspector_date
	FROM dbo.Counter_inspector AS ci 
	WHERE ci.id < @id1
		AND ci.counter_id = @counter_id1
	ORDER BY ci.id DESC

	IF (COALESCE(@inspector_date_pred, @inspector_date1) > @inspector_date_new)
		AND @service_id NOT IN (N'элек')
	BEGIN
		SET @strerror = CONCAT(N'Новая дата показания (',CONVERT(VARCHAR(10), @inspector_date_new, 104),') не должна быть ранее предыдущей (',CONVERT(VARCHAR(10), @inspector_date1, 104),')')
		RAISERROR (@strerror, 16, 1)
	END

	BEGIN TRY
		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION k_counter_value_edit;

		UPDATE ci
		SET inspector_value = COALESCE(@value_new, inspector_value)
		  , inspector_date = COALESCE(@inspector_date_new, inspector_date)
		  , date_edit = @date1
		  , user_edit = @user_edit
		FROM dbo.Counter_inspector AS ci
		WHERE ci.id = @id1
		IF @@rowcount > 0
			SET @result = 1

		IF @tran_count = 0
			COMMIT TRANSACTION;

		IF @result = 1
		BEGIN
			-- Делаем перерасчет по счётчикам
			IF @internal = 0
				EXEC dbo.k_counter_raschet_flats @flat_id1 = @flat_id1
											   , @tip_value1 = @tip_value1
											   , @debug = 0
			ELSE
				EXEC dbo.k_counter_raschet_flats2 @flat_id1 = @flat_id1
												, @tip_value1 = 1
												, @debug = 0

			-- делаем расчёт квартплаты в квартире
			EXEC k_raschet_flat @flat_id = @flat_id1

			-- сохраняем в историю изменений
			SET @Str1 = N'Стар.знач: ' + LTRIM(STR(@value_old)) + N'.Дата показания:' + CONVERT(VARCHAR(10), @inspector_date1, 104)
			EXEC k_counter_write_log @counter_id1 = @counter_id1
								   , @oper1 = N'счре'
								   , @comments1 = @Str1
		END
	END TRY
	BEGIN CATCH
        IF @@trancount > 0 ROLLBACK TRANSACTION

    	SET @strerror = CONCAT(N'Код квартиры: ', @flat_id1,', Адрес: ', dbo.Fun_GetAdresFlat(@flat_id1))

		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1);
        --;THROW

	END CATCH
go

