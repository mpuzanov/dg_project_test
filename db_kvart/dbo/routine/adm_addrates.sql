CREATE   PROCEDURE [dbo].[adm_addrates]
(
	@FinPeriod1	  SMALLINT -- фин.период
   ,@tipe_id1	  SMALLINT	 = NULL -- тип жилого фонда 
   ,@service_id1  VARCHAR(10) -- код услуги
   ,@mode_id1	  INT		 = NULL -- код режима потребления
   ,@source_id1	  INT		 = NULL -- код поставщика
   ,@status_id1	  VARCHAR(10) -- статус лицевого счета(откр, своб, закр)
   ,@proptype_id1 VARCHAR(10) = NULL -- статус квартиры (непр, прив, купл, арен )
   ,@t1			  DECIMAL(10, 4) = 0 -- обычный тариф (value)
   ,@t2			  DECIMAL(10, 4) = 0 -- 100% тариф  (full_value)
   ,@t3			  DECIMAL(10, 4) = 0 -- сверх. тариф (extr_value)

)
AS
/*
Устанавливаем тарифы

dbo.adm_addrates 34,1,'площ',1001,1000,'откр','прив',5.23,5.23,5.23
*/

	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @source_id1 = 0
		SET @source_id1 = NULL

	IF @mode_id1 = 0
		SET @mode_id1 = NULL


	DECLARE @user_edit SMALLINT = dbo.Fun_GetCurrentUserId()


	-- **********************************************
	IF (@source_id1 IS NOT NULL)
		AND (@mode_id1 IS NOT NULL)
		AND (@proptype_id1 IS NOT NULL)
		AND (@tipe_id1 IS NOT NULL)
	BEGIN
		-- у режима Нет или поставщика Нет - тариф не ставим
		IF (@mode_id1 % 1000) = 0 OR (@source_id1 % 1000) = 0			
			RETURN

		IF EXISTS (SELECT
					1
				FROM RATES
				WHERE 
					FinPeriod = @FinPeriod1
					AND tipe_id = @tipe_id1
					AND service_id = @service_id1
					AND mode_id = @mode_id1
					AND source_id = @source_id1
					AND Status_id = @status_id1
					AND proptype_id = @proptype_id1)
		BEGIN
			UPDATE RATES
			SET Value	   = @t1
			   ,full_value = @t2
			   ,extr_value = @t3
			   ,user_edit  = @user_edit
			WHERE FinPeriod = @FinPeriod1
			AND tipe_id = @tipe_id1
			AND service_id = @service_id1
			AND mode_id = @mode_id1
			AND source_id = @source_id1
			AND Status_id = @status_id1
			AND proptype_id = @proptype_id1
		END
		ELSE
		BEGIN
			-- Проверяем режим
			IF NOT EXISTS (SELECT
						1
					FROM dbo.CONS_MODES cm
					WHERE cm.service_id = @service_id1
					AND cm.id = @mode_id1)
			BEGIN
				RAISERROR ('Режима потребления с кодом <%i> нет по услуге <%s>', 16, 1, @mode_id1, @service_id1)
				RETURN 1
			END

			INSERT INTO dbo.Rates
			(FinPeriod
			,tipe_id
			,service_id
			,mode_id
			,source_id
			,Status_id
			,proptype_id
			,Value
			,full_value
			,extr_value
			,user_edit)
			VALUES (@FinPeriod1
				   ,@tipe_id1
				   ,@service_id1
				   ,@mode_id1
				   ,@source_id1
				   ,@status_id1
				   ,@proptype_id1
				   ,@t1
				   ,@t2
				   ,@t3
				   ,@user_edit)
		END

	END --IF @source_id1 is not NULL


	--******************************************************
	-- находим все режимы по заданной услуге и другим параметрам
	-- делаем курсор по ним 
	-- и вызываем рекурсионно эту же процедуру
	IF (@mode_id1 IS NULL)
		AND (@source_id1 IS NOT NULL)
		AND (@proptype_id1 IS NOT NULL)
		AND (@tipe_id1 IS NOT NULL)
	BEGIN
		DECLARE curs CURSOR FOR
			SELECT
				id
			FROM dbo.Cons_modes cm
			WHERE service_id = @service_id1
			AND (id % 1000) != 0
		OPEN curs
		FETCH NEXT FROM curs INTO @mode_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			--   print str(@mode_id1)

			EXEC adm_addrates @FinPeriod1
							 ,@tipe_id1
							 ,@service_id1
							 ,@mode_id1
							 ,@source_id1
							 ,@status_id1
							 ,@proptype_id1
							 ,@t1
							 ,@t2
							 ,@t3

			FETCH NEXT FROM curs INTO @mode_id1
		END

		CLOSE curs
		DEALLOCATE curs
	END

	--******************************************************
	-- находим всех поставщиков по заданной услуге и типу фонда
	-- делаем курсор по ним 
	-- и вызываем рекурсионно эту же процедуру
	IF (@source_id1 IS NULL)
		AND (@mode_id1 IS NOT NULL)
		AND (@proptype_id1 IS NOT NULL)
		AND (@tipe_id1 IS NOT NULL)
	BEGIN
		DECLARE curs CURSOR FOR
			SELECT DISTINCT
				vs.id
			FROM dbo.View_SUPPLIERS AS vs 
				JOIN dbo.Build_source AS bs ON 
					vs.service_id=bs.service_id 
					AND vs.id=bs.source_id
				JOIN dbo.Buildings AS b ON 
					b.id=bs.build_id
			WHERE vs.service_id = @service_id1
				AND (bs.source_id % 1000) != 0
				AND b.tip_id=@tipe_id1
		OPEN curs
		FETCH NEXT FROM curs INTO @source_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			--   print str(@source_id1)

			EXEC adm_addrates @FinPeriod1
							 ,@tipe_id1
							 ,@service_id1
							 ,@mode_id1
							 ,@source_id1
							 ,@status_id1
							 ,@proptype_id1
							 ,@t1
							 ,@t2
							 ,@t3

			FETCH NEXT FROM curs INTO @source_id1
		END

		CLOSE curs
		DEALLOCATE curs
	END

	--********************************************************
	-- для всех Статусов квартиры 
	IF (@proptype_id1 IS NULL)
		AND (@source_id1 IS NOT NULL)
		AND (@mode_id1 IS NOT NULL)
		AND (@tipe_id1 IS NOT NULL)
	BEGIN
		DECLARE curs CURSOR FOR
			SELECT
				id
			FROM Property_types
		OPEN curs
		FETCH NEXT FROM curs INTO @proptype_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			EXEC adm_addrates @FinPeriod1
							 ,@tipe_id1
							 ,@service_id1
							 ,@mode_id1
							 ,@source_id1
							 ,@status_id1
							 ,@proptype_id1
							 ,@t1
							 ,@t2
							 ,@t3

			FETCH NEXT FROM curs INTO @proptype_id1
		END

		CLOSE curs
		DEALLOCATE curs
	END

	-- тарифы по воде ставим так же на счётчики
	IF @service_id1 IN ('хвод', 'хвс2', 'гвод', 'гвс2', 'вотв')
		EXEC dbo.adm_addrates_counter @fin_id1 = @FinPeriod1
									 ,@tipe_id1 = @tipe_id1
									 ,@service_id1 = @service_id1
									 ,@unit_id1 = 'кубм'
									 ,@t1 = @t1
									 ,@source_id1 = @source_id1
									 ,@mode_id1 = @mode_id1

	-- тарифы по воде ставим так же на счётчики
	IF @service_id1 IN ('элек')
		EXEC dbo.adm_addrates_counter @fin_id1 = @FinPeriod1
									 ,@tipe_id1 = @tipe_id1
									 ,@service_id1 = @service_id1
									 ,@unit_id1 = 'квтч'
									 ,@t1 = @t1
									 ,@source_id1 = @source_id1
									 ,@mode_id1 = @mode_id1

	--********************************************************
	-- Для всех типов жилого фонда
	IF (@tipe_id1 IS NULL)
		AND (@source_id1 IS NOT NULL)
		AND (@mode_id1 IS NOT NULL)
		AND (@proptype_id1 IS NOT NULL)
	BEGIN
		DECLARE curs CURSOR FOR
			SELECT
				id
			FROM Occupation_Types
		OPEN curs
		FETCH NEXT FROM curs INTO @tipe_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			-- print str(@tipe_id1)

			EXEC adm_addrates @FinPeriod1
							 ,@tipe_id1
							 ,@service_id1
							 ,@mode_id1
							 ,@source_id1
							 ,@status_id1
							 ,@proptype_id1
							 ,@t1
							 ,@t2
							 ,@t3

			FETCH NEXT FROM curs INTO @tipe_id1
		END

		CLOSE curs
		DEALLOCATE curs
	END
go

