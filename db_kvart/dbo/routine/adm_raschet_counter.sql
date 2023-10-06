CREATE   PROCEDURE [dbo].[adm_raschet_counter]
(
	@internal   BIT		 = NULL -- 0 - внешний счётчик, 1- внутренний
   ,@tip_value  SMALLINT = NULL -- 0 - по показаниям инспектора, 1-квартиросъемщика
   ,@debug		BIT		 = 0
   ,@flat_start INT		 = NULL-- начальный код квартиры для расчёта
   ,@tip_id		SMALLINT = NULL
)
/*

Перерасчет всей базы по текущему финансовому периоду по СЧЕТЧИКАМ

adm_raschet_counter @tip_value=1,@debug=1,@tip_id=28

*/
AS
	SET NOCOUNT ON

	-- 5 сек ждем блокировку  в этой сесии пользователя
	SET LOCK_TIMEOUT 5000

	DECLARE @id1		INT = 0
		   ,@i			INT
		   ,@y			INT
		   ,@er			INT
		   ,@strerror   VARCHAR(4000)
		   ,@start_time1 DATETIME
		   ,@timeOne    DATETIME
		   ,@date_temp2 DATETIME
		   ,@msg		VARCHAR(100)
		   ,@kolVibor   INT
           ,@s VARCHAR(50)

	SET @i = 0
	SET @y = 0

	IF @internal IS NULL
		SET @internal = 1
	IF @flat_start IS NULL
		SET @flat_start = 0

	SELECT DISTINCT
		flat_id
	   ,c.internal
	INTO #t
	FROM dbo.Counters AS c 
	JOIN dbo.Buildings AS b 
		ON c.build_id = b.id
	JOIN dbo.Occupation_Types AS ot 
		ON b.tip_id = ot.id
	WHERE 
		ot.payms_value = CAST(1 AS BIT) -- Выбираем только тех которым мы начисляем
		AND (c.internal = @internal	OR @internal IS NULL) --    -- 21.12.2010
		AND c.flat_id >= @flat_start
		AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
		AND c.date_del IS NULL
		AND c.is_build = CAST(0 AS BIT)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
	ORDER BY flat_id

	SET @start_time1 = current_timestamp
	SET @s = CONVERT(VARCHAR(20), @start_time1, 120)
    RAISERROR (N'Делаем расчет ИПУ по помещениям %s', 10, 1, @s) WITH NOWAIT;
    
	SELECT
		@kolVibor = COUNT(*)
	FROM #t
	SET @msg = N'Отобрано:' + STR(@kolVibor)
	RAISERROR (@msg, 10, 1) WITH NOWAIT;

	--SELECT TOP 1
	--	*
	--FROM #t
	--return
	BEGIN TRY

		DECLARE curs CURSOR LOCAL FOR
			SELECT
				flat_id
			   ,internal
			FROM #t
		OPEN curs
		FETCH NEXT FROM curs INTO @id1, @internal
		WHILE (@@fetch_status = 0)
		BEGIN
			SET @i += 1
			SET @timeOne = current_timestamp

			IF @internal = 0 -- внешние счетчики
			BEGIN
				IF COALESCE(@tip_value, 0) = 0
				BEGIN
					-- Расчитываем по показателям инспектора
					EXEC @er = dbo.k_counter_raschet_flats @id1,0,0
					IF @er <> 0
					BEGIN
						SET @y += 1
						IF @y < 6
						BEGIN
							SET @strerror = N'Ошибка при перерасчете! Код квартиры: ' + STR(@id1)
							EXEC dbo.k_adderrors_card @strerror
						END
					END
				END
				IF COALESCE(@tip_value, 1) = 1
				BEGIN
					-- Расчитываем по показателям квартиросъемщика
					EXEC @er = dbo.k_counter_raschet_flats @id1,1,0
					IF @er <> 0
					BEGIN
						SET @y += 1
						IF @y < 6
						BEGIN
							SET @strerror = N'Ошибка при перерасчете! Код квартиры: ' + STR(@id1)
							EXEC dbo.k_adderrors_card @strerror
						END
					END
				END
			END
			IF @internal = 1 -- Внутренние счетчики
			BEGIN
				IF COALESCE(@tip_value, 0) = 0
				BEGIN
					-- Расчитываем по показателям инспектора
					EXEC @er = dbo.k_counter_raschet_flats2 @id1
														   ,0
														   ,0
					IF @er <> 0
					BEGIN
						SET @y += 1
						IF @y < 6
						BEGIN
							SET @strerror = N'Ошибка при перерасчете! Код квартиры: ' + STR(@id1)
							EXEC dbo.k_adderrors_card @strerror
						END
					END
				END
				IF COALESCE(@tip_value, 1) = 1
				BEGIN
					-- Расчитываем по показателям квартиросъемщика
					EXEC @er = dbo.k_counter_raschet_flats2 @id1
														   ,1
														   ,0
					IF @er <> 0
					BEGIN
						SET @y += 1
						IF @y < 6
						BEGIN
							SET @strerror = N'Ошибка при перерасчете! Код квартиры: ' + STR(@id1)
							EXEC dbo.k_adderrors_card @strerror
						END
					END
				END
			END

			IF @debug = 1
			BEGIN
				SET @msg = Concat(@i, ' flat_id: ', @id1, ' ', 
					DATEDIFF(MILLISECOND, @timeOne, current_timestamp), 'ms ', 
					dbo.Fun_GetTimeStr(@start_time1)
					)
				RAISERROR (@msg, 10, 1) WITH NOWAIT;
			END

			FETCH NEXT FROM curs INTO @id1, @internal

		END
		CLOSE curs
		DEALLOCATE curs


		DECLARE @kolSecond INT
		SELECT
			@kolSecond = DATEDIFF(SECOND, @start_time1, current_timestamp)
		IF @kolSecond>0
		BEGIN
			SET @msg = N'Выполнено за ' + dbo.Fun_GetTimeStr(@start_time1) + CHAR(13)
			IF @kolSecond > @kolVibor
				SET @msg = @msg + N'со скоростью: ' + LTRIM(STR(@kolSecond / @kolVibor)) + N' секунд за лиц/сч.'
			ELSE
				SET @msg = @msg + N'со скоростью: ' + LTRIM(STR(@kolVibor / @kolSecond)) + N' лиц/сч. в сек.'
			RAISERROR (@msg, 10, 1) WITH NOWAIT;
		END

	END TRY

	BEGIN CATCH

		SET @strerror = CONCAT(N'Код квартиры:', STR(@id1), ' Адрес: ', dbo.Fun_GetAdresFlat(@id1) )

		EXECUTE k_GetErrorInfo @visible = @debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

