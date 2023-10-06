CREATE   PROCEDURE [dbo].[ka_add_added_4_begin]
(
	@occ1			INT -- лицевой счет
	,@serv_str		VARCHAR(2000) -- строка формата: код услуги:код поставщика;код услуги:код поставщика
	,@add_type1		INT -- тип разового
	,@doc1			VARCHAR(100) -- документ
	,@data1			DATETIME -- с этого дня  "некачественное предоставление услуги"
	,@data2			DATETIME -- по этот день
	,@tnorm1		SMALLINT --  нормативная температора
	,@tnorm2		SMALLINT --  на сколько градусов ниже нормы
	,@znak1			BIT				= 0 -- 0 то разовае со знаком "-" если 1 то "+"
	,@doc_no1		VARCHAR(15)		= NULL -- номер акта
	,@doc_date1		SMALLDATETIME	= NULL -- дата акта
	,@vin1			INT				= NULL -- виновник1 (участок)
	,@vin2			INT				= NULL -- виновник2 (поставщик услуги)
	,@mode_history	BIT				= 0 -- при перерасчетах режимы брать из истории
	,@group1		BIT				= 0 -- 1 - групповое изменение (не выводим ошибок на экран)
	,@hours1		SMALLINT		= 0
	,@add_type2		SMALLINT		= 1
	,@manual_sum	DECIMAL(9, 2)	= 0
	,@debug			BIT				= 0
	,@KolAddItog	INT				OUTPUT -- кол-во добавили
)
AS
/*
		
Ввод разовых  "некачественное предоставление услуги" @add_type1=8
		
		
declare @addyes bit
exec dbo.ka_add_added_4_begin 680004826, 'гвод', 8, 'doc', '20151210','20160131' ,55,4, 0, null, null, null, null, 0, 0, 0, 1, 0, 1, @addyes
	
*/

	SET NOCOUNT ON;

	DECLARE	@fin_current		SMALLINT
			,@fin_id1			SMALLINT -- фин. период
			,@service_id1		VARCHAR(10)
			,@Start_date		SMALLDATETIME -- Начальная дата финансового  периода
			,@End_date			SMALLDATETIME -- Конечная  дата финансового  периода
			,@KolDayFinPeriod	SMALLINT -- Колличество дней в фин. периоде
			,@KolDayAdd			SMALLINT
			,@KolDay			INT
			,@comments			VARCHAR(50)	= NULL
			,@addyes			BIT
			,@hours_fin1		SMALLINT
			,@sup_id			INT

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
		,@KolAddItog = 0

	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		IF @group1 = 0
			RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		IF @group1 = 0
			RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		IF @group1 = 0
			RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
		RETURN
	END

	IF (@hours1 IS NULL)
		OR (@hours1 < 0)
		SET @hours1 = 0

	-- Таблица с услугами
	DECLARE @t_serv TABLE
		(
			id		VARCHAR(10)
			,sup_id	INT	DEFAULT NULL
		)
	IF dbo.strpos(':', @serv_str) > 0
	BEGIN
		INSERT
		INTO @t_serv
		(	id
			,sup_id)
				SELECT
					id
					,CAST(val AS INT)
				FROM dbo.Fun_split_IdValue(@serv_str, ';')
	END
	ELSE
	BEGIN
		INSERT
		INTO @t_serv
		(id)
				SELECT
					*
				FROM STRING_SPLIT(@serv_str, ';') WHERE RTRIM(value) <> ''
	END

	DECLARE	@fin_start	SMALLINT
			,@fin_end	SMALLINT
	SELECT
		@fin_start = fin_id
	FROM dbo.Global_values gv  
	WHERE @data1 BETWEEN start_date AND end_date

	IF @fin_start IS NULL
	BEGIN
		RAISERROR ('Фин.период не найден (%s)', 16, 1, 'Дата начала')
		RETURN
	END

	SELECT
		@fin_end = fin_id
	FROM dbo.Global_values gv  
	WHERE @data2 BETWEEN start_date AND end_date

	IF @fin_end IS NULL
	BEGIN
		RAISERROR ('Фин.период не найден (%s)', 16, 1, 'Дата окончания')
		RETURN
	END

	DECLARE @t_fin TABLE
		(
			fin_id		SMALLINT	PRIMARY KEY
			,kolday		SMALLINT
			,kolday_fin	SMALLINT
			,data1		SMALLDATETIME
			,data2		SMALLDATETIME
			,hours_fin	SMALLINT	DEFAULT 0
		)

	INSERT
	INTO @t_fin
	(	fin_id
		,kolday
		,kolday_fin
		,data1
		,data2)
			SELECT
				fin_id
				,kol_day =
					CASE
						WHEN @data1 BETWEEN start_date AND end_date AND
						@data2 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, @data1, @data2) + 1
						WHEN @data1 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, @data1, end_date) + 1
						WHEN @data2 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, start_date, @data2) + 1
						ELSE DATEDIFF(DAY, start_date, end_date) + 1
					END
				,KolDayFinPeriod --datediff(DAY, start_date, end_date) + 1
				,data1 =
					CASE
						WHEN @data1 BETWEEN start_date AND end_date THEN @data1
						ELSE start_date
					END
				,data2 =
					CASE
						WHEN @data2 BETWEEN start_date AND end_date THEN @data2
						ELSE end_date
					END
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id BETWEEN @fin_start AND @fin_end

	-- Обрабатываем часы
	UPDATE @t_fin
	SET hours_fin = kolday * @hours1 / (SELECT
			SUM(kolday)
		FROM @t_fin)
	WHERE @hours1 > 0
	-- проверяем остаток по часам
	SELECT
		@hours_fin1 = SUM(hours_fin)
	FROM @t_fin
	IF @hours_fin1 != 0
	BEGIN
		;WITH cte AS (
			SELECT TOP (1) * FROM @t_fin
		)
		UPDATE cte
		SET hours_fin = hours_fin + (@hours1 - @hours_fin1);
	END
	--*******************************


	IF @debug = 1
		SELECT
			*
		FROM @t_fin


	DECLARE cur CURSOR LOCAL FOR
		SELECT
			fin_id
			,data1
			,data2
			,hours_fin
		FROM @t_fin
	OPEN cur
	FETCH NEXT FROM cur INTO @fin_id1, @data1, @data2, @hours_fin1
	WHILE @@fetch_status = 0
	BEGIN

		-- Курсор по услугам
		DECLARE cur2 CURSOR LOCAL FOR
			SELECT
				id
				,sup_id
			FROM @t_serv
		OPEN cur2
		FETCH NEXT FROM cur2 INTO @service_id1, @sup_id
		WHILE @@fetch_status = 0
		BEGIN
			SET @addyes = 0
			EXECUTE [dbo].[ka_add_added_4]	@occ1
											,@service_id1
											,@add_type1
											,@doc1
											,@fin_id1
											,@data1
											,@data2
											,@tnorm1
											,@tnorm2
											,@znak1
											,@doc_no1
											,@doc_date1
											,@vin1
											,@vin2
											,@mode_history
											,@group1
											,@hours_fin1
											,@add_type2
											,@manual_sum
											,@addyes OUTPUT
											,@sup_id

			IF @addyes = 1
				SET @KolAddItog = @KolAddItog + 1

			FETCH NEXT FROM cur2 INTO @service_id1, @sup_id
		END
		CLOSE cur2
		DEALLOCATE cur2

		FETCH NEXT FROM cur INTO @fin_id1, @data1, @data2, @hours_fin1
	END
	CLOSE cur;
	DEALLOCATE cur;
go

