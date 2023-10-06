CREATE   PROCEDURE [dbo].[k_counter_raschet_flats2]
(
	  @flat_id1 INT -- код квартиры 
	, @tip_value1 SMALLINT = 0 -- 0-показания инспектора, 1- квартиросъемщика
	, @debug BIT = 0
	, @service_id1 VARCHAR(10) = NULL
	, @isRasHistory BIT = 0 -- расчет по всем показаниям с историей
)
AS
	/*
	EXEC  k_counter_raschet_flats2 @flat_id1=79620,@tip_value1=1,@debug=1,@isRasHistory=0
    EXEC  k_counter_raschet_flats2 @flat_id1=79620,@tip_value1=1,@debug=1,@isRasHistory=1
	
	Расчет по квартире со внутренними счетчиками 
	*/
	SET NOCOUNT ON;

	IF @isRasHistory IS NULL
		SET @isRasHistory = 0

	BEGIN TRY

		DECLARE @err INT
			  , @strerror VARCHAR(4000)
			  , @DB_NAME VARCHAR(30) = UPPER(DB_NAME())

		-- Выбираем все счетчики по квартире
		DECLARE @counter_flats_serv TABLE (
			  service_id VARCHAR(10)
			, tip_id SMALLINT
			, fin_current SMALLINT
			, Occ INT
			, avg_vday DECIMAL(12, 6) DEFAULT 0
		);

		--SELECT service_id, avg_vday 
		--INTO #t_avg
		--FROM dbo.Fun_GetAvgCounterValueTableFlat(@flat_id1);
		--select * FROM dbo.Fun_GetAvgCounterValueTableFlat(@flat_id1)

		;WITH cte AS (
		SELECT
			C.service_id
			, o.tip_id
			, o.fin_id
			, o.Occ	
		FROM dbo.Counters AS C 
			JOIN dbo.Occupations o ON 
				C.flat_id = o.flat_id
		WHERE C.flat_id = @flat_id1
			AND C.internal = CAST(1 AS BIT)
			AND (@service_id1 IS NULL OR C.service_id = @service_id1)
			AND o.status_id <> 'закр'
			AND o.total_sq <> 0
		GROUP BY c.service_id, o.tip_id, o.fin_id, o.Occ	
		)
		INSERT INTO @counter_flats_serv (service_id
									   , tip_id
									   , fin_current
									   , Occ
									   , avg_vday)		
		SELECT t.* 
			, COALESCE(t_avg.avg_vday, 0) AS avg_vday
		from cte as t
			LEFT JOIN dbo.Fun_GetAvgCounterValueTableFlat(@flat_id1) AS t_avg ON 
				t_avg.service_id=t.service_id

		--SELECT distinct C.service_id
		--			  , o.tip_id
		--			  , o.fin_id
		--			  , o.Occ
		--			  , COALESCE(t_avg.avg_vday, 0) AS avg_vday
		--FROM dbo.Counters AS C 
		--	JOIN dbo.Occupations o ON 
		--		C.flat_id = o.flat_id
		--	LEFT JOIN dbo.Fun_GetAvgCounterValueTableFlat(@flat_id1) AS t_avg ON 
		--		t_avg.service_id=c.service_id
		--WHERE C.flat_id = @flat_id1
		--	AND C.internal = CAST(1 AS BIT)
		--	AND (@service_id1 IS NULL OR C.service_id = @service_id1)
		--	AND o.status_id <> 'закр'
		--	AND o.total_sq <> 0;

		-- удаляем услуги по которым не надо расчитывать по счётчикам
		DELETE t1
		--SELECT	*
		FROM @counter_flats_serv AS t1
			JOIN dbo.Services_type_counters AS stc ON t1.service_id = stc.service_id
				AND stc.tip_id = t1.tip_id
				AND stc.no_counter_raschet = 1;

		IF @debug = 1
			SELECT '@counter_flats_serv', *
			FROM @counter_flats_serv;

		--*********************************************************
		-- проставляем кол-во месяцев до даты поверки
		UPDATE cl
		SET KolmesForPeriodCheck = CASE
                                       WHEN @DB_NAME = 'KOMP'
                                           THEN dbo.Fun_GetKolMonthPeriodCheck(cl.Occ, cl.fin_id, cl.service_id)
                                       ELSE dbo.Fun_GetKolMonthPeriodCheck2020(cl.Occ, cl.fin_id, cl.service_id)
            END
			--, kol_occ = [dbo].[Fun_GetCounter_occ](cl.counter_id, cl.fin_id)
		  , avg_vday = cf.avg_vday --  COALESCE(t_avg.avg_vday, 0)
		FROM dbo.Counter_list_all AS cl
			JOIN @counter_flats_serv AS cf ON cl.service_id = cf.service_id
				AND cl.fin_id = cf.fin_current
				AND cf.Occ = cl.Occ
		--OUTER APPLY dbo.Fun_GetAvgCounterValueTable(cf.Occ, cf.service_id, cf.count_month_avg) AS t_avg
		--WHERE o.flat_id = @flat_id1


		;WITH cte AS (
		SELECT 
		  kol_occ, kol_occ_new = COUNT(cl.occ) OVER(PARTITION BY cl.counter_id, cl.fin_id)
		FROM dbo.Counter_list_all AS cl
			JOIN @counter_flats_serv AS cf ON cl.service_id = cf.service_id
				AND cl.fin_id = cf.fin_current
				AND cf.Occ = cl.Occ		
		)
		UPDATE cte SET kol_occ=kol_occ_new;

		--UPDATE cl
		--SET kol_occ = [dbo].[Fun_GetCounter_occ](cl.counter_id, cl.fin_id)
		--FROM dbo.Counter_list_all AS cl
		--	JOIN dbo.Counters c ON cl.counter_id = c.id
		--WHERE c.flat_id = @flat_id1;

		UPDATE cl
		SET KolmesForPeriodCheck = (SELECT TOP(1) cl2.KolmesForPeriodCheck 
									FROM dbo.Counter_list_all AS cl2 
									WHERE cl2.counter_id=c.id 
									AND cl2.fin_id<t.fin_current
									ORDER BY cl2.fin_id DESC)
		FROM dbo.Counters c
			JOIN dbo.Counter_list_all AS cl ON cl.counter_id=c.id
			JOIN @counter_flats_serv as t ON cl.fin_id=t.fin_current AND cl.service_id=t.service_id
		WHERE c.flat_id = @flat_id1
		and c.date_del IS NOT NULL

		--*********************************************************

		IF @debug = 1
			SELECT * FROM Counter_list_all cl
				JOIN @counter_flats_serv as t ON cl.occ=t.Occ AND cl.fin_id=t.fin_current AND cl.service_id=t.service_id
			ORDER BY cl.service_id

		-- делаем перерасчет по счетчикам в квартире
		DECLARE @fin_current SMALLINT
		DECLARE some_cur CURSOR FOR
			SELECT DISTINCT service_id
						  , fin_current
			FROM @counter_flats_serv;
		OPEN some_cur;

		WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM some_cur INTO @service_id1, @fin_current
			IF @@fetch_status <> 0
				BREAK;

			EXEC @err = dbo.k_counter_raschet2 @flat_id1 = @flat_id1
											 , @service_id1 = @service_id1
											 , @tip_value1 = @tip_value1
											 , @debug = @debug
											 , @fin_current = @fin_current
											 , @isRasHistory = @isRasHistory

			IF @err <> 0
			BEGIN
				DEALLOCATE some_cur;
				SET @strerror = 'Ошибка при перерасчете квартиры : ' + STR(@flat_id1);
				EXEC dbo.k_adderrors_card @strerror;
				RETURN @err;
			END;

		END;

		DEALLOCATE some_cur;

		IF @debug = 1
			PRINT 'Расчитали по счетчикам';


	END TRY

	BEGIN CATCH

		SET @strerror = CONCAT('Код квартиры: ', @flat_id1,', Адрес: ', dbo.Fun_GetAdresFlat(@flat_id1))
		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1);
		RETURN @err;

	END CATCH; ;
go

