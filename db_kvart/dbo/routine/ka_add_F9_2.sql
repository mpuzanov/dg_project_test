-- =============================================
-- Author:		Пузанов
-- Create date: 22.06.2012
-- Description:	Перерасчет по пост. № 307 Формула 9 используем перерасчёты и количество услуги высчитываем сами
-- =============================================
CREATE         PROCEDURE [dbo].[ka_add_F9_2]
	  @bldn_id1 INT
	, @service_id1 VARCHAR(10) -- код услуги
	, @fin_id1 SMALLINT -- фин. период
	, @value_source1 DECIMAL(15, 2) -- Объем по счётчику
	, @doc1 VARCHAR(100) = NULL -- Документ
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @debug BIT
	, @ras_add BIT = 1 -- расчёт разовых, 0-текущих начислений
	, @addyes INT OUTPUT -- если 1 то разовые добавили
	, @volume_arenda DECIMAL(15, 4) -- объём по нежилым помещениям
	, @sup_id INT = NULL
	, @tarif DECIMAL(9, 4) = 0
/*

Вызов процедуры:
DECLARE	@addyes int --Воткинское шоссе д.122
exec [dbo].[ka_add_F9] @bldn_id1 = 2435,@service_id1 = N'хвод',@fin_id1 = 114,
		@value_source1 = 450,@doc1 = N'Тест',@doc_no1=999, @debug=1, @ras_add=1, @addyes = @addyes OUTPUT

exec [dbo].[ka_add_F9] @bldn_id1 = 3508,@service_id1 = N'вотв',@fin_id1 = 121,
		@value_source1 = 768,@doc1 = N'Тест',@doc_no1=999, @debug=1, @ras_add=1, @addyes = @addyes OUTPUT		

22/06/2012
используем перерасчёты и количество услуги высчитываем сами
		
*/
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	
	IF @debug=1 
		PRINT 'ka_add_F9_2'

	DECLARE @add_type1 TINYINT = 11
		  , @Vnr DECIMAL(15, 2)
		  , @Vnn DECIMAL(15, 2)
		  , @occ INT
		  , @total_sq DECIMAL(10, 4)
		  , @i INT = 0
		  , @comments VARCHAR(100) = ''
		  , @koef DECIMAL(15, 8)
		  , @sum_add DECIMAL(15, 2)
		  , @sum_value DECIMAL(15, 2)
		  , @ostatok DECIMAL(9, 2)
		  , @tip_id SMALLINT
		  , @fin_current SMALLINT

	SET @addyes = 0

	--IF @value_source1=0 RETURN;

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL)

	IF @ras_add = 0
		AND EXISTS (
			SELECT 1
			FROM dbo.Paym_occ_build AS pcb
				JOIN dbo.View_occ_all AS o 
					ON pcb.fin_id = o.fin_id
					AND pcb.occ = o.occ
			WHERE 
				pcb.fin_id = @fin_id1
				AND service_id = @service_id1
				AND o.bldn_id = @bldn_id1
		)
	BEGIN
		RAISERROR ('В этом доме по услуге %s уже были расчёты по ОПУ', 16, 1, @service_id1)
		RETURN 1
	END

	IF @fin_current = @fin_id1
	BEGIN
		-- нужен перерасчёт по дому 
		DECLARE curs CURSOR LOCAL FOR

			SELECT occ
			FROM dbo.VOcc voa 
				JOIN dbo.Occupation_Types AS ot 
					ON voa.tip_id = ot.id
			WHERE 
				voa.status_id <> 'закр'
				AND voa.bldn_id = @bldn_id1
				AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
			ORDER BY occ

		OPEN curs
		FETCH NEXT FROM curs INTO @occ

		WHILE (@@fetch_status = 0)
		BEGIN
			-- Расчитываем квартплату
			EXEC dbo.k_raschet_1 @occ
							   , @fin_current
			FETCH NEXT FROM curs INTO @occ
		END

		CLOSE curs
		DEALLOCATE curs
	END

	SELECT 
		@tip_id = tip_id
	FROM dbo.View_build_all 
	WHERE 
		fin_id = @fin_id1
		AND bldn_id = @bldn_id1

	DECLARE @t TABLE (
		  occ INT -- PRIMARY KEY
		, kol DECIMAL(15, 4) DEFAULT 0
		, is_counter BIT DEFAULT 0
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, value DECIMAL(9, 2) DEFAULT 0
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, sum_value DECIMAL(9, 2) DEFAULT 0
		, comments VARCHAR(100) DEFAULT ''
		, nom_kvr VARCHAR(20) DEFAULT ''
		, tarif DECIMAL(10, 4) DEFAULT 0
		, mode_id INT DEFAULT 0
		, source_id INT DEFAULT 0
		, norma DECIMAL(9, 2) DEFAULT 0
		, metod TINYINT DEFAULT 0
		, unit_id VARCHAR(10) DEFAULT NULL
		, kol_add DECIMAL(15, 4) DEFAULT 0
		, sup_id INT DEFAULT 0
	)
	--IF @service_kol IS NULL SET @service_kol=@service_id1

	-- находим кол-во
	INSERT INTO @t (occ
				  , kol
				  , is_counter
				  , value
				  , nom_kvr
				  , metod
				  , unit_id
				  , sup_id)
	SELECT ph.occ
		 , SUM(COALESCE(ph.kol, 0))
		 , ph.is_counter
		 , SUM(ph.value) + COALESCE((
			   SELECT SUM(value)
			   FROM dbo.View_added AS ap
			   WHERE ap.occ = ph.occ
				   AND ap.fin_id = @fin_id1
				   AND ap.service_id = @service_id1
				   AND ap.sup_id = @sup_id
				   AND add_type <> 11
		   ), 0)
		 , oh.nom_kvr
		 , ph.metod
		 , ph.unit_id
		 , ph.sup_id
	FROM dbo.View_occ_all AS oh 
		JOIN dbo.View_paym AS ph 
			ON oh.fin_id = ph.fin_id
			AND oh.occ = ph.occ
	WHERE 
		oh.bldn_id = @bldn_id1
		AND oh.fin_id = @fin_id1
		AND ph.service_id = @service_id1
		AND (ph.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY ph.occ
		   , ph.is_counter
		   , oh.nom_kvr
		   , ph.metod
		   , ph.unit_id
		   , ph.sup_id

	UPDATE t
	SET mode_id = cl.mode_id
	  , source_id = cl.source_id
	FROM @t AS t
		JOIN dbo.View_paym AS cl 
			ON t.occ = cl.occ
	WHERE cl.fin_id = @fin_id1
		AND cl.service_id = @service_id1
		AND cl.sup_id = t.sup_id;

	UPDATE t
	SET total_sq = o.total_sq
	FROM @t AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ;

	DECLARE @unit_id VARCHAR(10) = 'кубм'

	IF COALESCE(@tarif, 0) = 0  -- тариф на входе не задан
	BEGIN
		IF @service_id1 IN ('элек', 'элмп')
		BEGIN
			SET @unit_id = 'квтч'

			SELECT TOP (1) @tarif = ph.tarif
			FROM dbo.View_occ_all AS oh 
				JOIN dbo.Flats AS f 
					ON oh.flat_id = f.id
				JOIN dbo.View_paym AS ph 
					ON oh.occ = ph.occ
					AND oh.fin_id = ph.fin_id
			WHERE 
				f.bldn_id = @bldn_id1
				AND oh.fin_id = @fin_id1
				AND ph.service_id = @service_id1
				AND (ph.is_counter IS NULL OR ph.is_counter = 0)
				AND ph.value > 0

		END
		ELSE
		--IF @service_id1 IN ('хвод','гвод','гвс2','вотв')
		BEGIN
			UPDATE t
			SET tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, @service_id1, @unit_id)
			FROM @t AS t

			SELECT TOP 1 @tarif = COALESCE(tarif, 0)
			FROM @t
			ORDER BY tarif DESC;
		END

	END

	IF @tarif IS NULL
	BEGIN
		RAISERROR ('Не удалось определить тариф по услуге %s', 16, 1, @service_id1)
		RETURN
	END

	IF @debug = 1
		SELECT *
		FROM @t
		WHERE is_counter = 0

	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod IS NULL
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod=3
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=1 OR metod=3

	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod is null
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod=3
	--IF @debug=1 SELECT coalesce(SUM(kol),0) FROM @t WHERE is_counter=1 or metod=3

	SELECT @Vnn = COALESCE(SUM(value), 0)
	FROM @t
	WHERE is_counter = 0
		AND metod IS NULL;

	SELECT @Vnr = COALESCE(SUM(value), 0)
	FROM @t
	WHERE is_counter = 1
		OR metod IN (2, 3, 4);

	SELECT @value_source1 = @value_source1 * @tarif;

	SELECT @koef = @value_source1 / (@Vnr + @Vnn);

	DECLARE @str_koef VARCHAR(40)
	SELECT @str_koef = CONCAT('(', @value_source1, '/(', @Vnn, '+', @Vnr, '))')

	IF @debug = 1
		SELECT '@value_source1' = @value_source1
			 , '@Vnn' = @Vnn
			 , '@Vnr' = @Vnr
			 , '@Vnn+@Vnr' = @Vnn + @Vnr
			 , '@koef' = @koef
			 , '@tarif' = @tarif
			 , '@tip_id' = @tip_id
			 , '@fin_id1' = @fin_id1

	IF @debug = 1
		PRINT @str_koef

	UPDATE t
	SET sum_add = (@koef * value) - (value)
	  , sum_value = (@koef * value)
	  , comments = CONCAT('Ф9: (', @str_koef, '*', value, ')-(', value, ')')
	  , kol = value / @tarif
	FROM @t AS t

	SELECT @sum_add = SUM(sum_add)
		 , @sum_value = SUM(sum_value)
	FROM @t;

	SELECT @total_sq = SUM(total_sq)
	FROM @t
	WHERE is_counter = 0;

	-- Проверяем остатки
	SELECT @ostatok = (@value_source1 - (@Vnn + @Vnr)) * @tarif - @sum_add
	IF @ostatok <> 0
	BEGIN
		IF @debug = 1
			PRINT @ostatok
		
		;WITH cte AS (
			SELECT TOP (1) * FROM @t WHERE ABS(sum_add) > ABS(@ostatok)
		)
		UPDATE cte
		SET sum_add = sum_add + @ostatok;

		SELECT @sum_add = SUM(sum_add)
		FROM @t;

		SELECT @ostatok = (@value_source1 - (@Vnn + @Vnr)) * @tarif - @sum_add;
	END
	IF @debug = 1
		SELECT '@sum_add' = @sum_add
			 , '@ostatok_add' = @ostatok
			 , '@total_sq' = @total_sq

	SELECT @ostatok = (@value_source1 - (@Vnn + @Vnr)) * @tarif - @sum_value
	IF @ostatok <> 0
	BEGIN
		IF @debug = 1
			PRINT @ostatok

		;WITH cte AS (
			SELECT TOP (1) * FROM @t WHERE ABS(sum_value) > ABS(@ostatok)
		)
		UPDATE cte
		SET sum_value = sum_value + @ostatok;		

		SELECT @sum_value = SUM(sum_value)
		FROM @t;

		SELECT @ostatok = (@value_source1 - (@Vnn + @Vnr)) * @tarif - @sum_value
	END
	IF @debug = 1
		SELECT '@sum_value' = @sum_value
			 , '@ostatok_value' = @ostatok

	IF @debug = 1
		SELECT *
		FROM @t

	DECLARE @user_edit1 SMALLINT

	SELECT @user_edit1 = id
	FROM dbo.Users 
	WHERE login = system_user;

	UPDATE t
	SET kol_add =
				 CASE
					 WHEN @tarif = 0 THEN 0
					 ELSE sum_add / @tarif
				 END
	FROM @t AS t

	BEGIN TRAN

	IF @ras_add = 1
	BEGIN

		-- Добавить в таблицу added_payments
		INSERT INTO dbo.Added_Payments (occ
									  , service_id
									  , sup_id
									  , add_type
									  , doc
									  , value
									  , doc_no
									  , doc_date
									  , user_edit
									  , fin_id_paym
									  , comments
									  , kol)
		SELECT occ
			 , @service_id1
			 , sup_id
			 , @add_type1
			 , @doc1
			 , sum_add
			 , @doc_no1
			 , @doc_date1
			 , @user_edit1
			 , @fin_id1
			 , SUBSTRING(comments, 1, 70)
			 , kol_add
		FROM @t
		WHERE sum_add <> 0
		SELECT @addyes = @@rowcount

		-- Изменить значения в таблице paym_list
		UPDATE pl
		SET Added = COALESCE((
			SELECT SUM(value)
			FROM dbo.Added_Payments ap 
			WHERE occ = pl.occ
				AND service_id = pl.service_id
				AND ap.sup_id = pl.sup_id
				AND fin_id = @fin_current
		), 0)
		FROM dbo.Paym_list AS pl
			JOIN @t AS t ON 
				pl.occ = t.occ
		WHERE 
			pl.service_id = @service_id1
			AND pl.sup_id = t.sup_id
			AND fin_id = @fin_current;
	END
	ELSE
	BEGIN
		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb
			JOIN @t AS t ON 
				pcb.occ = t.occ
		WHERE 
			pcb.fin_id = @fin_id1
			AND pcb.service_id = @service_id1;

		INSERT INTO dbo.Paym_occ_build (fin_id
										, occ
										, service_id
										, kol
										, tarif
										, value
										, comments
										, unit_id
										, procedura
										, kol_add)
		SELECT @fin_id1
			 , t.occ
			 , @service_id1
			 , t.kol + t.kol_add
			 , @tarif
			 , t.sum_value
			 , comments
			 , unit_id = @unit_id
			 , procedura = 'ka_add_F9'
			 , t.kol_add
		FROM @t AS t
		SELECT @addyes = @@rowcount
	END
	COMMIT TRAN

	-- Добавляем показание по счётчику
	DECLARE @t_counter TABLE (
		  counter_id INT
		, actual_value DECIMAL(12, 4)
	)
	DECLARE @Sum_Actual_value DECIMAL(12, 4)
		  , @counter_id1 INT
		  , @inspector_date1 SMALLDATETIME

	INSERT INTO @t_counter (counter_id, actual_value)
	SELECT counter_id
		 , COALESCE(actual_value, 0)
	FROM dbo.View_counter_insp_build
	WHERE 
		build_id = @bldn_id1
		AND service_id = @service_id1;

	SELECT @Sum_Actual_value = SUM(actual_value)
	FROM @t_counter;

	IF @Sum_Actual_value = 0
	BEGIN
		SELECT TOP 1 @counter_id1 = counter_id
		FROM @t_counter;

		SET @inspector_date1 = dbo.Fun_GetOnlyDate(current_timestamp);

		EXEC k_counter_value_add3 @counter_id1
								, @inspector_value1 = 0
								, @inspector_date1 = @inspector_date1
								, @actual_value = @value_source1
								, @blocked1 = 0
								, @comments1 = 'взято из перерасчётов'
	END

END
go

