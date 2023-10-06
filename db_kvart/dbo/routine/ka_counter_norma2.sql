-- =============================================
-- Author:		Пузанов
-- Create date: 22.12.2012
-- Description:	Автоматический перерасчет по внутр. счётчикам если в прошлый месяц начислено по норме
-- =============================================
CREATE         PROCEDURE [dbo].[ka_counter_norma2]
(
	@occ			INT
	,@fin_current	SMALLINT
	,@debug			BIT			= 0
	,@doc_no		VARCHAR(10)	= '888'
)
AS
/*

Устаревшее

-- Удаляем водоотведение если нет ХВС или ГВС   21.11.2011
*/
BEGIN
	SET NOCOUNT ON;

	EXEC ka_counter_norma3	@occ = @occ
							,@fin_current = @fin_current
							,@debug = @debug
							,@doc_no = @doc_no
	RETURN

	IF @doc_no IS NULL
		SET @doc_no = '888'

	--select * FROM dbo.ADDED_PAYMENTS ap WHERE ap.occ=@occ AND ap.add_type=12 AND ap.doc_no=@doc_no

	DECLARE	@service_id1			VARCHAR(10)
			,@tip_id				SMALLINT
			,@kolmes				SMALLINT		= 0
			,@kol_counter			DECIMAL(9, 2)	= 0
			,@kol_add				DECIMAL(9, 2)	= 0
			,@comments				VARCHAR(50)		= ''
			,@sum_add				DECIMAL(9, 2)	= 0
			,@doc1					VARCHAR(50)		= ''
			,@first_mes				SMALLINT
			,@last_mes				SMALLINT
			,@str_mes				VARCHAR(30)		= ''
			,@sys_user				VARCHAR(30)		= system_user
			,@counter_add_ras_norma	BIT -- выполнять Автоматический перерасчет по внутр. счётчикам по типу фонда

	SELECT
		@tip_id = tip_id
		,@counter_add_ras_norma = ot.counter_add_ras_norma
	FROM dbo.OCCUPATIONS AS o 
	JOIN dbo.OCCUPATION_TYPES AS ot 
		ON o.tip_id = ot.id
	WHERE o.occ = @occ

	IF @counter_add_ras_norma = 0
		RETURN -- не расчитываем и выходим

	DECLARE @tc TABLE
		(
			fin_id			SMALLINT
			,service_id		VARCHAR(10)
			,kod_counter	INT				DEFAULT NULL
			, -- сумма кодов счетчиков по услуге (перерасчёт делать только если она совпадает с текущим мес.)
			metod_old		TINYINT			DEFAULT NULL
			,kol			DECIMAL(12, 4)	DEFAULT 0
			,value			DECIMAL(9, 2)	DEFAULT 0
			,is_counter		TINYINT			DEFAULT 0
		)

	INSERT INTO @tc
	(	fin_id
		,service_id
		,kod_counter)
			SELECT
				fin_id
				,service_id
				,SUM(counter_id)
			FROM [dbo].[View_COUNTER_ALL] 
			WHERE occ = @occ
			AND (date_del IS NULL
			OR date_del > start_date)
			AND (date_create <= start_date) -- убираем месяц установки счётчика
			GROUP BY	fin_id
						,service_id
			UNION ALL
			SELECT
				fin_id
				,'гвс2'
				,SUM(counter_id)
			FROM [dbo].[View_COUNTER_ALL] 
			WHERE occ = @occ
			AND service_id = 'гвод'
			AND (date_del IS NULL
			OR date_del > start_date)
			AND (date_create <= start_date) -- убираем месяц установки счётчика
			GROUP BY	fin_id
						,service_id
			UNION ALL
			SELECT
				fin_id
				,'хвс2'
				,SUM(counter_id)
			FROM [dbo].[View_COUNTER_ALL] 
			WHERE occ = @occ
			AND service_id = 'хвод'
			AND (date_del IS NULL
			OR date_del > start_date)
			AND (date_create <= start_date) -- убираем месяц установки счётчика
			GROUP BY	fin_id
						,service_id

	INSERT INTO @tc
	(	fin_id
		,service_id)
			SELECT DISTINCT
				fin_id
				,'вотв'
			FROM @tc
			UNION ALL
			SELECT DISTINCT
				fin_id
				,'вот2'
			FROM @tc

	UPDATE t1
	SET	metod_old	= vp.metod_old
		,kol		= COALESCE(vp.kol, 0)
		,t1.value	= COALESCE(vp.value, 0)
		,is_counter	= vp.is_counter
	FROM @tc AS t1
	JOIN dbo.View_PAYM AS vp
		ON vp.fin_id = t1.fin_id
		AND vp.service_id = t1.service_id
	WHERE vp.occ = @occ


	UPDATE t1
	SET metod_old = 3
	FROM @tc AS t1
	WHERE service_id = 'хвс2'
	AND EXISTS (SELECT
			*
		FROM @tc AS t2
		WHERE t2.fin_id = t1.fin_id
		AND t2.metod_old = 3
		AND t2.service_id = 'хвод')
	UPDATE t1
	SET metod_old = 3
	FROM @tc AS t1
	WHERE service_id = 'гвс2'
	AND EXISTS (SELECT
			*
		FROM @tc AS t2
		WHERE t2.fin_id = t1.fin_id
		AND t2.metod_old = 3
		AND t2.service_id = 'гвод')
	UPDATE t1
	SET metod_old = 0
	FROM @tc AS t1
	WHERE t1.service_id IN ('вотв', 'вот2')
	AND t1.metod_old IS NULL
	AND EXISTS (SELECT
			*
		FROM @tc AS t2
		WHERE t2.fin_id = t1.fin_id
		AND t2.metod_old IS NOT NULL
		AND t2.service_id IN ('хвод', 'гвод', 'хвс2', 'гвс2'))


	IF @debug = 1
		SELECT
			*
		FROM @tc
		ORDER BY fin_id DESC

	DECLARE @t TABLE
		(
			occ				INT
			,service_id		VARCHAR(10)
			,tarif			DECIMAL(10, 4)	DEFAULT 0
			,kolmes			SMALLINT		DEFAULT 0
			,kol_counter	DECIMAL(9, 2)	DEFAULT NULL
			,kol_add		DECIMAL(9, 2)	DEFAULT 0
			,sum_add		DECIMAL(9, 2)	DEFAULT 0
			,kod_counter	INT				DEFAULT 0
			,first_mes		SMALLINT		DEFAULT 0
		)

	-- находим текущие показания по счетчику
	INSERT INTO @t
	(	occ
		,service_id
		,tarif
		,kol_counter
		,kod_counter)
			SELECT
				occ
				,p1.service_id
				,tarif
				,SUM(coalesce(p1.kol, 0))
				,kod_counter
			FROM dbo.View_PAYM AS p1 
			LEFT JOIN @tc AS tc
				ON p1.fin_id = tc.fin_id
				AND p1.service_id = tc.service_id
			WHERE p1.fin_id = @fin_current
			AND p1.occ = @occ
			AND (p1.is_counter = 2
			AND p1.metod_old IN (3, 4)
			OR (p1.is_counter = 0
			AND p1.service_id IN ('вотв', 'вот2')))
			--AND p1.metod in (3,4)
			GROUP BY	occ
						,p1.service_id
						,tarif
						,kod_counter

	IF @debug = 1
		SELECT
			*
		FROM @t

	-- Удаляем водоотведение если нет ХВС или ГВС   21.11.2011
	IF EXISTS (SELECT
				*
			FROM @t
			WHERE service_id IN ('вотв', 'вот2'))
		AND NOT EXISTS (SELECT
				*
			FROM @t
			WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2'))
		DELETE FROM @t
		WHERE service_id IN ('вотв', 'вот2')

	IF @debug = 1
		SELECT
			*
		FROM @t

	-- находим кол-во месяцев по норме от текущего	
	DECLARE	@fin_id1		SMALLINT
			,@fin_min		SMALLINT
			,@kol			DECIMAL(9, 2)
			,@kod_counter	INT

	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT
			service_id
			,kod_counter
		FROM @t
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @service_id1, @kod_counter

	WHILE (@@fetch_status = 0)
	BEGIN
		SET @fin_id1 = @fin_current - 1

		SELECT
			@fin_min = MIN(fin_id)
		FROM @tc
		WHERE service_id = @service_id1

		IF @debug = 1
			PRINT @service_id1

		SELECT
			@last_mes = @fin_id1
			,@first_mes = @fin_id1

		IF @debug = 1
			SELECT
				@service_id1
				,fin_min = @fin_min
				,first_mes = @first_mes
				,last_mes = @last_mes
		WHILE @fin_id1 > @fin_current - 13
		BEGIN
			SELECT
				@kol = 0
				,@sum_add = 0
				,@first_mes = @fin_id1

			IF (@fin_id1 < @fin_min)
				OR EXISTS (SELECT
						*
					FROM @tc
					WHERE fin_id = @fin_id1
					AND service_id = @service_id1
					AND (metod_old = 3
					OR metod_old IS NULL   -- 25/02/2013
					))
				BREAK

			UPDATE @t
			SET first_mes = @first_mes
			WHERE service_id = @service_id1
			--if @debug=1 print @first_mes

			IF @service_id1 IN ('вотв', 'вот2')
				SELECT
					@kol = tc.kol
					,@sum_add = tc.value
				FROM @tc AS tc
				WHERE tc.fin_id = @fin_id1
				AND tc.service_id = @service_id1
				AND tc.is_counter = 0
				AND tc.kol <> 0
				AND EXISTS (SELECT
						*
					FROM @tc AS tc2
					WHERE tc2.fin_id = @fin_id1
					AND tc2.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
					AND (tc2.is_counter = 2
					OR EXISTS (SELECT
							*
						FROM @tc
						WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
						AND [@tc].fin_id = @fin_id1)
					)
					AND tc2.kol <> 0
					AND coalesce(tc2.metod_old, 1) IN (1, 2))
			ELSE
				SELECT
					@kol = tc.kol
					,@sum_add = tc.value
				FROM @tc AS tc
				WHERE tc.fin_id = @fin_id1
				AND tc.service_id = @service_id1
				--AND p1.is_counter=2
				AND tc.is_counter <> 1 --AND p1.is_counter=2
				AND tc.kol <> 0
				AND coalesce(tc.metod_old, 1) IN (1, 2)
				AND tc.kod_counter = @kod_counter

			IF @kol <> 0
				UPDATE t
				SET	kol_add		= kol_add + @kol
					,kolmes		= kolmes + 1
					,sum_add	= sum_add + @sum_add
				FROM @t AS t
				WHERE service_id = @service_id1

			IF @debug = 1
				PRINT @fin_id1

			SELECT
				@fin_id1 = @fin_id1 - 1
		END

		FETCH NEXT FROM curs_1 INTO @service_id1, @kod_counter
	END

	CLOSE curs_1
	DEALLOCATE curs_1

	-- Если начисляем по вот2 то удаляем если есть 'вотв'
	IF EXISTS (SELECT
				*
			FROM dbo.SERVICES_TYPES ST 
			WHERE ST.service_id = 'вот2'
			AND tip_id = @tip_id)
		UPDATE t
		SET	kol_add		= 0
			,sum_add	= 0
		FROM @t AS t
		WHERE service_id = 'вотв'

	UPDATE @t
	SET	kol_add		= -1 * kol_add
		,sum_add	= -1 * sum_add

	-- Удаляем водоотведение если нет начислений по ХВС или ГВС 2.06.2012
	IF EXISTS (SELECT
				*
			FROM @t
			WHERE service_id IN ('вотв', 'вот2'))
		AND NOT EXISTS (SELECT
				*
			FROM @t
			WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
			AND sum_add <> 0)
		DELETE FROM @t
		WHERE service_id IN ('вотв', 'вот2')

	UPDATE t1
	SET first_mes = (SELECT TOP 1
			first_mes
		FROM @t AS t2
		WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
		ORDER BY first_mes DESC)
	FROM @t AS t1
	WHERE service_id IN ('вотв', 'вот2')

	--UPDATE t
	--SET kolmes = @last_mes - first_mes + 1
	--FROM @t AS t

	IF @debug = 1
		SELECT
			*
		FROM @t
	-- удаляем с нулями если уже были
	--delete ap from dbo.ADDED_PAYMENTS ap JOIN @t as t ON ap.occ=t.occ and ap.service_id=t.service_id
	--where ap.occ=@occ and ap.add_type=12 and ap.doc_no=@doc_no and t.sum_add=0

	DELETE ap
		FROM dbo.ADDED_PAYMENTS ap
	WHERE ap.occ = @occ
		AND ap.add_type = 12
		AND ap.doc_no = @doc_no

	-- добавляем разовые
	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT
			service_id
			,kol_add
			,sum_add
			,kolmes
			,first_mes
		FROM @t
		WHERE sum_add <> 0
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @service_id1, @kol_add, @sum_add, @kolmes, @first_mes

	WHILE (@@fetch_status = 0)
	BEGIN

		-- проверяем есть ли разовые по счетчику по этой услуге
		-- add_type 12, doc_no=@doc_no
		--delete from dbo.ADDED_PAYMENTS where occ=@occ and service_id=@service_id1 and add_type=12 and doc_no=@doc_no

		SET @comments = 'Кол.мес: ' + LTRIM(STR(@kolmes)) + ' ,Кол-во: ' + LTRIM(STR(@kol_add, 9, 2))

		--if not Exists(select * from dbo.ADDED_PAYMENTS where occ=@occ and service_id=@service_id1)
		--begin 
		IF @debug = 1
			PRINT 'добавляем разовые ' + LTRIM(STR(@occ)) + ' ' + LTRIM(@service_id1)
		-- Определяем период

		IF @last_mes - @first_mes = 0
			SET @str_mes = dbo.Fun_NameFinPeriod(@last_mes)
		ELSE
		BEGIN
			DECLARE @d1 SMALLDATETIME
			SELECT
				@d1 = start_date
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id = @first_mes
			SET @str_mes = SUBSTRING(CONVERT(VARCHAR(8), @d1, 3), 4, 5)
			SELECT
				@d1 = start_date
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id = @last_mes
			SET @str_mes = @str_mes + '-' + SUBSTRING(CONVERT(VARCHAR(8), @d1, 3), 4, 5)
		END

		SET @doc1 = 'Коррект.по счётчикам за ' + @str_mes

		IF @debug = 1
			PRINT @doc1
		-- ************************************************************************************
		--exec dbo.ka_add_added_3 @occ1=@occ,@service_id1=@service_id1,@add_type1=12,@value1=@sum_add, 
		--	@doc1=@doc1,@comments=@comments, @kol=@kol_add, @doc_no1=@doc_no

		BEGIN TRAN

			-- Добавить в таблицу added_payments
			INSERT INTO dbo.ADDED_PAYMENTS
			(	occ
				,service_id
				,add_type
				,doc
				,value
				,doc_no
				,doc_date
				,user_edit
				,dsc_owner_id
				,COMMENTS
				,kol)
			VALUES (@occ
					,@service_id1
					,12
					,@doc1
					,@sum_add
					,@doc_no
					,NULL
					,NULL
					,NULL
					,@comments
					,@kol_add)

			-- Изменить значения в таблице paym_list
			UPDATE pl
			SET added = coalesce((SELECT
					SUM(value)
				FROM dbo.ADDED_PAYMENTS 
				WHERE occ = @occ
				AND service_id = pl.service_id)
			, 0)
			FROM dbo.PAYM_LIST AS pl
			WHERE occ = @occ

		COMMIT TRAN

		-- ************************************************************************************
		--end

		FETCH NEXT FROM curs_1 INTO @service_id1, @kol_add, @sum_add, @kolmes, @first_mes
	END

	CLOSE curs_1
	DEALLOCATE curs_1

	IF @debug = 1
		SELECT
			*
		FROM @t


END
go

