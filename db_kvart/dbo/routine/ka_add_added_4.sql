CREATE   PROCEDURE [dbo].[ka_add_added_4]
(
	  @occ1 INT -- лицевой счет
	, @service_id1 VARCHAR(10) -- код услуги
	, @add_type1 INT -- тип разового
	, @doc1 VARCHAR(100) -- документ
	, @fin_id1 SMALLINT -- фин. период
	, @data1 DATETIME -- с этого дня  "некачественное предоставление услуги"
	, @data2 DATETIME -- по этот день
	, @tnorm1 SMALLINT --  нормативная температора
	, @tnorm2 SMALLINT --  на сколько градусов ниже нормы
	, @znak1 BIT = 0 -- 0 то разовае со знаком "-" если 1 то "+"
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @vin1 INT = NULL -- виновник1 (участок)
	, @vin2 INT = NULL -- виновник2 (поставщик услуги)
	, @mode_history BIT = 0 -- при перерасчетах режимы брать из истории
	, @group1 BIT = 0 -- 1 - групповое изменение (не выводим ошибок на экран)
	, @hours1 SMALLINT = 0
	, @add_type2 SMALLINT = 1
	, @manual_sum DECIMAL(9, 2) = 0
	, @addyes BIT OUTPUT-- если 1 то разовые добавили
	, @sup_id INT = NULL
)
AS
	--
	--  Ввод разовых  "некачественное предоставление услуги" @add_type1=8
	--
	--declare @addyes bit
	--exec dbo.ka_add_added_4 55967, 'гвод', 8, 'doc', 49, '20060201','20060228' ,55,4, 0, null, null, null, null, 0, 0, @addyes

	/*
	13/11/2007
	Убрал участие субсидий в расчете разовых
	*/

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @summa2 MONEY;
	DECLARE @KolDay INT;

	DECLARE @fin_current SMALLINT
		  , @Start_date SMALLDATETIME -- Начальная дата финансового  периода
		  , @End_date SMALLDATETIME -- Конечная  дата финансового  периода
		  , @KolDayFinPeriod SMALLINT -- Колличество дней в фин. периоде
		  , @KolDayAdd SMALLINT
		  , @KoefSubsid DECIMAL(8, 4)
		  , @ExtSubsidia BIT
		  , @comments VARCHAR(50) = NULL;

	IF @sup_id IS NULL
		SELECT @sup_id = dbo.Fun_GetSup_idOcc(@occ1, @service_id1)

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);

	IF (@hours1 IS NULL)
		OR (@hours1 < 0)
		SET @hours1 = 0;

	IF (@tnorm1 IS NULL)
		OR (@tnorm1 < 0)
		SET @tnorm1 = 0;
	IF (@tnorm2 IS NULL)
		OR (@tnorm2 < 0)
		SET @tnorm2 = 0;
	IF (@tnorm1 < @tnorm2)
		SELECT @tnorm1 = 0
			 , @tnorm2 = 0;

	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		IF @group1 = 0
			RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1);
		RETURN;
	END;

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		IF @group1 = 0
			RAISERROR ('База закрыта для редактирования!', 16, 1);
		RETURN;
	END;

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		IF @group1 = 0
			RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1);
		RETURN;
	END;

	SELECT @Start_date = start_date
		 , @End_date = end_date
		 , @ExtSubsidia = ExtSubsidia
	FROM dbo.Global_values 
	WHERE fin_id = @fin_id1;

	IF @ExtSubsidia = 1 -- если внешний расчет субсидий надо самим находить пропорцию по дням
	BEGIN
		SELECT @KolDayFinPeriod = DATEDIFF(DAY, @Start_date, DATEADD(MONTH, 1, @Start_date));
		SELECT @KolDayAdd = DATEDIFF(DAY, @data1, @data2) + 1;
		SELECT @KoefSubsid = CAST(@KolDayAdd AS DECIMAL(8, 4)) / @KolDayFinPeriod;

	--	select @KolDayFinPeriod
	--	select @KolDayAdd 
	END;
	ELSE
	BEGIN
		SELECT @KoefSubsid = 1;
	END;
	--select @KoefSubsid


	IF @vin1 = 0
		SET @vin1 = NULL;
	IF @vin2 = 0
		SET @vin2 = NULL;

	SET @addyes = 0;

	IF (@add_type1 = 8)
	BEGIN
		DECLARE @factor SMALLINT
			  , @summa1 MONEY
			  , @Sum1 DECIMAL(10, 4)
			  , @AddGvrProcent1 DECIMAL(10, 4)
			  , @AddOtpProcent1 DECIMAL(10, 4)
			  , @AddGvrDays1 DECIMAL(10, 4);

		SET @factor =
					 CASE
						 WHEN COALESCE(@znak1, 0) = 0 THEN -1
						 ELSE 1
					 END;

		-- Проверяем есть ли такая услуга на этом лицевом
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list AS cl 
				WHERE cl.occ = @occ1
					AND cl.service_id = @service_id1
					AND cl.sup_id = @sup_id
					AND (cl.mode_id % 1000) != 0
			)
		BEGIN
			IF @group1 = 0
				RAISERROR ('У лицевого нет режима потребления по услуге: %s ', 16, 1, @service_id1);
			RETURN;
		END;

		--*******************************************************************
		-- Проверяем есть ли счетчик в том месяце по которому проводяться разовые
		IF EXISTS (
				SELECT 1
				FROM dbo.View_paym AS cl 
				WHERE cl.occ = @occ1
					AND cl.fin_id = @fin_id1
					AND cl.service_id = @service_id1
					AND cl.sup_id = @sup_id
					AND cl.is_counter = 1 -- IN (1,2)
			)
		BEGIN
			IF @group1 = 0
				RAISERROR ('У лицевого %d внешний счетчик по этой услуге в заданном месяце', 16, 1, @occ1);
			RETURN;
		END;

		-- Проверяем есть ли счетчик в том месяце по которому проводяться разовые
		IF @service_id1 = 'гвс2'
			AND EXISTS (
				SELECT 1
				FROM dbo.View_paym AS cl 
				WHERE cl.occ = @occ1
					AND cl.fin_id = @fin_id1
					AND cl.service_id = @service_id1
					AND cl.sup_id = @sup_id
					AND cl.is_counter = 1
			)
		BEGIN
			IF @group1 = 0
				RAISERROR ('У лицевого %d счетчик по этой услуге в заданном месяце', 16, 1, @occ1);
			RETURN;
		END;

		--*******************************************************************
		DECLARE @manual_bit BIT;
		SET @manual_bit = 0;
		IF @manual_sum <> 0 -- ПРОВЕРЯЕМ РУЧНОЙ ВВОД СУММЫ РАЗОВОГО
		BEGIN
			SELECT @summa1 = @manual_sum;
			SET @manual_bit = 1;
			GOTO label_write; -- сразу идем на запись
		END;
		ELSE
			SET @manual_sum = 0;

		--*******************************************************************
		IF @hours1 > 0
			AND @manual_sum = 0
			AND (@service_id1 IN ('гвод', 'хвод', 'отоп', 'гвс2', 'ото2', 'тепл', 'гвсд')) --
		BEGIN --пересчёт по часам

			SELECT @summa1 = p.Value - p.Discount
			FROM dbo.View_paym AS p
			WHERE p.service_id = @service_id1
				AND p.occ = @occ1
				AND p.fin_id = @fin_id1
				AND p.sup_id = @sup_id;

			IF (@summa1 IS NULL)
				OR (@summa1 < 0)
				SET @summa1 = 0;
			SET @summa2 = @summa1;

			IF @add_type2 = 1
			BEGIN --@add_type2=1
				IF @service_id1 IN ('гвод', 'гвс2', 'тепл', 'гвсд')
				BEGIN
					IF @tnorm1 - @tnorm2 < 40
					BEGIN
						SET @comments = LTRIM(STR(@summa1, 15, 4)) + '*' + LTRIM(STR(@hours1)) + '*0.00137*' + LTRIM(STR(@factor));
						SET @summa1 = @summa1 * @hours1 * 0.00137 * @factor;
					END;
					IF @tnorm1 - @tnorm2 >= 40
						AND @tnorm2 > 0
					BEGIN
						SET @comments = LTRIM(STR(@summa1, 15, 4)) + '*' + LTRIM(STR(@hours1)) + '*0.001*' + LTRIM(STR(@factor));
						SET @summa1 = @summa1 * @hours1 * 0.001 * @factor;
					END;
				END;

				IF @service_id1 IN ('отоп', 'ото2')
				BEGIN
					IF @tnorm2 > 0
					BEGIN
						SET @comments = LTRIM(STR(@summa1, 15, 4)) + '*' + LTRIM(STR(@hours1)) + '*0.0015*' + LTRIM(STR(@factor));
						SET @summa1 = @summa1 * @hours1 * 0.0015 * @factor;
					END;
				END;
				IF @service_id1 = 'хвод'
					SET @summa1 = 0;

			END; --@add_type2=1
			IF @add_type2 = 2
			BEGIN --@add_type2=2
				IF @service_id1 IN ('гвод', 'гвс2', 'тепл', 'гвсд')
				BEGIN
					SET @comments = dbo.FSTR(@summa1, 15, 4) + '*' + LTRIM(STR(@hours1)) + '*0,001*' + LTRIM(STR(@factor));
					SET @summa1 = @summa1 * @hours1 * 0.001 * @factor;
				END;
				IF @service_id1 = 'хвод'
				BEGIN
					SET @comments = dbo.FSTR(@summa1, 15, 4) + '*' + LTRIM(STR(@hours1)) + '*0,001*' + LTRIM(STR(@factor));
					SET @summa1 = @summa1 * @hours1 * 0.001 * @factor;
				END;
				IF @service_id1 IN ('отоп', 'ото2')
					SET @summa1 = 0;
			END; --@add_type2=2

			IF @summa1 * @factor > @summa2
				SET @summa1 = @summa2 * @factor;

			GOTO label_write; -- сразу идем на запись

		END; --пересчёт по часАМ
		ELSE
		BEGIN --по старой формуле 

			------------начало добавленно для нового расчета по дням-------------------2007-01-17
			IF @add_type2 = 2
				AND @manual_sum = 0 --and @hours1<1
				AND (@service_id1 IN ('гвод', 'хвод', 'отоп', 'гвс2', 'ото2', 'тепл', 'гвсд'))
			BEGIN --@add_type2=2
				-------------------------------

				SET @KolDay = DAY(@data2) - DAY(@data1) + 1;
				-------------------------------

				SELECT @summa1 = p.Value - p.Discount
				FROM dbo.View_paym AS p 
				WHERE p.service_id = @service_id1
					AND p.occ = @occ1
					AND p.fin_id = @fin_id1
					AND p.sup_id = @sup_id;

				SET @summa2 = @summa1;
				IF (@summa1 IS NULL)
					OR (@summa1 < 0)
					SET @summa1 = 0;

				SET @comments = dbo.FSTR(@summa1, 15, 4) + '/30.44*' + LTRIM(STR(@factor)) + '*' + LTRIM(STR(@KolDay));
				SET @summa1 = (@summa1 / 30.44) * @factor * @KolDay;

				IF @summa1 * @factor > @summa2
					SET @summa1 = @summa2 * @factor;
				--if @summa1<>0
				GOTO label_write; -- идем на запись
			END; --@add_type2=2

			IF @add_type2 = 3
				AND @manual_sum = 0
				AND (@service_id1 IN ('гвод', 'хвод', 'отоп', 'гвс2', 'ото2', 'тепл', 'гвсд'))
			BEGIN --@add_type2=3
				-------------------------------

				SET @KolDay = DAY(@data2) - DAY(@data1) + 1;
				-------------------------------
				SELECT @summa1 = p.Value - p.Discount
				FROM dbo.View_paym AS p
				WHERE p.service_id = @service_id1
					AND p.occ = @occ1
					AND p.fin_id = @fin_id1
					AND p.sup_id = @sup_id;

				IF (@summa1 IS NULL)
					OR (@summa1 < 0)
					SET @summa1 = 0;
				SET @summa2 = @summa1;
				---------------------------------

				SET @comments = dbo.FSTR(@summa1, 15, 4) + '/30.44*' + LTRIM(STR(@factor)) + '*' + LTRIM(STR(@KolDay));
				SET @summa1 = (@summa1 / 30.44) * @factor * @KolDay;

				IF @summa1 * @factor > @summa2
					SET @summa1 = @summa2 * @factor;
				IF @summa1 <> 0
					GOTO label_write; -- идем на запись
			END; --@add_type2=3
			--------------------конец добавленно для нового расчета по дням-------------2007-01-17

			IF NOT EXISTS (
					SELECT 1
					FROM dbo.Global_values
					WHERE fin_id = @fin_id1
				)
			BEGIN
				SELECT @fin_id1 = @fin_current;
			END;

			SELECT @AddGvrProcent1 = AddGvrProcent
				 , @AddGvrDays1 = AddGvrDays
				 , @AddOtpProcent1 = AddOtpProcent
			FROM dbo.Global_values 
			WHERE fin_id = @fin_id1;

			--***************************

			DECLARE @str1 VARCHAR(300);
			SET @str1 = ', ' + LTRIM(STR(@fin_id1)) + ',2,''' +
			CONVERT(VARCHAR(8), @data1, 112) + ''',''' + CONVERT(VARCHAR(8), @data2, 112) + '''';

			IF @service_id1 IN ('отоп', 'ото2', 'гвод', 'гвс2', 'тепл', 'гвсд')
				SET @str1 = @str1 + ', ' + LTRIM(STR(@tnorm1)) + ',' + LTRIM(STR(@tnorm2));

			SET @str1 = 'k_raschet_1  ' + LTRIM(STR(@occ1)) + @str1;

			IF @mode_history = 1
				SET @str1 = @str1 + ' ,@mode_history=1 ';

			EXEC (@str1); -- делаем перерасчет
			--SET @comments = @str1

			SELECT @summa1 = pa.Value - COALESCE(ph.Discount, 0) -- 22/03/2010    ---compens 13/11/2007
			FROM dbo.Paym_add AS pa
				LEFT JOIN dbo.Paym_history AS ph 
					ON pa.occ = ph.occ
					AND pa.service_id = ph.service_id
					AND ph.fin_id = @fin_id1
					AND pa.sup_id = ph.sup_id
			WHERE pa.occ = @occ1
				AND pa.service_id = @service_id1
				AND pa.sup_id = @sup_id;

			--  select * from paym_add where occ=@occ1 and service_id=@service_id1 

			IF (@summa1 IS NULL)
				OR (@summa1 < 0)
				SET @summa1 = 0;
			SET @summa1 = @summa1 * @factor;

			IF @summa1 <> 0
			BEGIN
			--IF @service_id1 in ('гвод','гвс2') убрал 22.05.13   
			--BEGIN
			--  SET @Sum1=@AddGvrDays1/12 -- 1,17
			--  SET @Sum1=30-@Sum1  -- 28,83
			--  SET @summa1=(@summa1*@sum1)/30
			--END

			label_write:;
				--  set @summa1=@summa1*@tnorm2/@tnorm1
				--  print  str(@summa1,10,4)+' '+str(@tnorm1,10,4)+' '+str(@tnorm2,10,4)
				DECLARE @user_edit1 SMALLINT;
				SELECT @user_edit1 = dbo.Fun_GetCurrentUserId();

				IF @tnorm2 = 0
					SET @tnorm2 = NULL;

				BEGIN TRAN;

				-- Добавить в таблицу added_payments
				INSERT INTO dbo.Added_Payments (occ
											  , service_id
											  , sup_id
											  , add_type
											  , doc
											  , Value
											  , data1
											  , data2
											  , Hours
											  , add_type2
											  , manual_bit
											  , doc_no
											  , doc_date
											  , Vin1
											  , Vin2
											  , user_edit
											  , fin_id_paym
											  , comments
											  , tnorm2
											  , fin_id)
				VALUES(@occ1
					 , @service_id1
					 , @sup_id
					 , @add_type1
					 , @doc1
					 , @summa1
					 , @data1
					 , @data2
					 , @hours1
					 , @add_type2
					 , @manual_bit
					 , @doc_no1
					 , @doc_date1
					 , @vin1
					 , @vin2
					 , @user_edit1
					 , @fin_id1
					 , @comments
					 , @tnorm2
					 , @fin_current);

				-- Изменить значения в таблице paym_list
				UPDATE pl
				SET added = COALESCE(t_add.val, 0), kol_added = COALESCE(t_add.kol,0)
				FROM dbo.Paym_list AS pl
					CROSS APPLY (SELECT SUM(ap.value) as val, sum(coalesce(ap.kol,0)) AS kol
						FROM dbo.Added_Payments ap 
						WHERE ap.occ = pl.occ
							AND ap.service_id = pl.service_id
							AND ap.fin_id = pl.fin_id
							AND ap.sup_id = pl.sup_id) AS t_add
				WHERE pl.occ = @occ1
					AND pl.fin_id = @fin_current;

				SET @addyes = 1; -- добавление разового прошло успешно

				COMMIT TRAN;
			END; --  if @summa1<>0
		END; --по старой формуле  
	END; --if  (@add_type1=8)

	-- сохраняем в историю изменений
	EXEC k_write_log @occ1 = @occ1
				   , @oper1 = 'раз!';
go

