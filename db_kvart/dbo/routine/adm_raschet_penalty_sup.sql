CREATE   PROCEDURE [dbo].[adm_raschet_penalty_sup]
(
	  @sup_id INT = NULL
	, @debug BIT = 0
	, @kol_occ INT = NULL -- Кол-во лицевых для тестирования
	, @tip_id SMALLINT = NULL
	, @occ_start INT = NULL -- начальный лицевой для расчёта
)
AS
	/*
		Перерасчет пени по поставщикам
		
		adm_raschet_penalty_sup 323,0, @kol_occ=50

		adm_raschet_penalty_sup NULL,1,NULL,5

	*/

	SET NOCOUNT ON

	DECLARE @occ_sup INT = 0
		  , @i INT
		  , @y INT
		  , @er INT
		  , @strerror VARCHAR(800) = ''		  
		  , @fin_id SMALLINT
		  , @date_temp DATETIME
		  , @date_temp2 DATETIME
		  , @msg VARCHAR(100)
		  , @kolVibor INT

	DECLARE @StartTime datetime = current_timestamp	

	IF @kol_occ IS NULL
		SET @kol_occ = 999999
	IF @occ_start IS NULL
		SET @occ_start = 0

	SELECT @i = 0
		 , @y = 0
		 , @msg = 'Начинаем перерасчёт в ' + CONVERT(VARCHAR(25), current_timestamp, 108)
	RAISERROR (@msg, 10, 1) WITH NOWAIT;

	BEGIN TRY

		-- удаляем пени по услугам у закрытых лицевых
		DELETE FROM p
		FROM dbo.Occ_Suppliers AS os
			JOIN dbo.Occupations AS o ON 
				os.occ = o.occ 
				AND os.fin_id = o.fin_id
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id
			JOIN dbo.Peny_all AS p ON 
				o.occ = p.occ
				AND os.fin_id = p.fin_id
		WHERE 
			o.status_id = 'закр'
			AND (os.sup_id = @sup_id
			OR @sup_id IS NULL)			
			AND ot.PaymClosed = 0
			AND ot.PaymClosedData < @StartTime
			--AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования

		DROP TABLE IF EXISTS #t;
		CREATE TABLE #t (
			  occ_sup INT PRIMARY KEY
			, fin_id SMALLINT
		)
		INSERT INTO #t
		SELECT TOP (@kol_occ) occ_sup
							, os.fin_id
		FROM dbo.Occ_Suppliers AS os
			JOIN dbo.Occupations AS o ON 
				os.occ = o.occ
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id
		WHERE 
			o.status_id <> 'закр'
			AND (@sup_id IS NULL OR sup_id = @sup_id)
			AND os.fin_id = ot.fin_id
			AND os.occ_sup <> 0
			AND os.occ <> 0
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND o.occ >= @occ_start;

		SELECT @kolVibor = COUNT(*)	FROM #t;
		RAISERROR ('Отобрано: %i', 10, 1, @kolVibor) WITH NOWAIT;

		DECLARE curs1 CURSOR LOCAL FOR
			SELECT occ_sup
				 , fin_id
			FROM #t
			ORDER BY fin_id DESC

		OPEN curs1
		FETCH NEXT FROM curs1 INTO @occ_sup, @fin_id

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT @i += 1
				 , @date_temp = current_timestamp

			--EXECUTE sp_executesql @SQLString, @ParmDefinition, @occ1 = @occ1;

			EXEC @er = dbo.k_raschet_peny_sup_new @occ_sup = @occ_sup
												, @fin_id1 = @fin_id
												, @debug = 0 --@debug
			IF @er <> 0
			BEGIN
				SET @y += 1
				IF @y < 6
				BEGIN
					SET @strerror = 'Ошибка при перерасчете пени по поставщикам! Лицевой: ' + STR(@occ_sup)
					EXEC dbo.k_adderrors_card @strerror
				END
			END

			IF @debug = 1
			BEGIN
				SET @msg = CONCAT(@i,' л/сч: ',@occ_sup,' (фин: ',@fin_id,') за ',
					DATEDIFF(MS,@date_temp,current_timestamp),' мс. (',
					dbo.Fun_GetTimeStr(@StartTime),')')
				RAISERROR (@msg, 10, 1) WITH NOWAIT;
			END

			FETCH NEXT FROM curs1 INTO @occ_sup, @fin_id
		--if @debug=1 IF @i>=1000 BREAK
		END

		CLOSE curs1;
		DEALLOCATE curs1;

		DECLARE @kolSecond INT
		SELECT @kolSecond = DATEDIFF(SECOND,@StartTime,current_timestamp)
		SET @msg = 'Выполнено за ' + dbo.Fun_GetTimeStr(@StartTime) + CHAR(13)
		IF (@kolSecond > 0)
			IF @kolSecond > @kolVibor
				SET @msg = @msg + 'со скоростью: ' + LTRIM(STR(@kolSecond / @kolVibor)) + ' секунд за лиц/сч.'
			ELSE
				SET @msg = @msg + 'со скоростью: ' + LTRIM(STR(@kolVibor / @kolSecond)) + ' лиц/сч. в сек.'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;

		DROP TABLE IF EXISTS #t;

	END TRY

	BEGIN CATCH
		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ_sup))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

