-- =============================================
-- Author:		Пузанов
-- Create date: 09.03.2011
-- Description:	Перерасчет по пост.№307 Формула 9
-- =============================================
CREATE     PROCEDURE [dbo].[ka_add_added_8]
	  @bldn_id1 INT
	, @service_id1 VARCHAR(10) -- код услуги
	, @fin_id1 SMALLINT -- с этого фин. периода
	, @fin_id2 SMALLINT -- по этот фин. период
	, @value_source1 DECIMAL(15, 2) -- Объем по счётчику
	, @doc1 VARCHAR(100) = NULL -- Документ
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @debug BIT = 0
	, @addyes INT OUTPUT -- если 1 то разовые добавили
	, @sup_id INT = NULL
/*



Вызов процедуры:
DECLARE	@addyes int
exec [dbo].[ka_add_added_8] @bldn_id1 = 869,@service_id1 = N'элек',@fin_id1 = 84,@fin_id2 = 95,
		@value_source1 = 387338,@doc1 = N'Тест',@debug=1, @addyes = @addyes OUTPUT
*/
AS
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SET @addyes = 0
	IF @value_source1 = 0
		RETURN;

	DECLARE @add_type1 TINYINT = 11
		  , @Vnr DECIMAL(15, 4)
		  , @Vnn DECIMAL(15, 4)
		  , @occ INT
		  , @total_sq DECIMAL(10, 4)
		  , @i INT = 0
		  , @comments VARCHAR(100) = ''
		  , @koef DECIMAL(15, 8)
		  , @tarif DECIMAL(9, 4)
		  , @sum_add DECIMAL(15, 4)
		  , @ostatok DECIMAL(15, 4)
		  , @tip_id SMALLINT
		  , @fin_current SMALLINT

	SELECT @tip_id = tip_id
	FROM dbo.View_build_all 
	WHERE fin_id = @fin_id1
		AND bldn_id = @bldn_id1

	IF @sup_id IS NULL
		SELECT TOP (1) @sup_id = cl.sup_id
		FROM Flats f 
			JOIN Occupations o 
				ON f.id = o.flat_id
			JOIN Consmodes_list cl 
				ON o.occ = cl.occ
		WHERE cl.service_id = @service_id1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL)

	DECLARE @t TABLE (
		  occ INT -- PRIMARY KEY 
		, kol DECIMAL(15, 4) DEFAULT 0
		, is_counter BIT DEFAULT 0
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, VALUE DECIMAL(9, 2) DEFAULT 0
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, comments VARCHAR(100) DEFAULT ''
	)

	-- находим кол-во по норме
	INSERT INTO @t (occ
				  , kol
				  , is_counter
				  , VALUE)
	SELECT ph.occ
		 , SUM(COALESCE(ph.kol, 0))
		 , 0
		 , SUM(ph.VALUE)
	FROM dbo.Occ_history AS oh 
		JOIN dbo.Flats AS f 
			ON oh.flat_id = f.id
		JOIN dbo.Paym_history AS ph 
			ON oh.occ = ph.occ
			AND oh.fin_id = ph.fin_id
	WHERE f.bldn_id = @bldn_id1
		AND oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND ph.service_id = @service_id1
		AND ph.service_id = @sup_id
		AND (ph.is_counter IS NULL OR ph.is_counter = 0)
	--AND ( (ph.is_counter IS NULL OR ph.is_counter=0) or (ph.is_counter=2 and ph.metod=1)) -- 14/04/2011
	GROUP BY ph.occ

	-- находим кол-во по счётчиккам
	INSERT INTO @t (occ
				  , kol
				  , is_counter
				  , VALUE)
	SELECT ph.occ
		 , SUM(COALESCE(ph.kol, 0))
		 , 1
		 , SUM(ph.VALUE)
	FROM dbo.Flats AS f 
		JOIN dbo.Counter_paym_occ AS ph 
			ON f.id = ph.flat_id
	WHERE f.bldn_id = @bldn_id1
		AND ph.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND ph.service_id = @service_id1
		AND ph.tip_value = 1
		AND NOT EXISTS (
			SELECT 1
			FROM @t t
			WHERE t.occ = ph.occ
		)
	GROUP BY ph.occ

	UPDATE t
	SET total_sq = o.total_sq
	FROM @t AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ

	SELECT @Vnn = COALESCE(SUM(kol), 0)
	FROM @t
	WHERE is_counter = 0
	SELECT @Vnr = COALESCE(SUM(kol), 0)
	FROM @t
	WHERE is_counter = 1

	SELECT @koef = @value_source1 / (@Vnr + @Vnn)
	DECLARE @str_koef VARCHAR(40)
	SELECT @str_koef = '(' + LTRIM(STR(@value_source1, 15, 2)) + '/(' + LTRIM(STR(@Vnn, 15, 2)) + '+' + LTRIM(STR(@Vnr, 15, 2)) + '))'
	--select @str_koef='; Vnn:'+LTRIM(STR(@Vnn,15,2))+',Vnr:'+LTRIM(STR(@Vnr,15,2))

	IF @service_id1 IN ('элек')
		SELECT TOP 1 @tarif = ph.tarif
		FROM dbo.View_occ_all_lite AS oh 
			JOIN dbo.View_paym AS ph 
				ON oh.occ = ph.occ
				AND oh.fin_id = ph.fin_id
		WHERE oh.bldn_id = @bldn_id1
			AND oh.fin_id = @fin_id2
			AND ph.service_id = @service_id1
			AND ph.service_id = @sup_id
			--AND (ph.is_counter IS NULL
			--OR ph.is_counter = 0)
			AND ph.VALUE > 0



	IF @service_id1 IN ('хвод', 'гвод', 'гвс2')
	BEGIN
		DECLARE @unit_id VARCHAR(10) = 'кубм'

		SELECT TOP 1 @tarif = COALESCE(tarif, 0)
		FROM [dbo].[Rates_counter]
		WHERE fin_id = @fin_id1
			AND tipe_id = @tip_id
			AND service_id = @service_id1
			AND unit_id = @unit_id
			AND tarif > 0
		ORDER BY tarif DESC

	--IF @tarif IS NULL SET @tarif=0
	END

	IF @tarif IS NULL
	BEGIN
		RAISERROR ('Не удалось определить тариф', 16, 1)
		RETURN
	END

	IF @debug = 1
		SELECT '@value_source1' = @value_source1
			 , '@Vnn' = @Vnn
			 , '@Vnr' = @Vnr
			 , '@Vnn+@Vnr' = @Vnn + @Vnr
			 , '@koef' = @koef
			 , '@tarif' = @tarif
	IF @debug = 1
		PRINT @str_koef
	UPDATE t
	SET sum_add = (kol * @koef * @tarif) - (kol * @tarif)
	  , --comments='Ф9: ('+LTRIM(STR(kol,9,4))+'*'+LTRIM(STR(@koef,9,4))+'*'+LTRIM(STR(@tarif,9,2))+')-('+LTRIM(STR(kol,9,2))+'*'+LTRIM(STR(@tarif,9,2))+')'+@str_koef
		comments = 'Ф9: (' + LTRIM(STR(kol, 9, 2)) + '*' + @str_koef + '*' + LTRIM(STR(@tarif, 9, 2)) + ')-(' + LTRIM(STR(kol, 9, 2)) + '*' + LTRIM(STR(@tarif, 9, 2)) + ')'
	FROM @t AS t
	WHERE is_counter = 1

	SELECT @sum_add = SUM(sum_add)
	FROM @t
	-- Находим остаток для раскидки по норме
	SELECT @ostatok = (@value_source1 - (@Vnn + @Vnr)) * @tarif - @sum_add

	SELECT @total_sq = COALESCE(SUM(total_sq), 0)
	FROM @t
	WHERE is_counter = 0

	IF @debug = 1
		SELECT '@sum_add' = @sum_add
			 , '@ostatok' = @ostatok
			 , '@total_sq' = @total_sq

	IF @ostatok <> 0
		UPDATE t
		SET sum_add = @ostatok * (total_sq / @total_sq)
		  , comments = 'Ф9 норма: ' + LTRIM(STR(@ostatok, 9, 4)) + '*' + LTRIM(STR(total_sq, 9, 2)) + '/' + LTRIM(STR(@total_sq, 9, 2))
		FROM @t AS t
		WHERE is_counter = 0

	IF @debug = 1
		SELECT *
		FROM @t --where is_counter=0

	DECLARE @user_edit1 SMALLINT
	SELECT @user_edit1 = dbo.Fun_GetCurrentUserId()

	BEGIN TRAN

	-- Добавить в таблицу added_payments
	INSERT INTO dbo.Added_Payments (occ
								  , service_id
								  , sup_id
								  , add_type
								  , doc
								  , VALUE
								  , doc_no
								  , doc_date
								  , user_edit
								  , fin_id_paym
								  , comments
								  , fin_id)
	SELECT occ
		 , @service_id1
		 , @sup_id
		 , @add_type1
		 , @doc1
		 , sum_add
		 , @doc_no1
		 , @doc_date1
		 , @user_edit1
		 , @fin_id2
		 , SUBSTRING(comments, 1, 70)
		 , @fin_current
	FROM @t
	WHERE sum_add <> 0
	SELECT @addyes = @@rowcount

	-- Изменить значения в таблице paym_list
	UPDATE pl
	SET Added = COALESCE((
		SELECT SUM(VALUE)
		FROM dbo.Added_Payments ap
		WHERE ap.occ = pl.occ
			AND ap.service_id = pl.service_id
			AND ap.sup_id = pl.sup_id
			AND ap.fin_id = pl.fin_id
	), 0)
	FROM dbo.Paym_list AS pl
		JOIN @t AS t ON pl.occ = t.occ
	WHERE pl.fin_id = @fin_current

	COMMIT TRAN

END
go

