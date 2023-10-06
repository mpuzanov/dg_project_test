CREATE   PROCEDURE [dbo].[ka_add_added_2]
(
	  @occ1 INT -- лицевой счет 
	, @service_id1 VARCHAR(10) -- код услуги
	, @add_type1 INT -- тип разового
	, @doc1 VARCHAR(100) -- документ
	, @fin_id1 SMALLINT -- Фин. период
	, @data1 DATETIME -- с этого дня услуги нет 
	, @data2 DATETIME -- по этот день
	, @group1 BIT = 0 -- 1 - групповое изменение (не выводим ошибок на экран)
	, @znak1 BIT = 0 -- 0 то разовае со знаком "-" если 1 то "+"
	, @tarif_minus1 DECIMAL(9, 4) = 0
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @vin1 INT = NULL -- виновник1 (участок)
	, @vin2 INT = NULL -- виновник2 (поставщик услуги)
	, @mode_history BIT = 0 -- при перерасчетах режимы брать из истории
	, @hours1 SMALLINT = 0
	, @manual_sum DECIMAL(9, 2) = 0
	, @addyes BIT = 0 OUTPUT -- если 1 то разовые добавили
	, @total_sq_new DECIMAL(10, 4) = NULL
	, @add_votv_auto BIT = 0 -- автоматический расчет разовых по водоотведению
	, @not_counter_ras BIT = 0 -- не рассчитывать по счётчикам
	, @debug BIT = 0
	, @strOut VARCHAR(100) = '' OUTPUT
	, @sup_id INT = NULL
	, @KolDayFinPeriod SMALLINT = NULL -- Колличество дней в фин. периоде (когда надо рассчитать за период в котором мы не считали)
)
AS
	/*
		
	Ввод разовых  "недопоставка услуги" тип - 1 
	
	
	@tarif_minus1 используется при расчете значения за содержания жилья
	выделяется сумма если бы тариф был = @tarif_minus1
	
	
	declare @addyes bit
	exec dbo.ka_add_added_2 @occ1=326036, @service_id1='Конс', @add_type1=1, @doc1='doc', @fin_id1=141, 
	@data1='20131001',@data2='20131013',
	@group1=0,@znak1=0,@tarif_minus1=0,@doc_no1=null,@doc_date1=null,@vin1=null,@vin2=null, 
	@mode_history=0,@hours1=0,@manual_sum=0, @addyes=@addyes OUTPUT, @debug=0
	
	
	 -- уменьшение тарифа
	declare @addyes bit  
	exec dbo.ka_add_added_2 297484, 'гвод', 1, 'doc', 108, '20110101','20110130',
	0,0,147.57,111,null,null,null, 0,0,0, @addyes OUTPUT
	
	declare @addyes bit
	exec dbo.ka_add_added_2 177986, 'лифт', 1, 'doc', 86, '20090322','20090322',
	0,0,0.245,null,null,null,null, 1,0,0, @addyes OUTPUT
	
	*/

	SET NOCOUNT ON;

	IF @debug = 1
	BEGIN
		DECLARE @exec_string VARCHAR(2000)=''
		SET @exec_string=CONCAT('EXEC ka_add_added_2 @occ1=',@occ1,', @service_id1=''',@service_id1,''', @add_type1=',@add_type1,', @doc1=''',@doc1,''', @fin_id1=',@fin_id1,', @debug=1')
		SET @exec_string=@exec_string+CONCAT(', @data1=''',CONVERT(VARCHAR(8), @data1, 112),''', @data2=''',CONVERT(VARCHAR(8), @data2, 112),''', @add_votv_auto=', @add_votv_auto) 
		SET @exec_string=@exec_string+', @addyes=@addyes OUTPUT, @strOut=@strOut OUTPUT;'
		PRINT '=================================================='
		PRINT 'DECLARE @addyes BIT=0'
		PRINT 'DECLARE @strOut VARCHAR(100);'
		PRINT @exec_string
		PRINT 'SELECT @addyes as addyes, @strOut AS strOut;'
		PRINT '=================================================='
	END

	DECLARE @fin_current SMALLINT
		  , @KolDayAdd SMALLINT
		  , @comments VARCHAR(50) = NULL		  
		  , @tar1 DECIMAL(10, 4); -- Тариф по услуге по заданному фин.периоду

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);

	SET @addyes = 0;

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

	IF COALESCE(@KolDayFinPeriod, 0) = 0
	BEGIN
		DECLARE @Start_date SMALLDATETIME -- Начальная дата финансового  периода
			  , @End_date SMALLDATETIME -- Конечная  дата финансового  периода	

		SELECT @Start_date = [start_date]
			 , @End_date = end_date
		FROM dbo.Global_values 
		WHERE fin_id = @fin_id1;

		SELECT @KolDayFinPeriod = DATEDIFF(DAY, @Start_date, DATEADD(MONTH, 1, @Start_date))
	END

	SELECT @KolDayAdd = DATEDIFF(DAY, @data1, @data2) + 1;

	IF @debug = 1
		SELECT @KolDayFinPeriod AS KolDayFinPeriod
			 , @KolDayAdd AS KolDayAdd
			 , @manual_sum AS manual_sum
			 , @doc_no1 AS doc_no
			 , @mode_history AS mode_history
			 , @data1 AS data1
			 , @data2 AS data2
			 , @add_votv_auto AS add_votv_auto

	IF @vin1 = 0
		SET @vin1 = NULL;
	IF @znak1 IS NULL
		SET @znak1 = 0
	IF @vin2 = 0
		SET @vin2 = NULL;
	IF @debug IS NULL
		SET @debug = 0;

	IF @sup_id IS NULL
		SELECT @sup_id = dbo.Fun_GetSup_idOcc(@occ1, @service_id1)

	DECLARE @factor SMALLINT
		  , @summa1 DECIMAL(15, 4)
		  , @Sum1 DECIMAL(15, 4)
		  , @AddGvrProcent1 DECIMAL(10, 4)
		  , @AddOtpProcent1 DECIMAL(10, 4)
		  , @AddGvrDays1 DECIMAL(10, 4)
		  , @kol_add DECIMAL(12,6);

	SET @factor =
				 CASE
					 WHEN @znak1 = 0 THEN -1
					 ELSE 1
				 END;

	IF @not_counter_ras IS NULL
		SET @not_counter_ras = 0;

	IF (@hours1 IS NULL)
		OR (@hours1 < 0)
		SET @hours1 = 0;

	-- Проверяем есть ли такая услуга на этом лицевом
	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Consmodes_list AS cl 
			WHERE cl.occ = @occ1
				AND cl.service_id = @service_id1
				AND cl.sup_id = @sup_id
				AND (cl.mode_id % 1000) != 0
		)
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.View_consmodes_all AS cl
			WHERE cl.occ = @occ1
				AND cl.fin_id = @fin_id1
				AND cl.service_id = @service_id1
				AND cl.sup_id = @sup_id
				AND (cl.mode_id % 1000) != 0
		)
	BEGIN

		IF @group1 = 0
			OR @debug = 1
			RAISERROR ('У лицевого %d нет режима потребления по услуге: %s ', 16, 1, @occ1, @service_id1);

		RETURN;
	END;

	DECLARE @user_edit SMALLINT;
	SELECT @user_edit = dbo.Fun_GetCurrentUserId();

	--*******************************************************************
	DECLARE @manual_bit BIT = 0


	IF @manual_sum <> 0 -- ПРОВЕРЯЕМ РУЧНОЙ ВВОД СУММЫ РАЗОВОГО
	BEGIN
		IF @debug = 1
			PRINT concat('Ручной ввод разового ' ,@manual_sum);
		SELECT @summa1 = @manual_sum;
		SET @manual_bit = 1;
		GOTO label_write; -- сразу идем на запись
	END;
	ELSE
		SET @manual_sum = 0;


	--*******************************************************************

	-- Проверяем есть ли счетчик в том месяце по которому проводяться разовые если начислили по норме то пропускаем
	IF @not_counter_ras = 1 -- 22.01.2015 ,было 0 поставил 1
		AND EXISTS (
			SELECT 1
			FROM dbo.View_paym AS vp
			WHERE vp.occ = @occ1
				AND vp.fin_id = @fin_id1
				AND vp.service_id = @service_id1
				AND vp.sup_id = @sup_id
				--AND cl.is_counter IN (1, 2)
				AND vp.metod IN (3, 4)
		)  -- по счётчику или по домовому
	BEGIN

		IF @group1 = 0
			RAISERROR ('У лицевого %d начисленно по счетчику по этой услуге в заданном месяце', 16, 1, @occ1);
		ELSE
			RAISERROR ('У лицевого %d начисленно по счетчику по этой услуге в заданном месяце', 10, 1, @occ1) WITH NOWAIT;

		RETURN;
	END;

	IF @not_counter_ras = 1
		AND EXISTS (
			SELECT 1
			FROM dbo.View_paym AS vp
			WHERE vp.occ = @occ1
				AND vp.fin_id = @fin_id1
				AND vp.service_id = @service_id1
				AND vp.sup_id = @sup_id
				AND vp.is_counter IN (1, 2)
		)
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.View_counter_all_lite c
			WHERE c.fin_id = @fin_id1
				AND c.occ = @occ1
				AND c.service_id = @service_id1
				AND c.date_del IS NULL
				AND c.KolmesForPeriodCheck < 0
		)  -- нет ПУ с истёкшим сроком поверки
	BEGIN

		IF @group1 = 0
			RAISERROR ('У лицевого %d счетчик по этой услуге в заданном месяце', 16, 1, @occ1);
		ELSE
			RAISERROR ('У лицевого %d счетчик по этой услуге в заданном месяце', 10, 1, @occ1) WITH NOWAIT;

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
				AND cl.is_counter IN (1, 2)
		)
	BEGIN

		IF @group1 = 0
			RAISERROR ('У лицевого %d счетчик по этой услуге в заданном месяце', 16, 1, @occ1);

		RETURN;
	END;

	--*******************************************************************
	IF @hours1 > 0
		AND @manual_sum = 0
		AND (@service_id1 IN ('хвод', 'хвпк', 'хвсд', 'гвод', 'гвпк', 'гвсд', 'вотв', 'вопк', 'элек', 'пгаз', 'отоп', 'гвс2', 'ото2', 'тепл'))
	BEGIN
		IF @debug = 1
			PRINT 'пересчёт по часам';
		SET @strOut = 'пересчёт по часам';
		DECLARE @summa2 MONEY;

		SELECT @summa1 = p.value - p.discount, @tar1 = p.tarif
		FROM dbo.View_paym AS p
		WHERE p.service_id = @service_id1
			AND p.occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.sup_id = @sup_id;

		IF (@summa1 IS NULL)
			OR (@summa1 < 0)
			SET @summa1 = 0;

		SET @summa2 = @summa1;
		SET @comments = concat(dbo.NSTR(@summa1) , '*' , @hours1 , '*0,0015*' , @factor);
		SET @summa1 = @summa1 * @hours1 * 0.0015 * @factor;

		IF @summa1 * @factor > @summa2
		BEGIN
			SET @summa1 = @summa2 * @factor;
			SET @comments = 'возвращаем полное начисление';
		END;

		SET @kol_add = @summa1 / @tar1

		IF (@summa1 <> 0) OR (@kol_add<>0)
		BEGIN --@summa1<>0
						
			BEGIN TRAN;

			-- Добавить в таблицу added_payments
			INSERT INTO dbo.Added_Payments
				(occ
			   , service_id
			   , sup_id
			   , add_type
			   , doc
			   , value
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
			   , kol)
				VALUES (@occ1
					  , @service_id1
					  , @sup_id
					  , @add_type1
					  , @doc1
					  , @summa1
					  , @data1
					  , @data2
					  , @hours1
					  , NULL
					  , @manual_bit
					  , @doc_no1
					  , @doc_date1
					  , @vin1
					  , @vin2
					  , @user_edit
					  , @fin_id1
					  , @comments
					  , @kol_add);

			-- Изменить значения в таблице paym_list
			UPDATE dbo.Paym_list
			SET added = COALESCE((
				SELECT SUM(value)
				FROM dbo.Added_Payments ap
				WHERE occ = @occ1
					AND service_id = pl.service_id
					AND fin_id = @fin_current
					AND ap.sup_id = pl.sup_id
			), 0)
			FROM dbo.Paym_list AS pl
			WHERE occ = @occ1
				AND fin_id = @fin_current
				AND pl.sup_id = @sup_id;

			SET @addyes = 1; -- добавление разового прошло успешно

			COMMIT TRAN;
		END; --@summa1<>0

	END --пересчёт по часам
	ELSE
	BEGIN
		IF @debug = 1
			PRINT 'по старой формуле';
		SET @strOut = 'по старой формуле';
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
		DECLARE @str1 VARCHAR(1024)
			  , @added SMALLINT = 2
		IF @fin_id1 = @fin_current
			SET @added = 0

		--SET @str1 = +',2,''' + CONVERT(VARCHAR(8), @data1, 112) + ''',''' + CONVERT(VARCHAR(8), @data2, 112) + ''''
		SET @str1 = +CONCAT(' ',@added,',''',CONVERT(VARCHAR(8), @data1, 112),''',''',CONVERT(VARCHAR(8), @data2, 112),'''')
		--SET @str1 = 'k_raschet_1 ' + LTRIM(STR(@occ1)) + ', ' + LTRIM(STR(@fin_id1)) + @str1 + ' ,@People_list=1, @debug=' + LTRIM(STR(@debug));
		SET @str1 = CONCAT('k_raschet_2 ',@occ1,', ',@fin_id1,', ',@str1,', @People_list=1, @debug=', @debug)

		IF @mode_history = 1
			SET @str1 = concat(@str1 , ' ,@mode_history=1');

		IF @total_sq_new > 0
		BEGIN
			SET @str1 = concat(@str1 , ', @total_sq_new=' + @total_sq_new);
			SET @comments = concat('На площадь: ' , @total_sq_new);
		END;

		--print @str1			
		IF @debug = 1
			PRINT @str1;
		EXEC (@str1); -- делаем перерасчет

		SET @strOut = SUBSTRING(@str1, 1, 100);

		IF @debug = 1
			SELECT 'PAYM_ADD' as tbl
				 , *
			FROM dbo.Paym_add
			WHERE occ = @occ1
				AND service_id = @service_id1
				AND sup_id = @sup_id;

		SELECT @summa1 = CASE
							WHEN @doc_no1='889' AND @service_id1='отоп' AND ph.kol_norma IS NOT NULL THEN pa.tarif*ph.kol_norma
							ELSE pa.value 
						END
		FROM dbo.Paym_add AS pa
			LEFT JOIN dbo.View_paym AS ph ON pa.occ = ph.occ
				AND pa.service_id = ph.service_id
				AND ph.fin_id = @fin_id1
				AND ph.sup_id = pa.sup_id
		WHERE pa.occ = @occ1
			AND pa.service_id = @service_id1
			AND pa.sup_id = @sup_id;

		IF @debug = 1 select @summa1 AS summa1

		IF (@summa1 IS NULL)
			OR (@summa1 < 0)
			SET @summa1 = 0;

		-- Находим сами пропорцию и берём из истории начислений
		IF @service_id1 IN ('хвпк', 'гвпк', 'вопк')
			OR @mode_history = 1
		BEGIN
			IF @debug = 1
				PRINT 'берём сумму из таблицы начислений';

			SELECT @summa1 = CASE
							WHEN @doc_no1='889' AND @service_id1='отоп' AND p.kol_norma IS NOT NULL THEN p.tarif*p.kol_norma
							ELSE p.value 
						END
				 , @tar1 = p.tarif
				 , @kol_add = p.kol
			FROM dbo.View_paym AS p 
			WHERE p.service_id = @service_id1
				AND p.occ = @occ1
				AND p.fin_id = @fin_id1
				AND p.sup_id = @sup_id;

			IF (@summa1 IS NULL)
				OR (@summa1 < 0)
				SET @summa1 = 0;

			SET @summa2 = @summa1;
			SET @comments = concat(dbo.nSTR(@summa1) , '*' , @KolDayAdd , '/' , @KolDayFinPeriod);
			SET @summa1 = @summa1 * @KolDayAdd / @KolDayFinPeriod;
			
			IF @debug = 1
				PRINT concat(@comments , ' =' , @summa1)

			IF @summa1 > @summa2
			BEGIN
				SET @summa1 = @summa2;
				IF @summa1 < 0
					SET @comments = 'возвращаем полное начисление'
				ELSE
					SET @comments = 'доначисляем полное начисление';
			END;

		END;

		SET @summa1 = @summa1 * @factor;

		--PRINT @summa1
		if @summa1<>0
			SET @kol_add = @summa1 / @tar1
		ELSE
			SET @kol_add = @kol_add * @KolDayAdd / @KolDayFinPeriod;
		if @debug=1 select @kol_add AS kol_add

		IF (@summa1 <> 0) OR (@kol_add<>0)
		BEGIN			

			--IF @service_id1 IN ('гвод', 'гвс2')  убрал 22.05.13   
			--BEGIN
			--	SET @Sum1 = @AddGvrDays1 / 12 -- 1,17
			--	SET @Sum1 = 30 - @Sum1 -- 28,83
			--	SET @summa1 = (@summa1 * @sum1) / 30
			--END

			IF (@tarif_minus1 > 0) --and (@service_id1 in ('площ','лифт','гвод') )  -- 27/02/2010
			BEGIN
				--print @tarif_minus1

				IF @tar1 IS NULL
					SET @tar1 = 0;

				IF @debug = 1
				BEGIN
					PRINT @tarif_minus1;
					PRINT @tar1;
					PRINT @summa1;
				END;

				--IF @tar1 > @tarif_minus1
				IF (@tar1 + (@factor * @tarif_minus1)) > 0
					AND (@tar1 > 0)
				BEGIN
					SET @comments = '(' + dbo.NSTR(@tarif_minus1) + '*' + dbo.NSTR(@summa1) + ')/' + dbo.NSTR(@tar1);
					SET @Sum1 = @tarif_minus1 * @summa1;
					SET @summa1 = @Sum1 / @tar1;
					IF @debug = 1
						PRINT 'Разовые: ' + dbo.NSTR(@summa1);
					SET @kol_add=@summa1/@tar1
				END; -- if @tar1>@tarif_minus1
				ELSE
					SET @comments = concat('Новый тариф не должен быть <0 .' , dbo.Fun_NameFinPeriod(@fin_id1));
			--ELSE
			--	SET @comments = 'Сумма изм.тарифа > тарифа за ' + dbo.Fun_NameFinPeriod(@fin_id1)

			END; --if (@service_id1='площ') and (@tarif_minus1>0)

		--  print str(@summa1,15,2)


		label_write:;
						
			BEGIN TRAN;

			-- Добавить в таблицу added_payments
			INSERT INTO dbo.Added_Payments
				(occ
			   , service_id
			   , sup_id
			   , add_type
			   , doc
			   , value
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
			   , kol)
				VALUES (@occ1
					  , @service_id1
					  , @sup_id
					  , @add_type1
					  , @doc1
					  , @summa1
					  , @data1
					  , @data2
					  , @hours1
					  , NULL
					  , @manual_bit
					  , @doc_no1
					  , @doc_date1
					  , @vin1
					  , @vin2
					  , @user_edit
					  , @fin_id1
					  , @comments
					  , @kol_add);

			-- Изменить значения в таблице paym_list
			UPDATE pl
			SET added = COALESCE(t_add.val, 0), kol_added = COALESCE(t_add.kol,0)
			FROM dbo.Paym_list AS pl
				CROSS APPLY (SELECT SUM(value) as val, sum(coalesce(ap.kol,0)) AS kol
					FROM dbo.Added_Payments ap
					WHERE occ = pl.occ
						AND service_id = pl.service_id
						AND fin_id = @fin_current
						AND ap.sup_id = pl.sup_id) AS t_add
			WHERE occ = @occ1
				AND fin_id = @fin_current
				AND pl.sup_id = @sup_id;

			SET @addyes = 1; -- добавление разового прошло успешно

			COMMIT TRAN;

			-- сохраняем в историю изменений
			EXEC k_write_log @occ1 = @occ1
						   , @oper1 = 'раз!';

		END; --  if @summa1<>0

	END; --по старой формуле   

	IF  @add_votv_auto = 1
		AND @add_type1 IN (1, 12)   --Недоп. услуги,Кор.по внутр. Счётчикам
		AND @service_id1 IN ('хвод', 'хвс2', 'гвод', 'гвс2')
		--AND @addyes = 1
	BEGIN
		-- автоматический расчёт водоотведения		
		IF @debug = 1
			PRINT 'автоматический расчёт водоотведения';

		DECLARE @sum_gvs DECIMAL(9, 2) = 0
			  , @norma_gvs DECIMAL(9, 4) = 0
			  , @sum_xvs DECIMAL(9, 2) = 0
			  , @norma_xvs DECIMAL(9, 4) = 0
			  , @sum_votv DECIMAL(9, 2) = 0
			  , @sum_add_votv DECIMAL(9, 2) = 0
			  , @serv_gvs VARCHAR(10)
			  , @tip_id SMALLINT
			  , @tarif_votv DECIMAL(10, 4)
			  , @kol_votv DECIMAL(12,6) = 0
			  , @koef_day DECIMAL(9,4) = 1

		-- находим сумму по вотв
		SELECT @sum_votv = SUM(value), @tarif_votv=max(pa.tarif), @kol_votv=SUM(kol), @koef_day = MIN(COALESCE(koef_day,1))
		FROM dbo.Paym_add pa
		WHERE occ = @occ1
			AND service_id IN ('вотв', 'вот2')
			AND pa.sup_id = @sup_id;

		IF @doc_no1='889' AND @kol_add<>0 AND @tarif_votv>0
		BEGIN
			if @debug=1 print 'нужен разовый по вотв только по услуге по которой делаем сейчас разовый'
			SELECT @sum_add_votv=@kol_add*@tarif_votv, @kol_votv=@kol_add
		END
		ELSE
		BEGIN
			-- находим сумму по гвс
			SELECT @sum_gvs = SUM(case when pa.service_id IN ('гвод', 'гвс2') then value else 0 end)
				 , @norma_gvs = SUM(case when pa.service_id IN ('гвод', 'гвс2') then kol else 0 end) 
				 , @sum_xvs = SUM(case when pa.service_id IN ('хвод', 'хвс2') then value else 0 end)
				 , @norma_xvs = SUM(case when pa.service_id IN ('хвод', 'хвс2') then kol else 0 end)
			FROM dbo.Paym_add AS pa
			WHERE pa.occ = @occ1
				AND pa.sup_id = @sup_id;

			-- водоотведение в текущем периоде возвращается без учета дней поэтому рассчитаем с коэф дней
			IF @fin_id1 = @fin_current
				AND (@sum_votv <> 0)
				SELECT @sum_votv = @sum_votv * @KolDayAdd / @KolDayFinPeriod

			if @debug=1
				SELECT @sum_gvs AS sum_gvs
				 , @norma_gvs AS norma_gvs
				 , @sum_xvs AS sum_xvs
				 , @norma_xvs AS norma_xvs
				 , @sum_votv AS sum_votv
				 , @sum_add_votv AS sum_add_votv
				 , @tarif_votv AS tarif_votv
				 , @kol_votv AS kol_votv
				 , @koef_day AS koef_day

			--IF @sum_gvs=0 SET @norma_gvs=0
			--IF @sum_xvs=0 SET @norma_xvs=0
			IF @norma_gvs IS NULL
				SET @norma_gvs = 0;
			IF @norma_xvs IS NULL
				SET @norma_xvs = 0;
			
			IF @sum_votv > 0
				AND @service_id1 IN ('гвод', 'гвс2')
			BEGIN
				IF @debug = 1 PRINT concat('Находим долю услуги ',@service_id1,' в общем объёме водоотведения')

				IF @sum_xvs = 0
					SET @sum_add_votv = @factor * @sum_votv;
				ELSE
					if @sum_gvs=0 and @norma_gvs>0 and @sum_votv<>0
					BEGIN
						SELECT @sum_add_votv = @factor * (@norma_gvs * @tarif_votv)
							, @kol_votv = @norma_gvs
					END
					ELSE
					BEGIN
						SELECT @sum_add_votv =
											  CASE
												  WHEN (@norma_gvs + @norma_xvs) = 0 THEN 0
												  WHEN @norma_gvs>0 THEN @factor * (@norma_gvs*@tarif_votv)
												  ELSE @factor * (@sum_votv * @norma_gvs) / (@norma_gvs + @norma_xvs)
											  END;

						IF @tarif_votv>0 AND @sum_add_votv<>0
							SELECT @kol_votv = @sum_add_votv/@tarif_votv
					END

				IF @sum_gvs=0
					SELECT @sum_add_votv = @sum_add_votv * @koef_day, @kol_votv= @kol_votv * @koef_day

				IF @debug = 1 PRINT concat(@service_id1 ,' @norma_gvs: ',@norma_gvs,' @norma_xvs:',@norma_xvs,' @koef_day:', @koef_day)
				IF @debug = 1 PRINT concat(@service_id1 ,' @sum_add_votv:', @sum_add_votv, ' @kol_votv:', @kol_votv)
			END;

			IF @sum_votv > 0
				AND @service_id1 IN ('хвод', 'хвс2')
			BEGIN
				IF @debug = 1 PRINT concat('Находим долю услуги ',@service_id1,' в общем объёме водоотведения')
				
				IF @sum_gvs = 0
					SET @sum_add_votv = @factor * @sum_votv;
				ELSE
					SELECT @sum_add_votv =
										  CASE
											  WHEN (@norma_gvs + @norma_xvs) = 0 THEN 0
											  WHEN @norma_xvs>0 THEN @factor * (@norma_xvs*@tarif_votv)
											  ELSE @factor * (@sum_votv * @norma_xvs) / (@norma_gvs + @norma_xvs)
										  END;

				IF @tarif_votv>0 AND @sum_add_votv<>0
					SELECT @kol_votv = @sum_add_votv/@tarif_votv

				IF @debug = 1 PRINT @service_id1 +' '+STR(@sum_add_votv,9,2)+' '+STR(@kol_votv,9, 4)
			END;
		END;

		IF @debug = 1
		BEGIN
			SELECT @sum_gvs AS sum_gvs
				 , @norma_gvs AS norma_gvs
				 , @sum_xvs AS sum_xvs
				 , @norma_xvs AS norma_xvs
				 , @sum_votv AS sum_votv
				 , @sum_add_votv AS sum_add_votv
				 , @tarif_votv AS tarif_votv
				 , @kol_votv AS kol_votv
				 , @koef_day AS koef_day
		END;

		IF @sum_add_votv <> 0
		BEGIN
			-- Добавить в таблицу added_payments
			INSERT INTO dbo.Added_Payments
				(occ
			   , service_id
			   , sup_id
			   , add_type
			   , doc
			   , value
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
			   , kol)
				VALUES (@occ1
					  , CASE
							WHEN @service_id1 IN ('хвс2', 'гвс2') THEN 'вот2'
							ELSE 'вотв'
						END
					  , @sup_id
					  , @add_type1
					  , @doc1
					  , @sum_add_votv
					  , @data1
					  , @data2
					  , @hours1
					  , NULL
					  , @manual_bit
					  , @doc_no1
					  , @doc_date1
					  , @vin1
					  , @vin2
					  , @user_edit
					  , @fin_id1
					  , CONCAT('авто расчёт (' , @service_id1 , ')')
					  , @kol_votv);

			-- Изменить значения в таблице paym_list
			UPDATE pl
			SET added = COALESCE(t_add.val, 0), kol_added = COALESCE(t_add.kol,0)
			FROM dbo.Paym_list AS pl
				CROSS APPLY (SELECT SUM(value) as val, sum(coalesce(ap.kol,0)) AS kol
					FROM dbo.Added_Payments ap 
					WHERE ap.occ = pl.occ
						AND ap.service_id = pl.service_id
						AND ap.fin_id = @fin_current
						AND ap.sup_id = pl.sup_id) AS t_add
			WHERE occ = @occ1
				AND fin_id = @fin_current
				AND pl.sup_id = @sup_id;

			SET @addyes = 1;
		END;

	END; -- IF @add_votv_auto=1 AND @service_id1 IN ('хвод','гвод','гвс2')
go

