CREATE   PROCEDURE [dbo].[k_counter_value_add2]
(
	  @counter_id1 INT
	, @inspector_value1 DECIMAL(14, 6)
	, @inspector_date1 SMALLDATETIME = NULL
	, @blocked1 BIT = 0
	, @tip_value1 SMALLINT = 1 -- тип показателя (0-инспектор, 1 - квартиросъемщика)
	, @comments1 VARCHAR(100) = NULL
	, @mode_id1 INT = 0 -- режим
	, @result_add BIT = 0 OUTPUT
	, @group_add BIT = 0 -- групповая загрузка показаний
	, @id_new INT = 0 OUTPUT -- код добавленного показателя
	, @debug BIT = 0
	, @strerror VARCHAR(4000) = '' OUTPUT
	, @fin_id1 SMALLINT = NULL -- установка показания в заданный период
	, @is_test BIT = 0 -- прогон без сохранения показаний в БД
	, @is_blocked_ppu_periodcheck BIT = 0 -- блокировать ввод показаний у истекших ипу
	, @count_month_passed_blocked SMALLINT = NULL -- блокировать ввод показаний если не передавали показания больше месяцев
	, @is_raschet_counter BIT = 1 -- расчет по ПУ
	, @is_raschet_kvart BIT = 1 -- расчёт квартплаты	
)
AS
/*
Ввод показаний (инспектора или квартиросъемщика)
используется в модуле: Счётчики

DECLARE @result_add	BIT, @id_new INT, @strerror VARCHAR(4000)
EXEC k_counter_value_add2 @counter_id1=51469,@inspector_value1=232,@inspector_date1='20170118',
	@tip_value1=1,@debug=1,@result_add=@result_add OUT,@id_new=@id_new OUT, @strerror = @strerror OUT
SELECT @result_add as result_add, @id_new as id_new, @strerror as strerror

*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF @debug = 1
		PRINT 'k_counter_value_add2'

	SELECT @count_month_passed_blocked=COALESCE(@count_month_passed_blocked, 999)  -- если будет 0 то если есть показания не заводить
		,@is_test=COALESCE(@is_test, 0)
		,@group_add=COALESCE(@group_add, 0)
		,@result_add=COALESCE(@result_add, 0)
		,@strerror=COALESCE(@strerror, '')
		,@is_raschet_counter=COALESCE(@is_raschet_counter, 1)

	IF @inspector_date1 IS NULL
		SET @inspector_date1 = dbo.Fun_GetOnlyDate(current_timestamp)	

	DECLARE @build_id1 INT -- код дома
		  , @tip_id1 INT 
		  , @date_create1 SMALLDATETIME -- дата принятия счетчика
		  , @date_Del1 SMALLDATETIME -- дата закрытия счетчика
		  , @count_value_start1 DECIMAL(14, 6) -- показания счетчика при приема
		  , @date_last1 SMALLDATETIME -- дата снятия последнего показания
		  , @value_last1 DECIMAL(14, 6) -- значение последнего показания
		  , @value_dif DECIMAL(14, 6) -- разница между показания
		  , @max_value1 INT -- максимальное значение счетчика
		  , @max_value_vday DECIMAL(14, 6)
		  , @max_value_month DECIMAL(14, 6)
		  , @err INT
		  , @res INT
	      , @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @PeriodCheck SMALLDATETIME
		  , @fin_current SMALLINT -- текущий фин.период
		  , @fin_last SMALLINT -- фин.период последнего показания
		  , @internal BIT
		  , @counter_block_value BIT
		  , @service_id VARCHAR(10)
		  , @flat_id1 INT
		  , @mode_counter INT = NULL
		  , @tip_name VARCHAR(50) = ''
		  , @metod_input SMALLINT = 1 -- 1-ручной, 2-из файла, 3 -мобильный
		  
		  , @DateCounterValue1 SMALLDATETIME -- разрешается ввод показаний гражданами в заданном диопазоне (для моб.приложения было)
		  , @DateCounterValue2 SMALLDATETIME

		  , @kol_day SMALLINT
		  , @value_vday DECIMAL(14, 8)		  	  
		  , @ProgramInput VARCHAR(30) = dbo.fn_app_name()
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @ras_no_counter_poverka BIT
		  , @blocker_read_value BIT

	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		SET @strerror = N'База закрыта для редактирования!'
		RAISERROR (@strerror, 16, 1);
	END;

	BEGIN TRY

		SELECT @build_id1 = c.build_id
			 , @date_create1 = c.date_create
			 , @date_Del1 = c.date_del
			 , @count_value_start1 = c.count_value
			 , @max_value1 = c.max_value
			 , @internal = c.internal
			 , @service_id = c.service_id
			 , @flat_id1 = flat_id
			 , @mode_counter = mode_id
			 , @tip_name = ot.name
			 , @tip_id1 = b.tip_id
			 , @PeriodCheck = c.PeriodCheck
			 , @ras_no_counter_poverka = ot.ras_no_counter_poverka
			 , @is_blocked_ppu_periodcheck =
               CASE
                   WHEN COALESCE(@is_blocked_ppu_periodcheck, 0) = 0 THEN COALESCE(st.is_blocked_ppu_periodcheck, 0)
                   ELSE @is_blocked_ppu_periodcheck
                   END
			 , @blocker_read_value = COALESCE(c.blocker_read_value,0)
		FROM dbo.Counters AS c 
			JOIN dbo.Buildings AS b ON 
				c.build_id = b.id
			JOIN dbo.Occupation_Types AS ot ON 
				b.tip_id=ot.id
			LEFT JOIN dbo.Services_type_counters st ON 
				b.tip_id=st.tip_id
		WHERE c.id = @counter_id1;

		IF @build_id1 IS NULL
		BEGIN
			SET @strerror = CONCAT('ПУ с кодом ', @counter_id1,' не найден в базе ', @Db_Name)
			RAISERROR (@strerror, 16, 1);
		END

		-- берём режим из счётчика по умолчанию
		IF @group_add = 1
			AND @mode_id1 IS NULL
			SET @mode_id1 = @mode_counter;

		IF @mode_id1 IS NULL
			SET @mode_id1 = 0;

		IF @mode_counter <> 0
			AND @mode_id1 = 0
			SET @mode_id1 = @mode_counter

		IF COALESCE(@fin_id1, 0) = 0
			SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)
		ELSE
			SET @fin_current = @fin_id1

		SELECT @start_date = gv.start_date
		     , @end_date = gv.end_date
			 , @counter_block_value = gv.counter_block_value
			 
			 , @DateCounterValue1 =
			    CONVERT(SMALLDATETIME, STR(DATEPART(M, gv.start_date)) + '/' + STR(gv.CounterValue1) + ' /' + STR(DATEPART(yy, gv.start_date)), 101)
			 
			 , @DateCounterValue2 =
			    CONVERT(SMALLDATETIME, STR(DATEPART(M, gv.start_date)) + '/' + STR(
			    CASE -- если CounterValue2>Последнего дня месяца  (февраль например)
				   WHEN gv.CounterValue2 > DAY(dbo.fn_end_month(gv.end_date)) THEN DAY(dbo.fn_end_month(gv.end_date))
				   ELSE gv.CounterValue2
			    END
			   ) + ' /' + STR(DATEPART(yy, gv.start_date)), 101)
		FROM dbo.Global_values as gv 
		WHERE fin_id = @fin_current;

		IF @blocker_read_value = 1
		BEGIN
			SET @strerror = N'У ПУ установлена блокировка приёма показаний'
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END

		IF @counter_block_value = 1
		BEGIN
			SET @strerror = N'Ввод показаний по счетчикам запрещён!'
			RAISERROR (@strerror, 16, 1);
		END;

		IF @blocked1 IS NULL
			SET @blocked1 = 0;
		IF @tip_value1 = 1
			SET @blocked1 = 0;

		IF SUSER_NAME() <> 'muser'
			IF dbo.Fun_AccessCounterLic(@build_id1) = 0
			BEGIN
				SET @strerror = CONCAT(N'Для Вас ', system_user,' работа со ПУ в доме (код: ', @build_id1,') запрещена!')

				IF @group_add = 0
					RAISERROR (@strerror, 16, 1);
				RETURN -1;
			END;

		IF @date_Del1 IS NOT NULL
		BEGIN
			SET @strerror = N'Счетчик закрыт! Изменять нельзя!'
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END;

		SELECT @max_value_vday = max_value_vday
			 , @max_value_month = max_value_month
		FROM Fun_GetCounterServValueInDay()
		WHERE service_id = @service_id;

		if @ras_no_counter_poverka = 1 -- если в УК не считаем по истекшим ПУ
			AND @is_blocked_ppu_periodcheck = 1
			AND	@PeriodCheck IS NOT NULL 
			AND @PeriodCheck<CURRENT_TIMESTAMP
		BEGIN
			SET @strerror = CONCAT(N'Истекла дата поверки ПУ ', CONVERT(VARCHAR(10), @PeriodCheck, 104) )
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);
			RETURN -1;
		END

		-- Находим последнее показание счетчика
		SELECT TOP (1) @date_last1 = inspector_date
					 , @value_last1 = inspector_value
					 , @fin_last = fin_id
		FROM dbo.Counter_inspector
		WHERE counter_id = @counter_id1
			--AND tip_value = @tip_value1  25.10.2021
			--AND mode_id = @mode_id1
		ORDER BY inspector_date DESC
			   , id DESC;

		IF @date_last1 IS NULL
			SET @date_last1 = @date_create1;

		IF @value_last1 IS NULL
			SET @value_last1 = @count_value_start1;

		IF @inspector_value1 < @count_value_start1    --AND @Db_Name NOT LIKE '%KOMP%' -- в компе по 2 кругу уже подают показания
			AND @value_last1 = @count_value_start1
			AND (@group_add = 1)
		BEGIN
			IF @service_id in ('гвод','хвод') 
				AND @inspector_value1=0  -- передано 0
				AND @value_last1 BETWEEN 0 AND 1  -- а последнее менее 1
			BEGIN
				SET @inspector_value1=@value_last1
				GOTO CONTINUE_WORKING
			END
			
			SET @strerror = CONCAT(N'Текущее показание (', dbo.FSTR(@inspector_value1, 14, 6),') не может быть меньше начального (', dbo.NSTR(@count_value_start1),')')
			
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END;

CONTINUE_WORKING:

		IF @inspector_value1 > @max_value1
		BEGIN
			SET @strerror = CONCAT(N'Текущее показание (',dbo.FSTR(@inspector_value1, 14, 6),') не может быть больше максимального (', dbo.NSTR(@max_value1),')' )			
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END;

		IF @inspector_date1 <= @date_create1
		BEGIN
			SET @strerror = CONCAT(N'Дата показания (',CONVERT(VARCHAR(10), @inspector_date1, 104),') должна быть позднее даты приемки ПУ (',CONVERT(VARCHAR(10), @date_create1, 104),')')
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);
			RETURN -1;
		END

		DECLARE @count_month_passed SMALLINT -- кол-во месяцев прошло от предыдущего показания
		SELECT @count_month_passed = COALESCE(DATEDIFF(MONTH, @date_last1, @inspector_date1), 0)
		IF @count_month_passed_blocked<@count_month_passed
		BEGIN
			SET @strerror = CONCAT(N'От предыдущего показания(',CONVERT(VARCHAR(10), @date_last1, 104),') прошло более ', @count_month_passed_blocked,' месяцев') 
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END

		IF (@date_last1 > @inspector_date1)
		  AND (@tip_value1 = 1) -- проверяем только показания квартиросъемщика
		BEGIN
			SET @strerror = CONCAT(N'Дата показания (',CONVERT(VARCHAR(10), @inspector_date1, 104),') должна быть позднее последнего снятого показания (',CONVERT(VARCHAR(10), @date_last1, 104),')')
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1);

			RETURN -1;
		END
		ELSE
		IF @date_last1 = @inspector_date1
			AND @value_last1 = @inspector_value1 --23.01.2021
			AND @fin_current = @fin_last  -- закоментировал строку 23.01.2021   раскоментировал 13.04.2021

			IF @group_add = 0
				DELETE dbo.Counter_inspector
				WHERE counter_id = @counter_id1
					AND fin_id = @fin_last
					AND inspector_date = @inspector_date1
					AND tip_value = @tip_value1
			ELSE
			BEGIN
				SET @strerror = N'Показание уже введено'
				RETURN 0;
			END

		IF (@value_last1 > @inspector_value1)
			AND (@group_add = 1)
		BEGIN
			IF @service_id in ('гвод','хвод') 
				AND @inspector_value1=0  -- передано 0
				AND @value_last1 BETWEEN 0 AND 1  -- а последнее менее 1
			BEGIN
				SET @inspector_value1=@value_last1
				GOTO CONTINUE_WORKING_2
			END

			-- RAISERROR('Предыдущее значение не должно быть больше текущего',16,1)
			-- сохраняем в историю но не заводим
			SET @strerror = CONCAT(N'от: ', CONVERT(VARCHAR(10), @inspector_date1, 104)
				,' знач: ',dbo.NSTR(@inspector_value1)
				,' при загрузке меньше предыдущего ', dbo.NSTR(COALESCE(@value_last1, @count_value_start1)))						
			IF @debug = 1
				PRINT @strerror
			EXEC k_counter_write_log @counter_id1 = @counter_id1
								   , @oper1 = N'счуп'
								   , @comments1 = @strerror


			RETURN -1;
		END;

CONTINUE_WORKING_2:

		SET @value_dif = @inspector_value1 - @value_last1
		SET @kol_day = DATEDIFF(D, @date_last1, @inspector_date1) + 1
		IF @kol_day > 0
			AND @value_dif > 0
			SET @value_vday = @value_dif / @kol_day

		IF @value_vday > @max_value_vday
			AND (@group_add = 1)
		BEGIN
			-- сохраняем в историю но не заводим
			SET @strerror = CONCAT(N'от: ', CONVERT(VARCHAR(10), @inspector_date1, 104)
				,' знач: ', dbo.NSTR(@inspector_value1)
				,' при загрузке (знач в день ', dbo.NSTR(@value_vday)
				,' больше макс.в день ', dbo.NSTR(@max_value_vday),')')
			IF @debug = 1
				PRINT @strerror

			IF @is_test = 0
				EXEC k_counter_write_log @counter_id1 = @counter_id1
									   , @oper1 = N'счуп'
									   , @comments1 = @strerror

			RETURN -1;
		END

		IF (@group_add = 1)
			AND (@value_dif > @max_value_month)
		BEGIN	-- Предупреждение
			SET @strerror = CONCAT(N'от: ', CONVERT(VARCHAR(10), @inspector_date1, 104)
				,' знач: ', dbo.NSTR(@inspector_value1)
				,' при загрузке (знач за месяц ', dbo.NSTR(@value_dif)
				,' больше макс.',dbo.NSTR(@max_value_month),')')
			IF @debug = 1
				PRINT @strerror

			IF @is_test = 0
				EXEC k_counter_write_log @counter_id1 = @counter_id1
									   , @oper1 = N'счуп'
									   , @comments1 = @strerror

			RETURN -1;
		END

		IF @end_date < @inspector_date1
		BEGIN
			SET @strerror = CONCAT(N'В базе период ', CONVERT(VARCHAR(7), @inspector_date1, 126),' еще не наступил!') -- 'yyyy-mm'
			IF @group_add = 0
				RAISERROR (@strerror, 16, 1)
			ELSE
				PRINT @strerror;

			RETURN -1;
		END;

		IF @group_add = 1
			AND EXISTS (
				SELECT 1
				FROM dbo.Counters AS t 
				WHERE t.date_del IS NULL
					AND t.is_build = 0
					AND flat_id = @flat_id1
				GROUP BY t.serial_number
				HAVING COUNT(t.id) > 1
			)
		BEGIN
			SET @strerror = N'обнаружено несколько одинаковых серийных номеров в помещении'
			PRINT @strerror
			RETURN -1;
		END;

		DECLARE @user_id1 SMALLINT
			  , @date_edit1 SMALLDATETIME;

		SET @date_edit1 = CAST(current_timestamp AS DATE);
		SELECT @user_id1 = dbo.Fun_GetCurrentUserId();

		IF @group_add = 1
			SET @metod_input = 2
		IF dbo.strpos('mobile', COALESCE(@comments1, '')) > 0
			SET @metod_input = 3

		-- разрешается ввод показаний гражданами в заданном диопазоне
		IF @metod_input = 3
			AND NOT (@inspector_date1 BETWEEN @DateCounterValue1 AND @DateCounterValue2)
		BEGIN
			SET @strerror = N'запрет ввода показаний гражданами в заданном диопазоне'
			IF @debug = 1
				PRINT @strerror
			RETURN -1;
		END

		IF @comments1 = ''
			SET @comments1 = NULL;

		---- если уже есть показания за этот день по счётчику не меняем
		--IF @group_add = 1 AND EXISTS (SELECT *
		--							  FROM dbo.COUNTER_INSPECTOR
		--							  WHERE counter_id = @counter_id1
		--								  AND inspector_date = @inspector_date1
		--								  AND tip_value = @tip_value1)
		--	GOTO QuitRollBack

		IF @is_test = 1
		BEGIN
			SET @result_add = 1
			RETURN
		END

		-- у показания инспектора меняем фин период
		if (@tip_value1=0) and not (@inspector_date1 between @start_date and @end_date)
		begin -- меняем фин период
            select @fin_current=fin_id
            from dbo.Global_values 
			where @inspector_date1 between start_date and end_date;
        end

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION k_counter_value_add2;

		-- Вводим новые показания
		INSERT INTO dbo.Counter_inspector
			(counter_id
		   , tip_value
		   , inspector_value
		   , inspector_date
		   , blocked
		   , user_edit
		   , date_edit
		   , kol_day
		   , actual_value
		   , value_vday
		   , comments
		   , fin_id
		   , mode_id
		   , metod_input
		   , ProgramInput)
			VALUES (@counter_id1
				  , @tip_value1
				  , @inspector_value1
				  , @inspector_date1
				  , @blocked1
				  , @user_id1
				  , @date_edit1
				  
				  -- 13/04/2022
				  , @kol_day
				  , @value_dif
				  , COALESCE(@value_vday,0)

				  , @comments1
				  , @fin_current
				  , @mode_id1
				  , @metod_input
				  , @ProgramInput);

		SELECT @id_new = SCOPE_IDENTITY() -- код нового показателя

		SET @result_add = 1;

		IF @trancount = 0
			COMMIT TRANSACTION;

		IF @ProgramInput IN (N'Показания.exe', 'VvodPPU.exe', 'Apache HTTP Server')
			OR SYSTEM_USER = 'muser'
			OR @metod_input = 3  -- мобильный ввод
			SELECT @is_raschet_kvart = 0
				 , @is_raschet_counter = 1

		-- Помечаем подозрительные показания
		IF @result_add = 1
			EXEC dbo.k_counter_inspector_alert @fin_id = @fin_id1
											 , @counter_id = @counter_id1

		-- Делаем перерасчет по счётчикам
		IF @is_raschet_counter = 1
			IF @internal = 0
			BEGIN
				EXEC @res = dbo.k_counter_raschet_flats @flat_id1 = @flat_id1
													  , @tip_value1 = @tip_value1
													  , @debug = 0;
				--EXEC @res = dbo.k_counter_raschet @counter_id1 = @counter_id1, @tip_value1 = @tip_value1

				IF @res <> 0
				BEGIN
					IF @group_add = 0
						RAISERROR (N'Ошибка добавления показания счетчика(расчет)!', 16, 1);
				END;

			END
			ELSE
			BEGIN
				EXEC @res = dbo.k_counter_raschet_flats2 @flat_id1 = @flat_id1
													   , @tip_value1 = @tip_value1
													   , @debug = 0;
				--EXEC @res = dbo.k_counter_raschet_id @counter_id1 = @counter_id1, @tip_value1 = @tip_value1

				IF @res <> 0
				BEGIN
					IF @group_add = 0
						RAISERROR (N'Ошибка добавления показания счетчика(расчет)!', 16, 1);
				END;

			END;

		-- если ручной ввод делаем расчёт квартплаты в помещении
		IF (@is_raschet_kvart = 1) and (@is_raschet_counter=1)
			IF @metod_input = 1
				OR DAY(current_timestamp) > 26
				EXEC k_raschet_flat @flat_id1;

	END TRY

	BEGIN CATCH

		DECLARE @message VARCHAR(4000)
			  , @xstate INT;
		SELECT @message = ERROR_MESSAGE()
			 , @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_counter_value_add2;

		IF @flat_id1 IS NOT NULL
			SET @strerror = CONCAT(CHAR(13), N'Код квартиры: ', @flat_id1,', Адрес: ',dbo.Fun_GetAdresFlat(@flat_id1),' (',@tip_name,')')
		ELSE
			SET @strerror = CONCAT(N'Код ПУ: ', @counter_id1)

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT
		IF @debug = 1
			PRINT @strerror

		RAISERROR (@strerror, 16, 1);

	END CATCH;
go

