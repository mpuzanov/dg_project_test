-- =============================================
-- Author:		Пузанов
-- Create date: 09.12.2010
-- Description:	Раскидка суммы или кол-ва по лицевым на входе ДОМА
-- =============================================
CREATE      PROCEDURE [dbo].[ka_add_added_6]
(
	  @fin_id SMALLINT -- фин. период
	, @bldn_str1 VARCHAR(4000) -- строка формата: код дома;код дома
	, @service_id VARCHAR(10) -- код услуги
	, @summa DECIMAL(18, 6) -- сумма для раскидки по лицевым  (для количества нужно столько разрядов)
	, @metod SMALLINT -- 1 - по общей площади, 2 - по кол.человек на лицевом, 3 - по начислению, 4 - по количеству, 
	  -- 5 - по кол-ву лицевых, 6-по площади помещения, 7 - по площади л.сч и площади дома по паспорту
	, @doc1 VARCHAR(100) = '' -- документ (комментарий)
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @add_type1 SMALLINT = NULL -- вид перерасчета
	, @debug BIT = 0 -- показать отладочную информацию
	, @ras_add BIT = 1 -- расчёт разовых, 0-текущих начислений
	, @KolAdd INT = 0 OUTPUT -- количество добавленно
	, @service_kol VARCHAR(10) = NULL -- код услуги на основании которой делаем расчёт
	, @is_counter_metod SMALLINT = 0 -- 0-все лицевые, 1-только без счётчиков, 2-только со счётчиками
	, @is_ras_kol BIT = 0 -- 0-раскидка суммы, 1-раскидка количества
	, @tarif DECIMAL(15, 6) = NULL
	, @is_raschet BIT = NULL
	, @sup_id INT = NULL
	, @sup_id_kol INT = NULL
	, @is_kol_total_sq BIT = 0 -- устанавливать в кол-во площадь по л.сч (если раскидка не по кол-ву)
	, @repeat_for_fin	SMALLINT		= NULL-- повтор перерасчета по заданные период
)
AS
/*

exec ka_add_added_6 @fin_id=122, @bldn_str1='1',@service_id='элмп',@summa=7801,@metod=3,@doc1='тест',@debug=1,@ras_add=0,
@service_kol='элек',@is_counter_metod=0,@is_ras_kol=0

exec ka_add_added_6 @fin_id=125, @bldn_str1='33',@service_id='отоп',@summa=2.479,@metod=1,@doc1='тест',@debug=1,@ras_add=1,
@service_kol='отоп',@is_counter_metod=0,@is_ras_kol=1    

exec ka_add_added_6 @fin_id=181, @bldn_str1='3239',@service_id='гвод',@summa=-195.12,
@metod=3,@doc1='тест',@debug=1,@ras_add=1,@service_kol='гвод',@is_counter_metod=0,@is_ras_kol=1  

*/
BEGIN
	SET NOCOUNT ON;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF @tarif = 0
		SET @tarif = NULL

	IF @is_kol_total_sq = COALESCE(@is_kol_total_sq, 0)

	DECLARE @total_sq_bldn MONEY
		  , @area_bldn MONEY
		  , @build_total_area DECIMAL(10, 4)
		  , @kol_people_bldn INT
		  , @kol_occ_bldn INT	-- кол-во лицевых счетов
		  , @value_bldn DECIMAL(15, 2)
		  , @kol_bldn DECIMAL(12, 6)
		  , @unit_id VARCHAR(10) = NULL

	IF @add_type1 IS NULL
		SET @add_type1 = 10 -- тех.корректировка 	

	IF @service_kol IS NULL
		SET @service_kol = @service_id
	IF @sup_id_kol IS NULL
		SET @sup_id_kol = @sup_id

	-- Таблица с новыми значениями 
	DECLARE @t_bldn TABLE (
		  bldn_id INT
	)

	INSERT INTO @t_bldn
	SELECT *
	FROM STRING_SPLIT(@bldn_str1, ';')
	WHERE RTRIM(value) <> ''

	if @debug=1 
	BEGIN
		SELECT '@t_bldn' AS tbl,* FROM @t_bldn
		SELECT @fin_id AS fin_id, @service_kol AS service_kol, @sup_id_kol AS sup_id_kol
	END

	DECLARE @t TABLE (
		  occ INT PRIMARY KEY
		, flat_id INT
		, nom_kvr VARCHAR(20)
		, total_sq DECIMAL(10, 4)  -- площадь лицевого
		, area DECIMAL(10, 4)  -- площадь помещения(квартиры)
		, kol_people INT
		, value DECIMAL(9, 2) DEFAULT 0
		, kol_serv DECIMAL(12, 6) DEFAULT 0
		, summa_add DECIMAL(12, 2) DEFAULT 0
		, is_counter TINYINT DEFAULT 0
		, fin_current SMALLINT
		, tarif DECIMAL(15, 6) DEFAULT 0
		, kol DECIMAL(12, 6) DEFAULT 0
		, unit_id VARCHAR(10) DEFAULT NULL
		, tip_id SMALLINT DEFAULT NULL
		, roomtype_id VARCHAR(10) DEFAULT NULL
		, [PRECISION] TINYINT DEFAULT 2--точность округления(количество знаков после запятой)
		, mode_id INT DEFAULT NULL
		, comments VARCHAR(70) DEFAULT NULL
		, koef_day DECIMAL(10, 4) DEFAULT 1
		, build_total_area DECIMAL(10, 4) DEFAULT 0 -- Общая площадь дома по паспорту
		, date_start SMALLDATETIME DEFAULT NULL
		, date_end SMALLDATETIME DEFAULT NULL
	)

	INSERT INTO @t (occ
				  , flat_id
				  , nom_kvr
				  , total_sq
				  , area
				  , kol_people
				  , is_counter
				  , fin_current
				  , tip_id
				  , roomtype_id
				  , mode_id
				  , koef_day
				  , build_total_area
				  , date_start
				  , date_end
				  , unit_id)
	SELECT o.occ
		 , f.id
		 , f.nom_kvr
		 , o.total_sq
		 , f.area
		 , COALESCE((
			   SELECT COUNT(p.owner_id)
			   FROM dbo.View_people_all AS p 
				   JOIN dbo.Person_calc AS pс ON 
					p.status2_id = pс.status_id
			   WHERE p.occ = o.occ
				   AND pс.have_paym = CAST(1 AS BIT)
				   AND pс.service_id = @service_kol
				   AND p.fin_id = o.fin_id
		   ), 0) as kol_people
		 , is_counter = COALESCE(p.is_counter, 0)
		 , B.fin_current
		 , o.tip_id
		 , o.roomtype_id
		 , p.mode_id
		 , COALESCE(p.koef_day,1) as koef_day
		 , COALESCE(b.build_total_area, 0) as build_total_area
		 , o1.date_start
		 , o1.date_end
		 , p.unit_id
	FROM dbo.View_occ_all AS o 
		JOIN @t_bldn AS t ON 
			o.bldn_id = t.bldn_id
		JOIN dbo.Occupations AS o1 ON 
			o.occ = o1.occ
		JOIN dbo.Flats f ON 
			o1.flat_id = f.id
		JOIN dbo.Buildings B ON 
			f.bldn_id = B.id		
		LEFT JOIN dbo.View_paym AS p ON 
			o.occ = p.occ
			AND o.fin_id = p.fin_id
			AND p.service_id = @service_kol
			AND (p.sup_id = @sup_id_kol OR @sup_id_kol IS NULL)
	WHERE o.fin_id = @fin_id
		AND o.status_id <> 'закр'
		AND o1.status_id <> 'закр' -- чтобы в текущем месяце тоже были открыты	
	
	if @debug=1 select '@t после зазрузки' as tbl ,* from @t ORDER BY dbo.Fun_SortDom(nom_kvr)

	-- удаление строк по дате начала и окончания лицевого счета
	DELETE o1
	FROM @t AS o1
		JOIN dbo.Calendar_period AS cp ON cp.fin_id=@fin_id
	WHERE o1.date_start>cp.end_date
		OR o1.date_end<cp.[start_date]

	IF @service_kol IN ('вотв', 'гвс2', 'хвс2')
	BEGIN
		UPDATE t
		SET is_counter = 1
		FROM @t AS t
		WHERE is_counter = 0
			AND EXISTS (
				SELECT 1
				FROM dbo.View_paym AS cl
				WHERE cl.fin_id = @fin_id
					AND cl.occ = t.occ
					AND cl.is_counter > 0
					AND cl.service_id IN ('хвод', 'гвод')
			)
	END

	IF @is_counter_metod = 2
		DELETE FROM @t
		WHERE is_counter = 0
			OR is_counter IS NULL

	IF @is_counter_metod = 1
		DELETE FROM @t
		WHERE is_counter > 0

	--**********************************************************************
	UPDATE t
	SET unit_id = su.unit_id
	FROM @t t
		JOIN dbo.Service_units su ON t.roomtype_id = su.roomtype_id
			AND t.tip_id = su.tip_id
	WHERE su.service_id = @service_id
		AND su.fin_id = @fin_id
		AND t.unit_id IS NULL

	UPDATE t
	SET unit_id = cm.unit_id
	FROM @t t
		JOIN dbo.Cons_modes AS cm ON t.mode_id = cm.id
	WHERE cm.unit_id IS NOT NULL
		AND cm.service_id = @service_id
		AND t.unit_id IS NULL

	SELECT @unit_id = unit_id
	FROM dbo.Service_units_counter 
	WHERE service_id = @service_id

	UPDATE t SET unit_id = @unit_id	FROM @t AS t WHERE t.unit_id IS NULL
	--**********************************************************************

	UPDATE t
	SET [PRECISION] = u.[PRECISION]
	FROM @t AS t
		JOIN dbo.Units AS u ON t.unit_id = u.id

	IF @metod IN (3, 4)
	BEGIN
		UPDATE t1
		SET value = p.value
		  , kol_serv = p.kol
		FROM @t AS t1
			JOIN dbo.View_paym AS p ON t1.occ = p.occ
				AND p.fin_id = @fin_id
				AND p.service_id = @service_kol
				AND (p.sup_id = @sup_id_kol OR @sup_id_kol IS NULL)
	END

	IF @tarif IS NOT NULL
		UPDATE @t
		SET tarif = @tarif
		--WHERE tarif = 0
	ELSE
		UPDATE t1
		SET tarif = p.tarif
		FROM @t AS t1
			JOIN dbo.View_paym AS p ON t1.occ = p.occ
				AND p.fin_id = @fin_id
				AND p.service_id = @service_id
				AND (p.sup_id = @sup_id OR @sup_id IS NULL)

	-- Если раскидка на колличество то тариф должен быть
	IF @is_ras_kol = 1
		DELETE FROM @t
		WHERE tarif = 0

	IF @metod IN (1, 6) -- по площади, чтобы даже остаток не раскидывался
		DELETE FROM @t
		WHERE total_sq = 0 
			OR tarif=0 -- 22.08.22

	SELECT @total_sq_bldn = SUM(CAST(total_sq*koef_day AS DECIMAL(12,2))) --14.12.2022 SUM(total_sq)
		 , @area_bldn = SUM(area)
		 , @kol_people_bldn = SUM(kol_people)
		 , @value_bldn = SUM(value)
		 , @kol_bldn = SUM(kol_serv)
		 , @kol_occ_bldn = COUNT(occ) -- SUM(CASE WHEN tarif>0 THEN 1 ELSE 0 END)
	FROM @t

	;
	WITH cte AS
	(
		SELECT DISTINCT flat_id
					  , area
		FROM @t
	)
	SELECT @area_bldn = SUM(area)
	FROM cte


	IF @debug = 1
		SELECT '@total_sq_bldn' = @total_sq_bldn
			 , '@area_bldn' = @area_bldn
			 , '@kol_people' = @kol_people_bldn
			 , '@value_bldn' = @value_bldn
			 , '@kol_bldn' = @kol_bldn
			 , '@metod' = @metod
			 , '@summa' = @summa
			 , '@is_ras_kol' = @is_ras_kol
			 , '@tarif' = @tarif


	DECLARE @occ INT
		  , @total_sq DECIMAL(12, 6)
		  , @area DECIMAL(12, 6)
		  , @kol_people INT
		  , @summa_add DECIMAL(15, 6)
		  , @value DECIMAL(9, 2)
		  , @kol DECIMAL(12, 6)
		  , @koef_day DECIMAL(10, 4)
		  , @comments VARCHAR(70) = ''

	DECLARE curs CURSOR LOCAL FOR
		SELECT occ
			 , total_sq
			 , area
			 , kol_people
			 , value
			 , kol_serv
			 , koef_day
			 , build_total_area
		FROM @t
	OPEN curs
	FETCH NEXT FROM curs INTO @occ, @total_sq, @area, @kol_people, @value, @kol, @koef_day, @build_total_area

	WHILE (@@fetch_status = 0)
	BEGIN

		IF @metod = 1  -- площадь
		BEGIN
			--print str(@summa * @total_sq/@total_sq_bldn,9,4)
			if @koef_day<>1
				SET @total_sq = CAST(@total_sq * @koef_day AS DECIMAL(9,2))
			IF @total_sq_bldn > 0
				SELECT @summa_add = @summa * @total_sq/ @total_sq_bldn
		END

		IF @metod = 2  -- граждане
		BEGIN
			IF @kol_people_bldn <> 0
				SELECT @summa_add = @summa * @kol_people / @kol_people_bldn
		END

		IF @metod = 3  -- начисления
		BEGIN
			IF @value_bldn <> 0
				SELECT @summa_add = @summa * @value / @value_bldn
		--print @summa_add
		END

		IF @metod = 4  -- объём услуги
		BEGIN
			IF @kol_bldn <> 0
				SELECT @summa_add = @summa * @kol / @kol_bldn
		END

		IF @metod = 5 -- по кол-ву лицевых 
		BEGIN
			IF @kol_occ_bldn <> 0
				SELECT @summa_add = @summa / @kol_occ_bldn
		END

		IF @metod = 6  -- 6-по площади помещения
		BEGIN
			IF @area_bldn > 0
				SELECT @summa_add = @summa * (@area / @area_bldn) * @koef_day * (@total_sq / @area)
		END

		IF @metod = 7  -- по площади л.сч и площади дома по паспорту
		BEGIN
			IF @build_total_area = 0
				SET @build_total_area = @total_sq_bldn
			SELECT @summa_add = @summa * @total_sq / @build_total_area
		END

		SET @comments = 'Раскидка (М:' + STR(@metod, 1) + ')=' + LTRIM(dbo.FSTR(@summa, 9, 4))
		SET @comments =
					   CASE
						   WHEN @metod = 1 THEN @comments + '*(' + LTRIM(dbo.FSTR(@total_sq, 9, 2)) + '/' + LTRIM(dbo.FSTR(@total_sq_bldn, 10, 2)) + ')'
						   WHEN @metod = 2 THEN @comments + '*(' + LTRIM(STR(@kol_people)) + '/' + LTRIM(STR(@kol_people_bldn)) + ')'
						   WHEN @metod = 3 THEN @comments + '*(' + LTRIM(dbo.FSTR(@value, 9, 2)) + '/' + LTRIM(dbo.FSTR(@value_bldn, 9, 2)) + ')'
						   WHEN @metod = 4 THEN @comments + '*(' + LTRIM(dbo.FSTR(@kol, 9, 2)) + '/' + LTRIM(dbo.FSTR(@kol_bldn, 9, 2)) + ')'
						   WHEN @metod = 5 THEN @comments + '/' + LTRIM(dbo.FSTR(@kol_occ_bldn, 9, 2))
						   WHEN @metod = 6 THEN @comments + '*(' + LTRIM(dbo.FSTR(@area, 9, 2)) + '/' + LTRIM(dbo.FSTR(@area_bldn, 10, 2)) + ')'
							   + '*' + LTRIM(dbo.FSTR(@koef_day, 10, 4)) + '*(' + LTRIM(dbo.FSTR(@total_sq, 9, 2)) + '/' + LTRIM(dbo.FSTR(@area, 9, 2)) + ')'
						   WHEN @metod = 7 THEN @comments + '*(' + LTRIM(dbo.FSTR(@total_sq, 9, 2)) + '/' + LTRIM(dbo.FSTR(@build_total_area, 10, 2)) + ')'
					   END

		UPDATE @t
		SET kol =
				 CASE
					 WHEN (@is_ras_kol = 1) THEN @summa_add
					 ELSE 0
				 END
		  , summa_add =
					   CASE
						   WHEN (@is_ras_kol = 0) THEN @summa_add
						   ELSE 0
					   END
		  , comments = @comments
		WHERE occ = @occ

		FETCH NEXT FROM curs INTO @occ, @total_sq, @area, @kol_people, @value, @kol, @koef_day, @build_total_area
	END
	CLOSE curs;
	DEALLOCATE curs;

	IF @is_ras_kol = 1
	BEGIN
		UPDATE @t SET summa_add = kol * tarif
	END
	ELSE
		UPDATE @t SET kol = CASE WHEN(tarif > 0) THEN summa_add / tarif ELSE 0 END

	--if @debug=1 select * from @t
	IF @debug = 1
		SELECT SUM(summa_add) AS summa_add
			 , SUM(kol) AS kol_add
		FROM @t 

	-- Проверяем остатки ================================================================================
	DECLARE @ostatok DECIMAL(12, 6) = 0

	SELECT @ostatok =
		SUM(CASE
			WHEN (@is_ras_kol = 1) THEN kol
			ELSE summa_add
		END)
	FROM @t

	IF @debug = 1
	BEGIN
		PRINT '@summa:' + STR(@summa, 15, 6) + ' @ostatok:' + STR(@ostatok, 12, 6)
	END

	SET @ostatok = @summa - @ostatok
	IF @ostatok <> 0 AND @metod not in (7)  -- в методе 7 остаток может не сходиться
	BEGIN
		IF @debug = 1
			PRINT 'Остаток:' + STR(@ostatok, 12, 6) + ', раскидка по ' + CASE WHEN(@is_ras_kol = 1) THEN 'количеству' ELSE 'сумме' END

		IF (@is_ras_kol = 1)
		BEGIN
			UPDATE c
			SET kol = kol + @ostatok
			FROM (
				SELECT TOP (1) *
				FROM @t
				ORDER BY ABS(kol) DESC
			) c
			UPDATE @t SET summa_add = kol * tarif
		END
		ELSE
		BEGIN
			UPDATE c
			SET summa_add = summa_add + @ostatok
			FROM (
				SELECT TOP (1) *
				FROM @t
				ORDER BY ABS(summa_add) DESC
			) c
			UPDATE @t SET kol = CASE WHEN(tarif > 0) THEN summa_add/tarif ELSE 0 END
		END

	END
	--=========================================================================

	DECLARE @user_edit1 SMALLINT = dbo.Fun_GetCurrentUserId()

	IF @is_ras_kol = 0 AND @is_kol_total_sq=1
		UPDATE @t SET kol = total_sq

	IF @is_ras_kol = 0
		UPDATE @t SET kol = ROUND(kol, [PRECISION])
		
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
									  , fin_id
									  , comments
									  , kol
									  , repeat_for_fin)
		SELECT occ
			 , @service_id
			 , COALESCE(@sup_id, 0)
			 , @add_type1
			 , @doc1
			 , summa_add
			 , @doc_no1
			 , @doc_date1
			 , @user_edit1
			 , @fin_id
			 , t.fin_current
			 , comments
			 , kol
			 , @repeat_for_fin
		FROM @t AS t
		WHERE summa_add <> 0
		SELECT @KolAdd = @@rowcount

		-- Изменить значения в таблице paym_list
		UPDATE pl
		SET added = COALESCE(t_add.val, 0), kol_added = COALESCE(t_add.kol,0)
		FROM dbo.Paym_list AS pl
			JOIN @t AS t ON pl.occ = t.occ
				AND pl.fin_id = t.fin_current
			CROSS APPLY (SELECT SUM(ap.value) as val, SUM(COALESCE(ap.kol,0)) AS kol
						FROM dbo.Added_Payments ap
						WHERE ap.occ = pl.occ
							AND ap.service_id = pl.service_id
							AND ap.fin_id = pl.fin_id
							AND ap.sup_id = pl.sup_id) AS t_add
		WHERE pl.service_id = @service_id

	END
	ELSE
	BEGIN

		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb
			JOIN @t AS t ON pcb.occ = t.occ
				AND pcb.fin_id = t.fin_current
		WHERE pcb.service_id = @service_id

		INSERT INTO dbo.Paym_occ_build (fin_id
									  , occ
									  , service_id
									  , kol
									  , tarif
									  , value
									  , comments
									  , unit_id
									  , procedura
									  , koef_day)
		SELECT t.fin_current
			 , t.occ
			 , @service_id
			 , COALESCE(kol, 0) AS kol
			 , tarif
			 , COALESCE(t.summa_add, 0)
			 , comments
			 , unit_id
			 , 'ka_add_added_6' AS procedura
			 , koef_day
		FROM @t AS t
		--WHERE summa_add<>0
		SELECT @KolAdd = @@rowcount

	END

	COMMIT TRAN

	IF @debug = 1
		SELECT *
		FROM @t
		ORDER BY dbo.Fun_SortDom(nom_kvr)
			   , occ

	IF @debug = 1
		SELECT SUM(summa_add) AS summa_add
			 , SUM(kol) AS kol_add
		FROM @t

	IF COALESCE(@is_raschet, 0) = 0
		RETURN

	IF @debug = 1
		PRINT 'делаем перерасчёт по домам'
	DECLARE @var1 INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT t.bldn_id
		FROM @t_bldn AS t
	OPEN cur
	FETCH NEXT FROM cur INTO @var1
	WHILE @@fetch_status = 0
	BEGIN

		EXEC dbo.k_raschet_build @var1, 0

		FETCH NEXT FROM cur INTO @var1
	END
	CLOSE cur;
	DEALLOCATE cur;

END
go

