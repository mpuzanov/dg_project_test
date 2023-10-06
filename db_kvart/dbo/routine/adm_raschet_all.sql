CREATE   PROCEDURE [dbo].[adm_raschet_all]
(
	  @debug BIT = 0
	, @occ_start INT = NULL -- начальный лицевой для расчёта
	, @tip_id SMALLINT = NULL
	, @kol_occ INT = NULL -- Кол-во лицевых для тестирования
	, @is_paym BIT = NULL -- 1 - отбор только кому начисляем, 0 - кому не начисляем , null - всех
)
/*
Перерасчет всей базы по текущему финансовому периоду

exec adm_raschet_all @debug=0
exec adm_raschet_all @debug=1,@kol_occ=100, @is_paym=1
exec adm_raschet_all @debug=0, @tip_id=1, @kol_occ=1000, @is_paym=1
*/
AS
	SET NOCOUNT ON

	PRINT N'Счётчик транзакций: ' + STR(@@trancount)
	IF @@trancount > 0
		ROLLBACK TRAN

	--SET DEADLOCK_PRIORITY 10;
	-- 5 сек ждем блокировку  в этой сесии пользователя
	--SET LOCK_TIMEOUT 5000

	DECLARE @occ1 INT = 0
		  , @fin_id1 SMALLINT
		  , @tip_id1 SMALLINT
		  , @tip_id_prev SMALLINT = NULL
		  , @payms_value1 BIT
		  , @is_paym_build1 BIT
		  , @i INT = 0
		  , @y INT = 0
		  , @er INT
		  , @strerror VARCHAR(800)
		  , @date_temp DATETIME
		  , @kol_time INT = 0


	DECLARE @start_time1 DATETIME = current_timestamp
		  , @time_tip DATETIME = current_timestamp
		  , @msg NVARCHAR(400)
		  , @kolVibor INT = 0
		  , @kol_tip INT = 0 -- кол-во лицевых по типу фонда

	IF @occ_start IS NULL
		SET @occ_start = 0

	IF @kol_occ IS NULL
		SET @kol_occ = 999999

		--TRUNCATE TABLE PAYM_ADD
		--TRUNCATE TABLE PEOPLE_LIST_RAS
		---- отключаем тригеры
		--ALTER TABLE dbo.OCCUPATIONS DISABLE TRIGGER ALL
		--ALTER TABLE dbo.CONSMODES_LIST DISABLE TRIGGER ALL
		----ALTER TABLE dbo.ADDED_PAYMENTS DISABLE TRIGGER ALL
		--ALTER TABLE dbo.OCC_SUPPLIERS DISABLE TRIGGER ALL

		;
	WITH cte AS
	(
		SELECT Occ
			 , b.fin_current AS fin_id
			 , o.tip_id
			 , CAST(CASE
				   WHEN ot.payms_value = 1 AND
					   b.is_paym_build = 1 THEN 1
				   --WHEN b.is_paym_build=1 THEN 1
				   ELSE 0
			   END AS BIT) AS payms_value
		--,b.is_paym_build
		FROM dbo.Occupations AS o
			JOIN dbo.Occupation_Types AS ot  ON o.tip_id = ot.id
			JOIN dbo.Flats f ON o.flat_id = f.id
			JOIN dbo.Buildings b  ON f.bldn_id = b.id
		WHERE status_id <> 'закр' --and occ>200000
			AND o.Occ >= @occ_start
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND ot.state_id <> 'стоп' -- где тип фонда открыт для редактирования
			AND (ot.raschet_no = 0 OR ot.only_pasport = 1 OR (DB_NAME() = 'NAIM') OR o.PaymAccount <> 0)
	)

	SELECT TOP (@kol_occ) *
	INTO #t
	FROM cte
	WHERE payms_value = CASE
                            WHEN @is_paym IS NULL THEN payms_value
                            ELSE @is_paym
        END
	ORDER BY Occ  -- чтобы работало @occ_start
	SELECT @kolVibor = @@rowcount
	SET @msg = N'Отобрано:' + STR(@kolVibor) + ' ' + CASE
                                                         WHEN @is_paym = 1 THEN N'кому начисляем'
                                                         ELSE CASE
                                                                  WHEN @is_paym = 0 THEN N'кому не начисляем'
                                                                  ELSE 'всех'
                                                             END
        END
	RAISERROR (@msg, 10, 1) WITH NOWAIT;

	SELECT @msg = 'Начинаем перерасчёт в ' + CONVERT(VARCHAR(20), current_timestamp, 120) --'yyyy-MM-dd HH:mm:ss'
	RAISERROR (@msg, 10, 1) WITH NOWAIT;


	BEGIN TRY

		DECLARE curs CURSOR LOCAL FOR
			SELECT Occ
				 , fin_id
				 , tip_id
				 , payms_value
			FROM #t
			ORDER BY payms_value DESC
				   , tip_id
				   , Occ  -- делаем расчёт с начала кому начисляем
		OPEN curs
		FETCH NEXT FROM curs INTO @occ1, @fin_id1, @tip_id1, @payms_value1 --, @is_paym_build1

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT @i += 1
				 , @kol_tip += 1
				 , @date_temp = current_timestamp

			-- Расчитываем квартплату
			EXEC @er = dbo.k_raschet_2 @occ1, @fin_id1
			IF @er <> 0
			BEGIN
				SET @y +=1
				IF @y < 6
				BEGIN
					SET @strerror = 'Ошибка при перерасчете! Лицевой: ' + STR(@occ1)
					EXEC dbo.k_adderrors_card @strerror
				END
			END

			-- всегда выводим рассчитанный тип фонда
			IF COALESCE(@tip_id_prev, -1) <> @tip_id1
			BEGIN
				IF @tip_id_prev IS NOT NULL
				BEGIN
					SET @kol_time = DATEDIFF(SECOND, @time_tip, current_timestamp)
					SET @kol_time = CASE
                                        WHEN @kol_time = 0 THEN 1
                                        ELSE @kol_time
                        END

					SET @msg = CONCAT('=> tip_id: ',@tip_id_prev,' (',@kol_tip,'), ',
						CONVERT(VARCHAR(20), current_timestamp, 120),
						', ',@i - 1,'/',@kolVibor,' л/сч., скорость: ',STR(@kol_tip / @kol_time, 2),
						' л/сч. в сек. за ', @kol_time,' сек., прошло: ', dbo.Fun_GetTimeStr(@start_time1))

					RAISERROR (@msg, 10, 1) WITH NOWAIT;
				END
				SELECT @tip_id_prev = @tip_id1
					 , @time_tip = current_timestamp
					 , @kol_tip = 0
			END

			IF @debug = 1
			BEGIN
				SET @kol_time = DATEDIFF(MILLISECOND, @date_temp, current_timestamp)
				SET @msg = CONCAT(@i,' л/сч: ', @occ1,' за ',@kol_time,' ms tip_id: ',@tip_id1,', payms_value: ', @payms_value1 )
				RAISERROR (@msg, 10, 1) WITH NOWAIT;
			END

			FETCH NEXT FROM curs INTO @occ1, @fin_id1, @tip_id1, @payms_value1 --, @is_paym_build1
		--if @debug=1 IF @i>=1000 BREAK
		END

		CLOSE curs
		DEALLOCATE curs

		IF @kolVibor > 0
		BEGIN

			SELECT @kol_time = DATEDIFF(SECOND, @start_time1, current_timestamp)
			SET @msg = 'Выполнено за ' + dbo.Fun_GetTimeStr(@start_time1) --+ CHAR(13)
			IF @kol_time > @kolVibor
				SET @msg = @msg + ' со скоростью: ' + LTRIM(STR(@kol_time / @kolVibor)) + ' сек. за л/сч.'
			ELSE
				SET @msg = @msg + ' со скоростью: ' + LTRIM(STR(@kolVibor / @kol_time)) + ' л/сч. в сек.'
			RAISERROR (@msg, 10, 1) WITH NOWAIT;
		END

	END TRY

	BEGIN CATCH

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT
		SET @strerror = @strerror + 'Лицевой: ' + LTRIM(STR(@occ1))
		SET @strerror = @strerror + ' Рассчитали л/счетов: ' + LTRIM(STR(@i))
		IF @@trancount > 0
			ROLLBACK TRAN
		RAISERROR (@strerror, 16, 1)
		EXEC dbo.adm_send_mail @strerror

	END CATCH
go

