/*
================================================
-- Author:		Пузанов
-- Create date: 24.04.07
-- Description:	Квартальная корректировка по 307 постановлению Приложение 2

Изменения:
26.07.2013
================================================
*/
CREATE         PROCEDURE [dbo].[ka_add_added_5]
(
	@occ1					INT -- лицевой счет
	,@service_id1			VARCHAR(10) -- код услуги
	,@fin_id1				SMALLINT -- с этого фин. периода
	,@fin_id2				SMALLINT -- по этот фин. период
	,@value_source1			DECIMAL(15, 2) -- начислено поставщиком
	,@value_build1			DECIMAL(15, 2) -- начислено нами
	,@square_build1			DECIMAL(8, 2) -- общая площадь дома
	,@square_build_no1		DECIMAL(8, 2) -- общая площадь дома без начислений по заданной услуге
	,@doc1					VARCHAR(100)	= NULL -- Документ
	,@doc_no1				VARCHAR(15)		= NULL -- номер акта
	,@doc_date1				SMALLDATETIME	= NULL -- дата акта
	,@addyes				BIT				OUTPUT -- если 1 то разовые добавили
	,@square_build_arenda	DECIMAL(8, 2)	= 0-- площадь нежилых помещений в доме
	,@sup_id				INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@add_type1		TINYINT
			,@fin_current	SMALLINT
	DECLARE	@summa1		DECIMAL(9, 2)
			,@comments	VARCHAR(50)
			,@occ_sq1	DECIMAL(10, 4) -- общая площадь в квартире	

	DECLARE	@paid_occ1	DECIMAL(9, 2)
			,@add_occ1	DECIMAL(9, 2) -- разовые по лицевому
			,@prev_year	SMALLINT


	SET @addyes = 0
	SET @add_type1 = 11 -- Квартальная корректировка

	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		--raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
		RETURN
	END

	IF @sup_id IS NULL
		SELECT
			@sup_id = dbo.Fun_GetSup_idOcc(@occ1, @service_id1)

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	-- Проверяем есть ли такаю услуга на этом лицевом
	IF NOT EXISTS (SELECT
				1
			FROM dbo.CONSMODES_LIST AS cl
			WHERE cl.occ = @occ1
			AND cl.service_id = @service_id1
			AND (cl.mode_id % 1000) != 0)
	BEGIN
		--    raiserror('У лицевого нет режима потребления по этой услуге',16,1)
		RETURN
	END

	IF @value_source1 = 0
		RETURN 0
	IF @value_build1 = 0
		RETURN 0
	IF @square_build1 = 0
		RETURN 0

	SELECT
		@occ_sq1 = total_sq
	FROM dbo.OCC_HISTORY 
	WHERE occ = @occ1
	AND fin_id = @fin_id1 --21.04.2010 площадь берем из истории
	IF @occ_sq1 IS NULL
		SET @occ_sq1 = 0


	SELECT
		@add_occ1 = SUM(value)
	FROM dbo.ADDED_PAYMENTS_HISTORY AS ap 
	JOIN dbo.GLOBAL_VALUES AS gb
		ON ap.fin_id = gb.fin_id
	WHERE occ = @occ1
	AND gb.fin_id BETWEEN @fin_id1 AND @fin_id2
	AND ap.service_id = @service_id1
	AND (ap.sup_id = @sup_id OR @sup_id IS NULL)
	AND ap.add_type <> 11 -- все разовые кроме Корректировки по 307

	IF @add_occ1 IS NULL
		SET @add_occ1 = 0

	SELECT
		@square_build1 = @square_build1 + COALESCE(@square_build_arenda, 0)

	IF @service_id1 = 'отоп'
	BEGIN
		SELECT
			@paid_occ1 = SUM(value) + @add_occ1
		FROM dbo.PAYM_HISTORY AS ph 
		JOIN dbo.GLOBAL_VALUES AS gb
			ON ph.fin_id = gb.fin_id
		WHERE occ = @occ1
		AND gb.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND ph.service_id = @service_id1
		AND ph.sup_id = @sup_id

		IF @paid_occ1 IS NULL
			OR @paid_occ1 = 0
			SET @summa1 = 0
		ELSE
		BEGIN
			SET @summa1 = (@value_source1) * (@occ_sq1 / @square_build1) - @paid_occ1

			-- формируем комментарий
			SET @comments = LTRIM(STR(@value_source1, 12, 2)) + '*' + STR(@occ_sq1, 5, 2) + '/' + LTRIM(STR(@square_build1, 8, 2)) + '-' + LTRIM(STR(@paid_occ1, 12, 2))
		END
	END
	ELSE
	BEGIN
		SELECT
			@paid_occ1 = SUM(value) + @add_occ1
		FROM dbo.PAYM_HISTORY AS ph 
		JOIN dbo.GLOBAL_VALUES AS gb
			ON ph.fin_id = gb.fin_id
		WHERE occ = @occ1
		AND gb.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND ph.service_id = @service_id1
		AND ph.sup_id = @sup_id

		IF @paid_occ1 IS NULL
			SET @paid_occ1 = 0

		IF (@value_build1 < @value_source1) -- если доначисления то квартирам где не начисляли будем делать разовые
			SET @square_build1 = @square_build1 + @square_build_no1

		IF (@value_build1 > @value_source1)
			AND (@paid_occ1 = 0)
			-- если надо возвратить деньги то квартирам где не начисляли не делаем разовые
			SET @summa1 = 0
		ELSE
		BEGIN
			SET @summa1 = (@value_source1 - @value_build1) * (@occ_sq1 / @square_build1)
			-- формируем комментарий
			SET @comments = '(' + LTRIM(STR(@value_source1, 12, 2)) + '-' + LTRIM(STR(@value_build1, 12, 2)) + ')*' + STR(@occ_sq1, 5, 2) + '/' + LTRIM(STR(@square_build1, 8, 2))
		END
	END

	--print @paid_occ1
	--print @value_source1
	--print @value_build1
	--print @occ_sq1
	--print @square_build1
	--if (@summa1>-1 and @summa1<1) or @summa1 is null return 0

	--*******************************************************************
	DECLARE @user_edit1 SMALLINT

	SELECT
		@user_edit1 = dbo.Fun_GetCurrentUserId()

	BEGIN TRAN

		-- Добавить в таблицу added_payments
		INSERT
		INTO dbo.ADDED_PAYMENTS
		(	occ
			,service_id
			,sup_id
			,add_type
			,doc
			,value
			,doc_no
			,doc_date
			,user_edit
			,dsc_owner_id
			,comments)
		VALUES (@occ1, @service_id1, @sup_id, @add_type1, @doc1, @summa1, @doc_no1, @doc_date1, @user_edit1, NULL, @comments)

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

		SET @addyes = 1 -- добавление разового прошло успешно

	COMMIT TRAN

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'


END
go

