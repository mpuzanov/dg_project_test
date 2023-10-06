CREATE   PROCEDURE [dbo].[adm_raschet_penalty]
(
	@tip_id1		SMALLINT = NULL
   ,@debug			BIT		 = 0
   ,@kol_occ		INT		 = NULL -- Кол-во лицевых для тестирования
   ,@occ_start		INT		 = NULL -- начальный лицевой для расчёта
   ,@is_payms_value BIT		 = NULL -- признак начисления в типе фонда
)
AS
	/*
		Перерасчет пени по всей базе
		
	adm_raschet_penalty @tip_id1=28,@debug=1
	adm_raschet_penalty @occ_start=274765, @debug=1, @kol_occ=1
	adm_raschet_penalty @debug=1,@is_payms_value=1

	*/
	SET NOCOUNT ON

	DECLARE @occ1			INT
		   ,@address		VARCHAR(100)
		   ,@i				INT
		   ,@y				INT
		   ,@er				INT
		   ,@strerror		VARCHAR(800)  = ''
		   ,@PaymClosedData SMALLDATETIME
		   ,@fin_current	SMALLINT
		   ,@PaymClosed1	BIT
		   ,@DateCurrent1   SMALLDATETIME = NULL
		   ,@date_temp		DATETIME
		   ,@date_temp2		DATETIME
		   ,@msg			VARCHAR(100)
		   ,@kolVibor		INT

	DECLARE @StartTime datetime = current_timestamp	

	IF @kol_occ IS NULL
		SET @kol_occ = 999999
	IF @occ_start IS NULL
		SET @occ_start = 0

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)

	SELECT
		@PaymClosed1 = PaymClosed
	   ,@PaymClosedData = PaymClosedData
	FROM dbo.Global_values 
	WHERE fin_id = @fin_current

	SET @msg = 'fin_current:' + STR(@fin_current)
	RAISERROR (@msg, 10, 1) WITH NOWAIT;

	--IF (@PaymClosed1=1) AND (@PaymClosedData<@date1)  --  27.09.2005
	--BEGIN
	--    PRINT 'Платежный период закрыт пени считать больше не буду!'
	--    RETURN 0
	--END   -- 15/07/12 В процедуре есть обработка даты закрытия платёжного периода

	SELECT
	   @i = 0
	   ,@y = 0
	   ,@DateCurrent1 = NULL

	;WITH cte
	AS
	(SELECT TOP (@kol_occ)
		occ, tip_id, o.address
	FROM dbo.Occupations AS o 
		JOIN dbo.Occupation_Types AS ot 
			ON o.tip_id = ot.id
	WHERE 
		o.STATUS_ID <> 'закр'
		AND (o.occ >= @occ_start)
		AND (o.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		--AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
		AND (ot.payms_value = @is_payms_value OR @is_payms_value IS NULL)
		AND (ot.raschet_no = 0	OR ot.only_pasport = 1 OR (DB_NAME() = 'NAIM') OR O.PaymAccount<>0)
	--ORDER BY ot.payms_value DESC, ot.penalty_calc_tip DESC, o.tip_id, o.occ
	)
	SELECT TOP (@kol_occ)
		*
	INTO #t
	FROM cte
	ORDER BY occ  -- чтобы работало @occ_start
	SELECT
		@kolVibor = @@rowcount	
	RAISERROR ('Отобрано: %i', 10, 1, @kolVibor) WITH NOWAIT;

	IF @kolVibor=0
		RETURN

	BEGIN TRY

		DECLARE curs1 CURSOR LOCAL FOR
			SELECT
				occ, [address]
			FROM #t
			ORDER BY tip_id, occ

		OPEN curs1
		FETCH NEXT FROM curs1 INTO @occ1, @address
		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT
				@i += 1
			   ,@date_temp = current_timestamp

			--IF @debug = 1
			--	PRINT STR(@i) + ' ' + STR(@occ1)

			--EXECUTE sp_executesql @SQLString, @ParmDefinition, @occ1 = @occ1;
			--dbcc freeproccache with no_infomsgs;
			EXEC @er = dbo.k_raschet_peny @occ1 = @occ1
										 ,@debug = 0
										 ,@fin_id1 = NULL
										 ,@DateCurrent1 = @DateCurrent1
			IF @er <> 0
			BEGIN
				SET @y += 1
				IF @y < 6
				BEGIN
					SET @strerror = 'Ошибка при перерасчете пени! Лицевой: ' + STR(@occ1)
					EXEC dbo.k_adderrors_card @strerror
				END
			END

			IF @debug = 1
			BEGIN
				SET @msg = CONCAT(@i,' л/сч: ',@occ1,' за ',
					DATEDIFF(MS, @date_temp,current_timestamp),' мс. (', 
					dbo.Fun_GetTimeStr(@StartTime),')')
				RAISERROR (@msg, 10, 1) WITH NOWAIT;
			END

			FETCH NEXT FROM curs1 INTO @occ1, @address
		--if @debug=1 IF @i>=1000 BREAK
		END
		CLOSE curs1
		DEALLOCATE curs1

		DECLARE @kolSecond INT	
		SELECT @kolSecond = DATEDIFF(SECOND, @StartTime, current_timestamp)

		SET @msg = 'Выполнено за ' + dbo.Fun_GetTimeStr(@StartTime) + CHAR(13)
		IF (@kolSecond > 0)
			IF (@kolSecond > @kolVibor)
				SET @msg = @msg + 'со скоростью: ' + LTRIM(STR(@kolSecond / @kolVibor)) + ' сек. за лиц/сч.'
			ELSE
				SET @msg = @msg + 'со скоростью: ' + LTRIM(STR(@kolVibor / @kolSecond)) + ' лиц/сч. в сек.'
		RAISERROR (@msg, 10, 1) WITH NOWAIT;

	END TRY

	BEGIN CATCH
		SET @strerror = @strerror + CONCAT(' Лицевой: <', LTRIM(STR(COALESCE(@occ1,''))),'>, Адрес: <',COALESCE(@address,''),'>')

		EXECUTE k_GetErrorInfo @visible = @debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

