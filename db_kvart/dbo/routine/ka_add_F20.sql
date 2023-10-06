-- =============================================
-- Author:		Пузанов
-- Create date: 24.01.15
-- Description:	Перерасчет по пост. № 354 Формула 20
-- =============================================
CREATE               PROCEDURE [dbo].[ka_add_F20]
	@bldn_id1		INT
	,@service_id1	VARCHAR(10) -- код услуги
	,@fin_id1		SMALLINT -- фин. период
	,@value_source1	DECIMAL(15, 6)	= 0 -- Объем теплоэнергии на подогрев по дому в Г/Калл
	,@tarif_otop	DECIMAL(10, 4)		= 0 -- тариф за Г/Калл
	,@tarif_hvs		DECIMAL(10, 4)		= 0 -- тариф за ХВС
	,@value_gvs		DECIMAL(15, 4)	= 0 -- Объем воды по прибору учёта, если есть
	,@value_gaz		DECIMAL(15, 4)	= 0 -- Объем газа на подогрев
	,@tarif_gaz		DECIMAL(10, 4)		= 0 -- тариф за ХВС
	,@value_ee		DECIMAL(15, 4)	= 0 -- Объем электроэнергии на подогрев
	,@tarif_ee		DECIMAL(10, 4)		= 0 -- тариф за ХВС
	,@value_arenda	DECIMAL(15, 4)	= 0 -- объём в нежелых помещениях
	,@doc1			VARCHAR(100)	= NULL -- Документ
	,@doc_no1		VARCHAR(15)		= NULL -- номер акта
	,@doc_date1		SMALLDATETIME	= NULL -- дата акта
	,@debug			BIT				= 0
	,@addyes		INT				= 0 OUTPUT -- если 1 то разовые добавили
	,@arenda_sq_no	BIT				= 0 -- 1- не учитывать площадь по нежилым помещениям
	,@sup_id		INT				= NULL

/*

Вызов процедуры:

DECLARE	@addyes int 
exec [dbo].ka_add_P354 @bldn_id1 = 2,@service_id1 = N'хвод',@fin_id1 = 128,
		@value_source1 = 630,@doc1 = N'Тест',@doc_no1=999, @debug=1, @addyes = @addyes OUTPUT,
		@volume_arenda=0,@serv_dom='хвсд',@flag=0
		
exec [dbo].[ka_add_F9] @bldn_id1 = 3508,@service_id1 = N'вотв',@fin_id1 = 121,
		@value_source1 = 768,@doc1 = N'Тест',@doc_no1=999, @debug=1, @ras_add=1, @addyes = @addyes OUTPUT		
		
*/
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE	@add_type1		TINYINT			= 11
			,@Vnr			DECIMAL(15, 4)
			,@Vnn			DECIMAL(15, 4)
			,@Vob			DECIMAL(15, 4)	= 0
			,@value_add_kol	DECIMAL(15, 4)	= 0
			,@occ			INT
			,@total_sq		DECIMAL(10, 4)
			,@arenda_sq		DECIMAL(10, 4)
			,@KolPeopleItog	SMALLINT
			,@i				INT				= 0
			,@comments		VARCHAR(200)	= ''
			,@tarif			DECIMAL(9, 4)
			,@sum_add		DECIMAL(15, 2)
			,@sum_value		DECIMAL(15, 2)
			,@ostatok		DECIMAL(9, 2)
			,@tip_id		SMALLINT
			,@fin_current	SMALLINT
			,@str_koef		VARCHAR(40)
			,@flat_id1		INT
			,@Formula		SMALLINT		= 18 -- номер формулы

	SELECT
		@addyes = 0
	IF @value_source1 IS NULL
		SET @value_source1 = 0

	IF @tarif_hvs IS NULL
		SET @tarif_hvs = 0
	IF @tarif_otop IS NULL
		SET @tarif_otop = 0
	IF @value_gvs IS NULL
		SET @value_gvs = 0

	IF @value_gaz IS NULL
		SET @value_gaz = 0
	IF @value_ee IS NULL
		SET @value_ee = 0
	IF @tarif_gaz IS NULL
		SET @tarif_gaz = 0
	IF @tarif_ee IS NULL
		SET @tarif_ee = 0

	IF @service_id1 IN ('гвод', 'гвс2')
		SET @Formula = 20

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL)

	DELETE pcb
		FROM dbo.PAYM_OCC_BUILD AS pcb 
		JOIN dbo.View_OCC_ALL AS o 
			ON pcb.fin_id = o.fin_id
			AND pcb.occ = o.occ
	WHERE pcb.fin_id = @fin_current
		AND service_id = @service_id1
		AND o.bldn_id = @bldn_id1

	IF @value_source1 < 0
		RETURN

	IF (@fin_current = @fin_id1)
		AND @doc_no1 <> '99999'
	BEGIN
		-- нужен перерасчёт по дому 
		DECLARE curs CURSOR LOCAL FOR
			SELECT
				voa.occ
				,voa.flat_id
			FROM dbo.VOcc AS voa 
			JOIN dbo.OCCUPATION_TYPES AS ot 
				ON voa.tip_id = ot.id			
			WHERE voa.status_id <> 'закр'
			AND voa.bldn_id = @bldn_id1
			AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
			ORDER BY occ

		OPEN curs
		FETCH NEXT FROM curs INTO @occ, @flat_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			-- расчитываем по внутренним счётчикам
			EXEC dbo.k_counter_raschet_flats2	@flat_id1
												,1
												,0

			-- Расчитываем квартплату
			EXEC dbo.k_raschet_1	@occ
									,@fin_current
			FETCH NEXT FROM curs INTO @occ, @flat_id1
		END

		CLOSE curs
		DEALLOCATE curs
	END

	SELECT
		@tip_id = tip_id
		,@arenda_sq = arenda_sq
	FROM View_build_all 
	WHERE fin_id = @fin_id1
	AND bldn_id = @bldn_id1

	DECLARE @t TABLE
		(
			occ				INT -- PRIMARY KEY
			,kol			DECIMAL(15, 4)	DEFAULT 0
			,kol_itog		DECIMAL(15, 4)	DEFAULT 0
			,is_counter		BIT				DEFAULT 0
			,total_sq		DECIMAL(10, 4)	DEFAULT 0
			,value			DECIMAL(9, 2)	DEFAULT 0
			,value_add		DECIMAL(9, 2)	DEFAULT 0
			,value_add_kol	DECIMAL(15, 4)	DEFAULT 0
			,sum_add		DECIMAL(9, 2)	DEFAULT 0
			,sum_value		DECIMAL(9, 2)	DEFAULT 0
			,kol_add		DECIMAL(15, 4)	DEFAULT 0
			,comments		VARCHAR(200)	DEFAULT ''
			,nom_kvr		VARCHAR(20)		DEFAULT ''
			,tarif			DECIMAL(10, 4)	DEFAULT 0
			,norma			DECIMAL(9, 2)	DEFAULT 0
			,metod			TINYINT			DEFAULT 0
			,unit_id		VARCHAR(10)		DEFAULT NULL
			,kol_people		TINYINT			DEFAULT 0
			,mode_id		INT				DEFAULT 0
			,source_id		INT				DEFAULT 0
			,kol_norma		DECIMAL(15, 4)	DEFAULT 0
			,sup_id INT DEFAULT 0
		)
	--IF @service_kol IS NULL SET @service_kol=@service_id1

	-- находим кол-во
	INSERT
	INTO @t
	(	occ
		,kol
		,is_counter
		,value
		,value_add
		,nom_kvr
		,metod
		,unit_id
		,kol_people
		,tarif
		,kol_norma
		,sup_id)
			SELECT
				ph.occ
				,SUM(COALESCE(ph.kol, 0))
				,ph.is_counter
				,SUM(ph.value)
				,COALESCE((SELECT
						SUM(value)
					FROM dbo.View_ADDED AS ap
					WHERE ap.occ = ph.occ
					AND ap.fin_id = @fin_id1
					AND ap.service_id = @service_id1
					AND add_type <> 11)
				, 0)
				,oh.nom_kvr
				,ph.metod
				,ph.unit_id
				,kol_people = COALESCE((SELECT
						COUNT(id)
					FROM dbo.PEOPLE AS P
					JOIN dbo.PERSON_CALC AS PC
						ON P.status2_id = PC.status_id
					WHERE P.occ = ph.occ
					AND P.Del = 0
					AND PC.service_id = @service_id1
					AND PC.have_paym = 1)
				, 0)
				,@tarif_hvs --tarif
				,ph.kol_norma
				,ph.sup_id
			FROM dbo.View_OCC_ALL AS oh 
			JOIN dbo.View_PAYM AS ph 
				ON oh.fin_id = ph.fin_id
				AND oh.occ = ph.occ
			WHERE oh.bldn_id = @bldn_id1
			AND oh.fin_id = @fin_id1
			AND ph.service_id = @service_id1
			AND (ph.sup_id=@sup_id OR @sup_id IS NULL)
			GROUP BY	ph.occ
						,ph.is_counter
						,oh.nom_kvr
						,ph.metod
						,ph.unit_id
						,ph.tarif
						,ph.kol_norma
						,ph.sup_id

	UPDATE t
	SET	mode_id		= cl.mode_id
		,source_id	= cl.source_id
	FROM @t AS t
	JOIN dbo.View_PAYM AS cl 
		ON t.occ = cl.occ
	WHERE cl.fin_id = @fin_id1
	AND cl.service_id = @service_id1
	AND cl.sup_id=t.sup_id

	UPDATE t
	SET	total_sq	= o.total_sq
		--, kol_itog = kol
		,kol_itog	= kol_norma
		,kol		= kol_norma
	FROM @t AS t
	JOIN dbo.OCCUPATIONS AS o 
		ON t.occ = o.occ

	DECLARE @unit_id VARCHAR(10)
	SELECT TOP 1
		@unit_id = unit_id
	FROM @t
	WHERE unit_id IS NOT NULL
	IF @unit_id IS NULL
		SET @unit_id = 'кубм'

	--IF @service_id1 IN ('отоп')
	--	SET @unit_id = 'ггкл'

	UPDATE t
	SET tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, t.occ, CASE
		WHEN @service_id1 = 'гвс2' THEN 'гвод'
		ELSE @service_id1
	END, @unit_id)
	FROM @t AS t
	WHERE tarif = 0
	OR tarif IS NULL

	SELECT TOP 1
		@tarif = COALESCE(tarif, 0)
	FROM @t
	ORDER BY tarif DESC

	UPDATE t
	SET norma = dbo.Fun_GetNormaSingle(@unit_id, t.mode_id, 1, @tip_id, @fin_id1)
	FROM @t AS t
	WHERE unit_id = 'люди'


	IF @tarif IS NULL
	BEGIN
		RAISERROR ('Не удалось определить тариф по услуге %s', 16, 1, @service_id1)
		RETURN
	END

	UPDATE t
	SET value_add_kol =
		CASE
			WHEN tarif > 0 THEN value_add / tarif
			ELSE value_add / @tarif
		END
	FROM @t AS t

	UPDATE t
	SET kol_itog = kol * norma
	FROM @t AS t
	WHERE unit_id = 'люди'

	IF @debug = 1
		SELECT
			COALESCE(SUM(kol_itog), 0) AS kol_itog
			,COALESCE(SUM(value_add_kol), 0) AS value_add_kol
			,COALESCE(SUM(kol), 0) AS kol
		FROM @t

	--UPDATE t
	--SET kol_itog = kol_itog + value_add_kol -- количество с учетом разовых
	--FROM @t AS t

	IF @debug = 1
		SELECT
			*
		FROM @t
		ORDER BY occ

	--IF @debug=1 SELECT COALESCE(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod is null
	--IF @debug=1 SELECT COALESCE(SUM(kol),0) FROM @t WHERE is_counter=0 AND metod=3
	--IF @debug=1 SELECT COALESCE(SUM(kol),0) FROM @t WHERE is_counter=1 or metod=3

	SELECT
		@total_sq = SUM(total_sq)
	FROM @t

	IF COALESCE(@arenda_sq_no, 0) = 0
		SET @total_sq = @total_sq + COALESCE(@arenda_sq, 0)

	SELECT
		@KolPeopleItog = SUM(kol_people)
	FROM @t

	SELECT
		@Vnn = COALESCE(SUM(kol_itog), 0)
	FROM @t
	WHERE is_counter = 0
	AND metod IS NULL
	SELECT
		@Vnr = COALESCE(SUM(kol_itog), 0)
	FROM @t
	WHERE is_counter = 1
	OR metod IN (2, 3, 4)

	SELECT
		@value_add_kol = SUM(value_add_kol)
	FROM @t AS t

	IF @Vnn = 0
		AND @Vnr = 0
	BEGIN
		RAISERROR ('Начислений по услуге %s не было', 16, 1, @service_id1)
		RETURN
	END

	IF @value_gvs = 0
		SELECT
			@Vob = @Vnn + @Vnr
	ELSE
		SELECT
			@Vob = @value_gvs

	SET @Vob = @Vob + COALESCE(@value_arenda, 0)

	IF @Vob > 0
		AND @Formula = 20
	BEGIN
		UPDATE t
		SET	sum_value	= kol * tarif + (@value_source1 * kol / @Vob * @tarif_otop) +
			(@value_gaz * kol / @Vob * @tarif_gaz) +
			(@value_ee * kol / @Vob * @tarif_ee)
			--SET kol_add = value+(@value_source1*kol/@Vob*@tarif_otop)
			,comments = CONCAT('Ф20: (',dbo.NSTR(kol),'*',dbo.NSTR(tarif)
			,'+(',dbo.NSTR(@value_source1),'*',dbo.NSTR(kol),'/',dbo.NSTR(@Vob),'*',dbo.NSTR(@tarif_otop)
			,')+(',dbo.NSTR(@value_gaz),'*',dbo.NSTR(kol),'/',dbo.NSTR(@Vob),'*',dbo.NSTR(@tarif_gaz)
			,')+(',dbo.NSTR(@value_ee),'*',dbo.NSTR(kol),'/',dbo.NSTR(@Vob),'*',dbo.NSTR(@tarif_ee),'))' )
		FROM @t AS t
	END

	IF @Vob > 0
		AND @Formula = 18
	BEGIN
		UPDATE t
		SET	sum_value	= (@value_source1 * total_sq / @total_sq * @tarif_otop) +
			(@value_gaz * total_sq / @total_sq * @tarif_gaz) +
			(@value_ee * total_sq / @total_sq * @tarif_ee)

			,comments	= CONCAT('Ф18: (',dbo.NSTR(@value_source1),'*',dbo.NSTR(total_sq),'/',dbo.NSTR(@total_sq),'*',dbo.NSTR(@tarif_otop)
			,')+(',dbo.NSTR(@value_gaz),'*',dbo.NSTR(total_sq),'/',dbo.NSTR(@total_sq),'*',dbo.NSTR(@tarif_gaz)
			,')+(',dbo.NSTR(@value_ee),'*',dbo.NSTR(total_sq),'/',dbo.NSTR(@total_sq),'*',dbo.NSTR(@tarif_ee),')' )
		FROM @t AS t
	END

	--UPDATE t
	--SET tarif = @tarif
	--FROM @t AS t
	--WHERE tarif = 0 AND
	--	sum_value <> 0

	UPDATE t
	SET tarif = sum_value / kol
	FROM @t AS t
	WHERE --tarif = 0 AND
	sum_value <> 0

	UPDATE t
	SET kol_add = kol --sum_value/tarif
	FROM @t AS t

	IF @debug = 1
		SELECT
			'@value_source1' = @value_source1
			,'@Vnn' = @Vnn
			,'@Vnr' = @Vnr
			,'@Vnn+@Vnr' = @Vob
			,'@value_add_kol' = @value_add_kol
			,'@tarif' = @tarif
			,'@tip_id' = @tip_id
			,'@fin_id1' = @fin_id1

	SELECT
		@sum_add = SUM(sum_add)
		,@sum_value = SUM(sum_value)
	FROM @t

	IF @debug = 1
		SELECT
			*
		FROM @t

	DECLARE	@user_edit1	SMALLINT
			,@sys_usr	CHAR(30)	= system_user;
	SELECT
		@user_edit1 = id
	FROM dbo.USERS
	WHERE login = @sys_usr

	BEGIN TRAN

		DELETE pcb
			FROM dbo.PAYM_OCC_BUILD AS pcb
			JOIN @t AS t
				ON pcb.occ = t.occ
		WHERE pcb.fin_id = @fin_current
			AND pcb.service_id = @service_id1

		INSERT
		INTO dbo.PAYM_OCC_BUILD
		(	fin_id
			,occ
			,service_id
			,kol
			,tarif
			,value
			,comments
			,unit_id
			,procedura
			,kol_add
			,metod_old)
				SELECT
					@fin_current
					, t.occ
					, @service_id1
					, t.kol_add
					, tarif
					, t.sum_value
					, SUBSTRING(comments, 1, 100)
					, @unit_id as unit_id
					, 'ka_add_F20' as procedura
					, 0 --t.kol_add
					, metod
				FROM @t AS t
				WHERE COALESCE(t.kol_add, 0) <> 0
		SELECT
			@addyes = @@rowcount

	COMMIT TRAN


END
go

