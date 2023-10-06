CREATE   PROCEDURE [dbo].[k_counter_del]
(
	  @id1 INT -- код счетчика
	, @date_del SMALLDATETIME = NULL -- дата закрытия сетчика
	, @count_del DECIMAL(12, 4) = NULL -- показания счетчика при закрытии
	, @ReasonDel VARCHAR(100) = NULL -- Причина
	, @debug BIT = 0	
)
AS
	/*
		Удаление счетчика (архивация, закрытие)

		k_counter_del 61337
		
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

	DECLARE @occ1 INT
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @service_id1 VARCHAR(10)
		  , @build_id1 INT
		  , @err INT
		  , @serial_number1 VARCHAR(10)
		  , @str1 VARCHAR(100)
		  , @date_create_counter SMALLDATETIME
		  , @fin_current SMALLINT
		  , @start_date SMALLDATETIME
		  , @date_edit1 SMALLDATETIME
		  , @date_del1 SMALLDATETIME
		  , @count_value DECIMAL(14, 6)
		  , @is_build BIT
		  , @strerror VARCHAR(4000) = ''
		  , @is_del_current_fin BIT = 1 -- удалять из текущего периода

	SELECT @service_id1 = C.service_id
		 , @serial_number1 = C.serial_number
		 , @build_id1 = C.build_id
		 , @date_create_counter = C.date_create
		 , @count_value = count_value
		 , @date_del1 = date_del
		 , @is_build = is_build
		 , @start_date = ot.start_date
	FROM dbo.Counters AS C 
		JOIN dbo.Buildings b ON C.build_id = b.id
		JOIN dbo.Occupation_Types ot ON b.tip_id = ot.id
	WHERE C.id = @id1;

	IF @date_del1 IS NOT NULL  -- счётчик уже удалён
		RETURN;

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)
		 , @date_edit1 = dbo.Fun_GetOnlyDate(current_timestamp);

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1);
		RETURN;
	END;

	IF @count_del IS NULL
	BEGIN
		-- находим последнее значение ИПУ
		SELECT TOP (1) @count_del = ci.inspector_value
		FROM dbo.Counter_inspector ci 
		WHERE counter_id = @id1
		ORDER BY ci.inspector_date DESC;

		IF @count_del IS NULL  -- то берём начальное
			SET @count_del = @count_value;
	END;

	IF EXISTS (
			SELECT 1
			FROM dbo.Counter_list_all 
			WHERE counter_id = @id1
				AND fin_id < @fin_current
		)
		AND (@date_del IS NULL)
	BEGIN
		RAISERROR ('Введите дату закрытия!', 16, 1);
		RETURN;
	END;

	IF (@date_del IS NOT NULL)
		AND (@date_create_counter >= @date_del)
		AND (@date_del > current_timestamp)
	BEGIN
		RAISERROR ('Введите правильную дату закрытия!', 16, 1);
		RETURN;
	END;

	-- Кол-во счетчиков по лицевому и услуге
	DECLARE @CountPU_in_occ1 INT;

	BEGIN TRY

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION [k_counter_del];

		-- Если это последний счетчик по услуге
		-- убираем признак отдельной платы за эту услугу			
		DECLARE curs CURSOR LOCAL FOR
			SELECT occ
			FROM dbo.Counter_list_all 
			WHERE counter_id = @id1
				AND fin_id = @fin_current;
		OPEN curs;
		FETCH NEXT FROM curs INTO @occ1;

		WHILE (@@fetch_status = 0)
		BEGIN

			SELECT @CountPU_in_occ1 = COALESCE(COUNT(occ), 0)
			FROM dbo.Counter_list_all 
			WHERE occ = @occ1
				AND service_id = @service_id1
				AND fin_id = @fin_current;

			-- print @Count1

			IF @CountPU_in_occ1 = 1
			BEGIN
				UPDATE cml
				SET is_counter = 0
				FROM dbo.Consmodes_list AS cml
				WHERE is_counter = 1
					AND cml.occ = @occ1
					AND cml.service_id = @service_id1;
			END;

			FETCH NEXT FROM curs INTO @occ1;
		END;

		CLOSE curs;
		DEALLOCATE curs;

		SELECT @is_del_current_fin=is_del_current_fin
		FROM dbo.Reason_close_pu rp
		WHERE rp.[name]=@ReasonDel

		if @is_del_current_fin IS NULL	
			SET @is_del_current_fin=1

		IF (@is_del_current_fin =1) OR (@date_del1<@start_date)	-- dbo.strpos('KOMP', UPPER(@DB_NAME)) > 0
			DELETE cla
			FROM dbo.Counter_list_all AS cla 
			WHERE counter_id = @id1
				AND fin_id = @fin_current
		--	AND @date_del1<@start_date  -- 13/04/2022

		/*

			Если по этому счетчику проходили начисления
			то счетчик просто закрываем Date_Del

			иначе удаляем на совсем
		*/
		DECLARE @is_forever BIT = 0

		IF EXISTS (
				SELECT 1
				FROM dbo.View_counter_all 
				WHERE counter_id = @id1
					AND fin_id < @fin_current
			)
			OR (@is_build = 1 -- это ОПУ					
			AND @date_create_counter < @start_date  -- создали не в текущем периоде
			)
		BEGIN
			IF @debug = 1
				PRINT 'счетчик закрываем'

			EXEC @err = dbo.k_counter_value_add2 @counter_id1 = @id1
											   , @inspector_value1 = @count_del
											   , @inspector_date1 = @date_del
											   , @blocked1 = 1
											   , @comments1 = 'при закрытии ПУ'
			IF @err <> 0
			BEGIN
				RAISERROR ('Ошибка добавления последнего показания счетчика', 16, 1);
				RETURN @err;
			END;

			UPDATE Counters 
			SET date_del = @date_del
			  , CountValue_del = @count_del
			  , date_edit = @date_edit1
			  , ReasonDel = @ReasonDel
			WHERE id = @id1;
		END
		ELSE
		BEGIN
			IF @debug = 1
				PRINT 'удаляем на совсем'

			SET @is_forever=1

			IF EXISTS (
					SELECT 1
					FROM dbo.Counter_inspector 
					WHERE counter_id = @id1
				)
			BEGIN
				ROLLBACK TRAN;
				RAISERROR ('Удалите сначала показания по счётчику!', 16, 1);
				RETURN;
			END;

			DELETE FROM Counter_list_all 
			WHERE counter_id = @id1

			DELETE FROM Counters 
			WHERE id = @id1;

		END

		IF @trancount = 0
			COMMIT TRANSACTION;

		-- сохраняем в историю изменений
		SET @str1 = CONCAT('ПУ № ',@serial_number1,',услуга: ',@service_id1,', ', COALESCE(@ReasonDel, ''))
		EXEC k_counter_write_log @counter_id1 = @id1
							   , @oper1 = 'счуд'
							   , @comments1 = @str1;

		--IF @is_forever=0 AND COALESCE(@auto_add_added, 0) = 1
		--BEGIN
		--	IF @debug = 1
		--		PRINT 'Делаем разовые'
		--END

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
			ROLLBACK TRANSACTION [k_counter_del];

		SET @strerror = @strerror + ' ПУ № ' + @serial_number1 + ',услуга: ' + @service_id1;

		EXECUTE k_GetErrorInfo @visible = 0 --@debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1);

	END CATCH; ;
go

