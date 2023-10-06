-- =============================================
-- Author:		Пузанов
-- Create date: 14.09.2011
-- Description:	Перерасчеты (Техническая корректировка на дом)
-- Возврат начислений по домам за месяц
-- =============================================
CREATE       PROCEDURE [dbo].[ka_add_added_9]
(
	  @fin_id SMALLINT -- фин. период 
	, @id_str VARCHAR(8000) -- строка формата: код дома(лицевого);код дома
	, @serv_str VARCHAR(2000) -- строка формата: код услуги:код поставщика;код услуги:код поставщика
	, @doc1 VARCHAR(100) = '' -- документ (комментарий)
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @debug BIT = 0 -- показать отладочную информацию
	, @id_occ BIT = 0 -- если = 1 то в @id_str передаються лицевые счета иначе дома
	, @added_true BIT = 1 -- возврат с учётом разовых
	, @data1 SMALLDATETIME = NULL -- с этого дня 
	, @data2 SMALLDATETIME = NULL -- по этот день
	, @add_type1 SMALLINT = 2 -- тех.корректировка
	, @SummaItog DECIMAL(9, 2) = 0 OUTPUT-- Общая сумма возврата
	, @Znak SMALLINT = -1
	, @is_saldo BIT = 0 -- 1-Установить кон.сальдо в 0 (Добор или возврат сальдо)
)
AS
/*
DECLARE	@return_value int,
		@SummaItog decimal(9, 2)

EXEC	@return_value = [dbo].[ka_add_added_9]
		@fin_id = 237,
		@id_str = N'910003500',
		@serv_str = N'площ:0',
		@doc1 = N'тест',
		@doc_no1 = N'888',
		@debug = 1,
		@id_occ = 1,
		@data1 = '20211001',
		@data2 = '20211031',
		@SummaItog = @SummaItog OUTPUT,
		@Znak=1

SELECT	@SummaItog as N'@SummaItog'

SELECT	'Return Value' = @return_value
*/
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @fin_current SMALLINT
		  , @total_sq_bldn MONEY
		  , @kol_people_bldn INT
		  , @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @kol_day_fin TINYINT  -- кол-во дней в фин.периоде
		  , @sup_id INT
		  , @mode_history BIT = 1

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF @Znak IS NULL
		SET @Znak = -1

	IF @add_type1 IS NULL
		SET @add_type1 = 2

	-- Таблица с новыми значениями 
	DECLARE @t_id TABLE (
		  id INT
	)

	INSERT INTO @t_id
	SELECT *
	FROM STRING_SPLIT(@id_str, ';')
	WHERE RTRIM(Value) <> ''

	-- Таблица с услугами
	DECLARE @t_serv TABLE (
		  id VARCHAR(10)
		, sup_id INT DEFAULT NULL
	)
	IF dbo.strpos(':', @serv_str) > 0
	BEGIN
		INSERT INTO @t_serv
			(id
		   , sup_id)
		SELECT id
			 , CAST(val AS INT)
		FROM dbo.Fun_split_IdValue(@serv_str, ';')
		WHERE val > ''
	END
	ELSE
	BEGIN
		INSERT INTO @t_serv
			(id)
		SELECT *
		FROM STRING_SPLIT(@serv_str, ';')
	END

	DECLARE @t TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, sup_id INT DEFAULT 0
		, summa DECIMAL(9, 2) DEFAULT 0
		, is_counter TINYINT DEFAULT 0
		, fin_current SMALLINT
	--,debt			DECIMAL(9, 2)	DEFAULT 0
	)

	SELECT @SummaItog = 0
		 , @start_date = gv.start_date
		 , @end_date = gv.end_date
		 , @kol_day_fin = gv.KolDayFinPeriod
	FROM dbo.Global_values gv
	WHERE gv.fin_id = @fin_id

	IF @id_occ = 0
	BEGIN -- отбираем по домам		
		INSERT INTO @t
			(occ
		   , service_id
		   , summa
		   , is_counter
		   , sup_id)
		SELECT o.occ
			 , p.service_id
			 , CASE
				   WHEN @is_saldo = 1 THEN (p.Debt - p.Paid)
				   WHEN @added_true = 0 THEN p.Value
				   ELSE p.Paid
			   END
			 , is_counter = COALESCE(p.is_counter, 0)
			 , p.sup_id
		FROM @t_id AS t
			JOIN dbo.View_occ_all_lite AS o ON t.id = o.bldn_id
			JOIN dbo.View_paym AS p ON o.occ = p.occ
				AND o.fin_id = p.fin_id
		WHERE o.fin_id = @fin_id
			AND o.status_id <> 'закр'
			AND EXISTS (
				SELECT 1
				FROM @t_serv
				WHERE id = p.service_id
			)
	END
	ELSE
	BEGIN -- отбираем по лицевым
		INSERT INTO @t
			(occ
		   , service_id
		   , summa
		   , is_counter
		   , sup_id)
		SELECT o.occ
			 , p.service_id
			 , CASE
				   WHEN @is_saldo = 1 THEN (p.Debt - p.Paid)
				   WHEN @added_true = 0 THEN p.Value
				   ELSE p.Paid
			   END
			 , is_counter = COALESCE(p.is_counter, 0)
			 , p.sup_id
		FROM @t_id AS t
			JOIN dbo.View_occ_all_lite AS o ON t.id = o.occ
			JOIN dbo.View_paym AS p ON o.occ = p.occ
				AND o.fin_id = p.fin_id
		WHERE o.fin_id = @fin_id
			AND o.status_id <> 'закр'
			AND EXISTS (
				SELECT 1
				FROM @t_serv
				WHERE id = p.service_id
			)
		IF NOT EXISTS (SELECT * FROM @t)
			AND @Znak > 0
		BEGIN
			INSERT INTO @t
				(occ
			   , service_id
			   , summa
			   , is_counter
			   , sup_id)
			SELECT t.id
				 , s.id
				 , 0
				 , 0
				 , s.sup_id
			FROM @t_id AS t
			   , @t_serv s

			SET @mode_history = 0
		END
	END

	UPDATE @t
	SET fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, occ)

	IF @debug = 1
	BEGIN
		SELECT 'отобрали для расчета'
			 , *
			 , @mode_history AS mode_history
			 , @Znak AS Znak
			 , @fin_id AS fin_id
		FROM @t

		SELECT *
		FROM @t_serv
	END

	DECLARE @user_edit1 SMALLINT
		  , @comments VARCHAR(50)

	SELECT @user_edit1 = dbo.Fun_GetCurrentUserId()

	IF @data1 IS NULL
		SET @data1 = @start_date
	IF @data2 IS NULL
		SET @data2 = @end_date

	DECLARE @occ1 INT
		  , @service_id VARCHAR(10)
		  , @addyes BIT
	DECLARE @str1 VARCHAR(500)
		  , @summa1 DECIMAL(9, 2)
		  , @value DECIMAL(9, 2)
	DECLARE @sum_add DECIMAL(9, 2)
		  , @kolday_add TINYINT = 0
		  , @kolday_fin TINYINT

	IF (DATEDIFF(DAY, @data1, @data2) + 1) = @kol_day_fin
	BEGIN
		IF @debug = 1
			PRINT 'Возврат за весь месяц'

		IF @is_saldo = 0
		BEGIN
			IF @Znak > 0
				SET @comments = 'Добор начисл. за ' + dbo.Fun_NameFinPeriod(@fin_id)
			ELSE
				SET @comments = 'Возврат за ' + dbo.Fun_NameFinPeriod(@fin_id)
		END
		ELSE
		BEGIN
			SET @comments = 'Возврат(добор) сальдо за ' + dbo.Fun_NameFinPeriod(@fin_id)
		END

		BEGIN TRAN

		UPDATE @t
		SET summa = CASE
                        WHEN @is_saldo = 1 THEN summa * -1
                        ELSE @Znak * summa
            END
		WHERE summa <> 0

		-- Добавить в таблицу added_payments
		INSERT INTO dbo.Added_Payments
			(occ
		   , service_id
		   , sup_id
		   , add_type
		   , doc
		   , Value
		   , doc_no
		   , doc_date
		   , user_edit
		   , fin_id_paym
		   , comments
		   , fin_id)
		SELECT occ
			 , service_id
			 , sup_id
			 , @add_type1
			 , @doc1
			 , summa AS value
			 , @doc_no1
			 , @doc_date1
			 , @user_edit1
			 , @fin_id
			 , @comments
			 , fin_current
		FROM @t
		WHERE summa <> 0

		SELECT @SummaItog = SUM(summa)
		FROM @t

		IF @SummaItog = 0
			AND @Znak = 1
		BEGIN
			DECLARE curs CURSOR LOCAL FOR
				SELECT occ
					 , service_id
					 , fin_current
					 , sup_id
				FROM @t
			OPEN curs
			FETCH NEXT FROM curs INTO @occ1, @service_id, @fin_current, @sup_id

			WHILE (@@fetch_status = 0)
			BEGIN
				SELECT @summa1 = 0
					 , @sum_add = 0
					 , @value = 0

				IF @debug = 1
					PRINT 'при доборе делаем новый расчет'
				SET @str1 = +',2,''' + CONVERT(VARCHAR(8), @data1, 112) + ''',''' + CONVERT(VARCHAR(8), @data2, 112) + ''''
				SET @str1 = 'k_raschet_2 ' + LTRIM(STR(@occ1)) + ', ' + LTRIM(STR(@fin_id)) + @str1 + ', @People_list=1'
				IF @mode_history = 1
					SET @str1 = @str1 + ' ,@mode_history=1'
				IF @debug = 1
					SET @str1 = @str1 + ', @debug=1'
				IF @debug = 1
					PRINT @str1
				EXEC (@str1) -- делаем расчет
				IF @debug = 1
					SELECT *
					FROM dbo.Paym_add
					WHERE occ = @occ1
						AND service_id = @service_id

				SELECT @summa1 = pa.Value
				FROM dbo.Paym_add AS pa
				WHERE pa.occ = @occ1
					AND pa.service_id = @service_id
					AND pa.sup_id = @sup_id

				IF @summa1 <> 0
				BEGIN
					SELECT @SummaItog = @SummaItog + @summa1

					INSERT INTO dbo.Added_Payments
						(occ
					   , service_id
					   , sup_id
					   , add_type
					   , doc
					   , Value
					   , data1
					   , data2
					   , doc_no
					   , doc_date
					   , user_edit
					   , fin_id_paym
					   , comments
					   , fin_id)
						VALUES (@occ1
							  , @service_id
							  , @sup_id
							  , @add_type1
							  , @doc1
							  , @summa1
							  , @data1
							  , @data2
							  , @doc_no1
							  , @doc_date1
							  , @user_edit1
							  , @fin_id
							  , @comments
							  , @fin_current)

				END

				FETCH NEXT FROM curs INTO @occ1, @service_id, @fin_current, @sup_id
			END

			CLOSE curs
			DEALLOCATE curs

		END

		COMMIT TRAN

	END

	ELSE
	BEGIN -- Возврат по датам
		IF @debug = 1
			PRINT 'Возврат по датам'

		SELECT @kolday_add = DATEDIFF(DAY, @data1, @data2) + 1
		SELECT @kolday_fin = DATEDIFF(DAY, start_date, end_date) + 1
		FROM dbo.Global_values 
		WHERE fin_id = @fin_id

		IF @debug = 1
			PRINT '@kolday_add=' + STR(@kolday_add) + ' ,@kolday_fin=' + STR(@kolday_fin)

		DECLARE curs CURSOR LOCAL FOR
			SELECT occ
				 , service_id
				 , fin_current
				 , sup_id
			FROM @t
		OPEN curs
		FETCH NEXT FROM curs INTO @occ1, @service_id, @fin_current, @sup_id

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT @summa1 = 0
				 , @sum_add = 0
				 , @value = 0

			SELECT @sum_add = COALESCE(Added, 0)
				 , @value = COALESCE(Value, 0)
			FROM dbo.View_paym AS p
			WHERE occ = @occ1
				AND fin_id = @fin_id
				AND service_id = @service_id
				AND p.sup_id = @sup_id

			IF @Znak <= 0
			BEGIN
				SET @summa1 = @value
				SELECT @summa1 = (@summa1 * @kolday_add) / @kolday_fin
				SET @comments = 'Возврат начисл. c ' + CONVERT(VARCHAR(10), @data1, 104) + ' по ' + CONVERT(VARCHAR(10), @data2, 104)
			END
			ELSE
			BEGIN
				SET @comments = 'Добор начисл. c ' + CONVERT(VARCHAR(10), @data1, 104) + ' по ' + CONVERT(VARCHAR(10), @data2, 104)

				-- при доборе делаем новый расчет
				SET @str1 = +',2,''' + CONVERT(VARCHAR(8), @data1, 112) + ''',''' + CONVERT(VARCHAR(8), @data2, 112) + ''''
				SET @str1 = 'k_raschet_2 ' + LTRIM(STR(@occ1)) + ', ' + LTRIM(STR(@fin_id)) + @str1 + ', @People_list=1'
				IF @mode_history = 1
					SET @str1 = @str1 + ' ,@mode_history=1'
				IF @debug = 1
					SET @str1 = @str1 + ', @debug=1'
				IF @debug = 1
					PRINT @str1
				EXEC (@str1) -- делаем расчет
				IF @debug = 1
					SELECT *
					FROM dbo.Paym_add
					WHERE occ = @occ1
						AND service_id = @service_id

				SELECT @summa1 = pa.Value
				FROM dbo.Paym_add AS pa
				WHERE pa.occ = @occ1
					AND pa.service_id = @service_id
					AND pa.sup_id = @sup_id

				IF (@summa1 > @value)
					AND @mode_history = 1
					SET @summa1 = @value

				IF @debug = 1
					PRINT @summa1
			END

			IF (@added_true = 1)
				AND (@sum_add <> 0) -- С учётом перерасчётов
			BEGIN
				-- берём пропорцию по кол-ву дней возврата		
				IF @kolday_fin > @kolday_add
					SELECT @sum_add = (@sum_add * @kolday_add) / @kolday_fin
				SELECT @summa1 = @summa1 + @sum_add
			END

			SELECT @summa1 = (@Znak * @summa1)

			IF @summa1 <> 0
			BEGIN
				SELECT @SummaItog = @SummaItog + @summa1

				INSERT INTO dbo.Added_Payments
					(occ
				   , service_id
				   , sup_id
				   , add_type
				   , doc
				   , Value
				   , data1
				   , data2
				   , doc_no
				   , doc_date
				   , user_edit
				   , fin_id_paym
				   , comments
				   , fin_id)
					VALUES (@occ1
						  , @service_id
						  , @sup_id
						  , @add_type1
						  , @doc1
						  , @summa1
						  , @data1
						  , @data2
						  , @doc_no1
						  , @doc_date1
						  , @user_edit1
						  , @fin_id
						  , @comments
						  , @fin_current)

			END

			FETCH NEXT FROM curs INTO @occ1, @service_id, @fin_current, @sup_id
		END

		CLOSE curs
		DEALLOCATE curs
	END

	-- Изменить значения в таблице paym_list
	UPDATE pl
	SET Added = COALESCE((
		SELECT SUM(Value)
		FROM dbo.Added_Payments ap
		WHERE ap.occ = pl.occ
			AND ap.service_id = pl.service_id
			AND ap.fin_id = pl.fin_id
			AND ap.sup_id = pl.sup_id
	), 0)
	FROM dbo.Paym_list AS pl
		JOIN @t AS t ON pl.occ = t.occ
			AND pl.fin_id = t.fin_current
END
go

