CREATE   PROCEDURE [dbo].[k_counter_value_add3]
(
	@counter_id1				INT
   ,@inspector_value1			DECIMAL(14, 6) = 0
   ,@inspector_date1			SMALLDATETIME	 = NULL -- если нет ставим последний день месяца
   ,@actual_value				DECIMAL(14, 6) = 0
   ,@blocked1					BIT			 = 0
   ,@comments1					VARCHAR(100)	 = NULL
   ,@volume_arenda				DECIMAL(14, 6) = NULL
   ,@result_add					BIT			 = 1 OUTPUT
   ,@is_info					BIT			 = 0
   ,@strerror					VARCHAR(4000) = '' OUTPUT
   ,@volume_odn					DECIMAL(14, 6) = NULL
   ,@norma_odn					DECIMAL(12,6)  = NULL
   ,@volume_direct_contract		DECIMAL(14, 6) = NULL
   ,@inspector_value_prev		DECIMAL(14, 6) = NULL  -- предыдущее значение
   ,@group_add					BIT = 0 -- групповая загрузка показаний
   ,@is_calculate_actual_value  BIT  = 1
   ,@fin_id1					SMALLINT = NULL -- установка показания в заданный период
)
AS
/*

Ввод показаний по общедомовым счётчикам
используется в модуле: СЧЁТЧИКИ


k_counter_value_add3 @counter_id1,@inspector_value1,@inspector_date1,@actual_value,@blocked1,@comments1

*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		SET @strerror = 'База закрыта для редактирования!'
		RAISERROR (@strerror, 16, 1);
		RETURN
	END

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	SELECT @is_calculate_actual_value=COALESCE(@is_calculate_actual_value,1)

	BEGIN TRY

		IF @blocked1 IS NULL
			SET @blocked1 = 0

		IF @inspector_value1 IS NULL
			SET @inspector_value1 = 0

		IF @actual_value IS NULL
			SET @actual_value = 0

		IF @is_info IS NULL
			SET @is_info = 0

		IF @group_add IS NULL
			SET @group_add = 0


		DECLARE @tip_value1			 TINYINT	 = 2 -- тип показателя (0-инспектор, 1 - квартиросъемщик, 2- общедомовой)
			   ,@mode_id1			 INT		 = 0 -- режим
			   ,@build_id1			 INT -- код дома
			   ,@date_create1		 SMALLDATETIME -- дата принятия счетчика
			   ,@date_Del1			 SMALLDATETIME -- дата закрытия счетчика
			   ,@count_value1		 INT -- показания счетчика при приеме
			   ,@date_last1			 SMALLDATETIME -- дата снятия последнего показания
			   ,@value_last1		 DECIMAL(14, 6) -- значение последнего показания
			   ,@value_dif			 DECIMAL(14, 6) -- разница между показания
			   ,@max_value1			 INT -- максимальное значение счетчика
			   ,@err				 INT
			   ,@res				 INT
			   ,@end_date			 SMALLDATETIME
			   ,@fin_current		 SMALLINT -- текущий фин.период
			   ,@fin_last			 SMALLINT -- фин.период последнего показания
			   ,@internal			 BIT
			   ,@counter_block_value BIT
			   ,@service_id			 VARCHAR(10)
			   ,@is_build			 BIT
			   ,@msg				 VARCHAR(200)
			   ,@arenda_sq_build	 DECIMAL(10, 4) = 0
			   ,@tip_name			 VARCHAR(50) = ''
			   ,@koef				 DECIMAL(9,4) = 1
			   ,@kol_day			 SMALLINT = 0
			   ,@value_vday			 DECIMAL(14, 8)
			   ,@serial_number		 VARCHAR(20) = ''

		SELECT
			@build_id1 = c.build_id
		   ,@date_create1 = c.date_create
		   ,@date_Del1 = c.date_del
		   ,@count_value1 = c.count_value
		   ,@max_value1 = c.max_value
		   ,@internal = c.internal
		   ,@service_id = c.service_id
		   ,@is_build = c.is_build
		   ,@tip_name = b.tip_name
		   ,@arenda_sq_build = COALESCE(b.arenda_sq, 0)
		   ,@mode_id1 = c.mode_id
		   ,@koef = c.koef
		   ,@fin_current = b.fin_current
		   ,@serial_number=c.serial_number
		FROM dbo.Counters AS c 
			JOIN dbo.View_buildings AS b 
				ON c.build_id = b.id
		WHERE 
			c.id = @counter_id1;

		IF COALESCE(@fin_id1, 0)>0
			SET @fin_current = @fin_id1

		SELECT
			@end_date = end_date
		   ,@counter_block_value = counter_block_value
		FROM dbo.GLOBAL_VALUES 
		WHERE fin_id = @fin_current

		IF @mode_id1 IS NULL
			SET @mode_id1 = 0
			
		IF @inspector_date1 IS NULL
			SET @inspector_date1 = dbo.Fun_GetOnlyDate(@end_date)

		IF @counter_block_value = 1
		BEGIN
			SET @strerror = 'Ввод показаний по счетчикам запрещён!'
			RAISERROR (@strerror, 16, 1);
			RETURN -1
		END

		--IF @volume_arenda > 0  -- 15.12.22 закомментировал или надо ещё проверять по типу лицевых  IN (N'комм', N'об06', N'об10', N'отдк') OR o.proptype_id = N'арен'
		--	AND @arenda_sq_build = 0
		--BEGIN
		--	SET @strerror = 'Площадь нежилых помещений по дому не заведена! Объём завести не могу.'
		--	RAISERROR (@strerror, 16, 1)
		--	RETURN -1
		--END

		IF @tip_value1 = 1
			SET @blocked1 = 0

		IF dbo.Fun_AccessCounterLic(@build_id1) = 0
		BEGIN
			SET @strerror = 'Для Вас работа со счетчиками запрещена!'
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		IF @date_Del1 IS NOT NULL
		BEGIN
			SET @strerror = 'ПУ <'+@serial_number+'> закрыт! Изменять нельзя!' 
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		IF @is_build = 0
		BEGIN
			SET @strerror = 'ПУ <'+@serial_number+'> не домовой!'
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		IF @inspector_value1 > @max_value1
		BEGIN
			SET @strerror = 'Текущее показание ' + STR(@inspector_value1, 12, 4) + ' не может быть больше максимального ' + STR(@max_value1) + ' !'
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		IF @inspector_date1 <= @date_create1
		BEGIN
			SET @strerror = CONCAT('Дата показания (', CONVERT(VARCHAR(10), @inspector_date1, 104),') должна быть позднее даты приемки ПУ (', CONVERT(VARCHAR(10), @date_create1, 104),')')				
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		-- удаляем показание за текущий день(если есть) 
		DELETE dbo.COUNTER_INSPECTOR
		WHERE counter_id = @counter_id1
			AND tip_value = @tip_value1
			AND mode_id = COALESCE(@mode_id1, 0)
			AND inspector_date = @inspector_date1

		-- Находим последнее показание счетчика
		SELECT TOP (1)
			@date_last1 = inspector_date
		   ,@value_last1 = inspector_value
		   ,@fin_last = fin_id
		FROM dbo.Counter_inspector 
		WHERE counter_id = @counter_id1
			--AND tip_value = @tip_value1  25.10.2021
			AND mode_id = COALESCE(@mode_id1, 0)
			AND inspector_date < @inspector_date1
		ORDER BY inspector_date DESC

		IF @date_last1 IS NULL
			SET @date_last1 = @date_create1

		IF @value_last1 IS NULL
			SET @value_last1 = @count_value1

		IF @date_last1 > @inspector_date1
		BEGIN
			SET @strerror = CONCAT('Дата показания (',CONVERT(VARCHAR(10), @inspector_date1, 104),') должна быть позднее последнего снятого показания (',CONVERT(VARCHAR(10), @date_last1, 104),')')				
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END
		ELSE

		IF @date_last1 = @inspector_date1
			AND @fin_last = @fin_current
			DELETE dbo.COUNTER_INSPECTOR
			WHERE counter_id = @counter_id1
				AND inspector_date = @inspector_date1
				AND tip_value = @tip_value1


		IF @end_date < @inspector_date1
		BEGIN
			SET @strerror = 'В БД этот период еще не наступил!'
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

		IF @actual_value = 0 --@value_last1 <> 0   -- Объем может не совпадать с @inspector_value1 - @value_last1
			AND @inspector_value1 <> 0
			AND @is_calculate_actual_value=1   --@group_add=0
		BEGIN
			--IF COALESCE(@inspector_value_prev,0)>0
			--	SET @value_last1=@inspector_value_prev

			IF @value_last1 > @inspector_value1
				SET @actual_value = @max_value1 - @value_last1 + @inspector_value1
			ELSE
				SET @actual_value = @inspector_value1 - @value_last1
			
			IF @koef>1
				SET @actual_value = @actual_value * @koef
		END

		SELECT @value_dif = @inspector_value1 - @value_last1
			  ,@kol_day = DATEDIFF(DAY, @date_last1, @inspector_date1) + 1

		IF @kol_day > 0
			AND @value_dif > 0
			SET @value_vday = @value_dif / @kol_day

		DECLARE @user_id1   SMALLINT
			   ,@date_edit1 SMALLDATETIME = dbo.Fun_GetOnlyDate(current_timestamp)

		SELECT @user_id1 = dbo.Fun_GetCurrentUserId()

		IF @comments1 = ''
			SET @comments1 = NULL

		IF @trancount = 0
			BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_counter_value_add3;

			-- Вводим новые показания
			INSERT INTO dbo.Counter_inspector
			(counter_id
			,tip_value
			,inspector_value
			,inspector_date
			,blocked
			,user_edit
			,date_edit
			,kol_day
			,actual_value
			,value_vday
			,comments
			,fin_id
			,mode_id
			,volume_arenda
			,is_info
			,volume_odn
			,norma_odn
			,volume_direct_contract)
			VALUES (@counter_id1
				   ,@tip_value1
				   ,@inspector_value1
				   ,@inspector_date1
				   ,@blocked1
				   ,@user_id1
				   ,@date_edit1
				   ,COALESCE(@kol_day,0)
				   ,@actual_value
				   ,COALESCE(@value_vday,0)
				   ,@comments1
				   ,@fin_current
				   ,@mode_id1
				   ,@volume_arenda
				   ,COALESCE(@is_info, 0)
				   ,@volume_odn
				   ,@norma_odn
				   ,@volume_direct_contract)

			SELECT
				@err = @@error

			IF @err <> 0
			BEGIN
				SET @result_add = 0
				SET @strerror = 'Ошибка добавления показания ПУ!' 
				RAISERROR (@strerror, 16, 1)
				RETURN -1
			END
			ELSE
				SET @result_add = 1

			IF @trancount = 0
			COMMIT TRANSACTION;


	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_counter_value_add3;

		SET @strerror = CONCAT('Код дома: ', @build_id1,', Адрес: ', dbo.Fun_GetAdres(@build_id1, NULL, NULL),' (', @tip_name,')')

		EXECUTE k_GetErrorInfo @visible = 0--@debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

