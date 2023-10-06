-- =============================================
-- Author:		Пузанов
-- Create date: 02.02.2011
-- Description:	Раскидка суммы или кол-ва по лицевым
-- =============================================
CREATE     PROCEDURE [dbo].[ka_add_added_7]
(
	  @fin_id SMALLINT -- фин. период
	, @occ_str1 VARCHAR(4000) -- строка формата: Лицевой;Лицевой
	, @service_id VARCHAR(10) -- код услуги
	, @summa DECIMAL(15, 6) -- сумма для раскидки по лицевым
	, @metod SMALLINT -- 1 - по общей площади, 2 - по кол.человек на лицевом, 3 - по начислению, 4 - по количеству(объём услуги), 
	  -- 5 - по кол-ву лицевых, 6-по площади помещения
	, @doc1 VARCHAR(100) = NULL -- документ (комментарий)
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
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

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
		  , @kol_occ_bldn INT	-- кол-во лицевых счетов (выбранных)
		  , @value_bldn DECIMAL(9, 2)
		  , @kol_bldn DECIMAL(12, 6)
		  , @unit_id VARCHAR(10) = NULL

	IF @add_type1 IS NULL
		SET @add_type1 = 10 -- тех.корректировка 		

	IF @service_kol IS NULL
		SET @service_kol = @service_id
	IF @sup_id_kol IS NULL
		SET @sup_id_kol = @sup_id

	-- Таблица с новыми значениями 
	DECLARE @t_occ TABLE (
		  occ INT
	)

	INSERT INTO @t_occ
	SELECT *
	FROM STRING_SPLIT(@occ_str1, ';')
	WHERE RTRIM(value) <> ''


	IF @debug=1 SELECT '@t_occ' AS tbl, * FROM @t_occ

	DECLARE @t TABLE (
		  occ INT PRIMARY KEY
		, flat_id INT
		, nom_kvr VARCHAR(20)
		, total_sq MONEY
		, area MONEY  -- площадь помещения(квартиры)
		, kol_people INT
		, value DECIMAL(9, 2) DEFAULT 0
		, kol_serv DECIMAL(12, 6) DEFAULT 0
		, summa_add DECIMAL(12, 2) DEFAULT 0
		, is_counter TINYINT DEFAULT 0
		, fin_current SMALLINT
		, tarif DECIMAL(15, 6) DEFAULT 0
		, kol DECIMAL(12, 6) DEFAULT 0
		, unit_id VARCHAR(10) DEFAULT NULL
		, comments VARCHAR(70) DEFAULT NULL
		, mode_id INT DEFAULT NULL
		, source_id INT DEFAULT NULL
		, koef_day DECIMAL(10, 4) DEFAULT 1
		, build_total_area DECIMAL(10, 4) DEFAULT 0 -- Общая площадь дома по паспорту
		, [PRECISION] TINYINT DEFAULT 2--точность округления(количество знаков после запятой)
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
				  , mode_id
				  , source_id
				  , koef_day
				  , build_total_area
				  , date_start
				  , date_end
				  , unit_id)
	SELECT o.occ
		 , f.id
		 , f.nom_kvr_sort
		 , o.total_sq
		 , f.area
		 , kol_people = COALESCE((
			   SELECT COUNT(p.owner_id)
			   FROM dbo.View_people_all AS p 
				   JOIN dbo.Person_calc AS pс ON p.status2_id = pс.status_id
			   WHERE p.occ = o.occ
				   AND pс.have_paym = 1
				   AND pс.service_id = @service_kol
				   AND p.fin_id = o.fin_id
		   ), 0)
		 , COALESCE(p.is_counter, 0) AS is_counter
		 , b.fin_current
		 , p.mode_id
		 , p.source_id
		 , coalesce(p.koef_day,1) as koef_day 
		 , coalesce(b.build_total_area, 0) as build_total_area
		 , o1.date_start
		 , o1.date_end
		 , p.unit_id
	FROM dbo.View_occ_all AS o 
		JOIN dbo.Occupations AS o1  ON o.occ = o1.occ
		JOIN dbo.Flats f ON o1.flat_id = f.id
		JOIN dbo.Buildings B ON f.bldn_id = B.id
		JOIN @t_occ AS t ON o.occ = t.occ
		JOIN dbo.Occupation_Types OT ON o1.tip_id = OT.id
		LEFT JOIN dbo.View_paym AS p ON o.occ = p.occ
			AND o.fin_id = p.fin_id
			AND p.service_id = @service_kol
			AND (p.sup_id = @sup_id_kol OR @sup_id_kol IS NULL)
	WHERE o.fin_id = @fin_id
		AND o.status_id <> 'закр'
		AND o1.status_id <> 'закр' -- чтобы в текущем месяце тоже были открыты

	IF @debug=1 select '@t после зазрузки' as tbl ,* from @t ORDER BY dbo.Fun_SortDom(nom_kvr)

	-- удаление строк по дате начала и окончания лицевого счета
	DELETE o1
	FROM @t AS o1
		JOIN dbo.Calendar_period AS cp  ON cp.fin_id=@fin_id
	WHERE o1.date_start>cp.end_date
		OR o1.date_end<cp.[start_date]
	
	IF @debug=1 SELECT '@t after delete' AS tbl, count(*) as [count_record] FROM @t

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
	
	-- берём ед.изм. по умолчанию
	SELECT @unit_id = unit_id
	FROM dbo.Service_units_counter 
	WHERE service_id = @service_id

	-- с учётом режима на лицевом надо проставить еденицы потребления
	UPDATE t
	SET unit_id = COALESCE(cm.unit_id, @unit_id)
	FROM @t t
		LEFT JOIN dbo.Cons_modes cm ON t.mode_id = cm.id
	WHERE t.unit_id IS NULL

	UPDATE t SET unit_id = @unit_id	FROM @t AS t WHERE t.unit_id IS NULL
	--****************************************************************

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
		UPDATE @t SET tarif = @tarif
	--WHERE tarif = 0
	ELSE
		UPDATE t1
		SET tarif = p.tarif
		FROM @t AS t1
			JOIN dbo.View_paym AS p ON t1.occ = p.occ
				AND p.fin_id = @fin_id
				AND p.service_id = @service_id
				AND (p.sup_id = @sup_id OR @sup_id IS NULL)		

	IF @metod IN (1, 6) -- по площади, чтобы даже остаток не раскидывался
		DELETE FROM @t
		WHERE total_sq = 0
		OR (tarif=0 AND mode_id%1000=0) -- 22.08.22

	IF @debug = 1
		SELECT '@t' AS tbl, * FROM @t

	-- Если раскидка на колличество то тариф должен быть
	IF @is_ras_kol = 1
		DELETE FROM @t
		WHERE tarif = 0

	SELECT @total_sq_bldn = SUM(CAST(total_sq*koef_day AS DECIMAL(12,2))) --14.12.2022 SUM(total_sq)
		 , @kol_people_bldn = SUM(kol_people)
		 , @value_bldn = SUM(value)
		 , @kol_bldn = SUM(kol_serv)
		 , @kol_occ_bldn = COUNT(occ)
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
		SELECT @total_sq_bldn AS '@total_sq'
			 , @area_bldn AS '@area_bldn'
			 , @kol_people_bldn AS '@kol_people'
			 , @value_bldn AS '@value_bldn'
			 , @kol_bldn AS '@kol_bldn'
			 , @kol_occ_bldn AS '@kol_occ_bldn'
			 , @metod AS '@metod'
			 , @summa AS '@summa'
			 , @is_ras_kol AS '@is_ras_kol'
			 , @tarif AS '@tarif'

	DECLARE @occ INT
		  , @total_sq DECIMAL(12, 6)
		  , @area DECIMAL(12, 6)
		  , @kol_people INT
		  , @summa_add DECIMAL(15, 6)
		  , @value DECIMAL(9, 2)
		  , @kol DECIMAL(12, 6)
		  , @comments VARCHAR(70) = ''
		  , @koef_day DECIMAL(10, 4)

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

		IF @metod = 1
		BEGIN
			if @koef_day<>1
				SET @total_sq = CAST(@total_sq * @koef_day AS DECIMAL(9,2))
			IF @total_sq_bldn <> 0
				SELECT @summa_add = @summa * @total_sq / @total_sq_bldn
		END

		IF @metod = 2
		BEGIN
			IF @kol_people_bldn <> 0
				SELECT @summa_add = @summa * @kol_people / @kol_people_bldn
		END

		IF @metod = 3
		BEGIN
			IF @value_bldn <> 0
				SELECT @summa_add = @summa * @value / @value_bldn
		END

		IF @metod = 4
		BEGIN
			IF @kol_bldn <> 0
				SELECT @summa_add = @summa * @kol / @kol_bldn
		END

		IF @metod = 5
		BEGIN
			IF @kol_occ_bldn <> 0
				SELECT @summa_add = @summa / @kol_occ_bldn
		END

		IF @metod = 6
		BEGIN
			IF @area_bldn <> 0
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

	CLOSE curs
	DEALLOCATE curs

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

	-- Проверяем остатки
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

			UPDATE @t SET kol = CASE WHEN (tarif > 0) THEN summa_add/tarif ELSE 0 END
		END

		IF @debug = 1
			SELECT SUM(summa_add) AS summa_add_ostatok
				 , SUM(kol) AS kol_add_ostatok
			FROM @t
	END

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
									  , fin_id
									  , fin_id_paym
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
			 , t.fin_current
			 , @fin_id
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
			CROSS APPLY (SELECT SUM(ap.value) as val, sum(coalesce(ap.kol,0)) AS kol
						FROM dbo.Added_Payments ap 
						WHERE ap.occ = pl.occ
							AND ap.service_id = pl.service_id
							AND ap.fin_id = pl.fin_id
							AND ap.sup_id = pl.sup_id) AS t_add
		WHERE pl.service_id = @service_id;

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
			 , procedura = 'ka_add_added_7'
			 , t.koef_day
		FROM @t AS t
		--WHERE summa_add<>0
		SELECT @KolAdd = @@rowcount

	END

	COMMIT TRAN

	IF @debug = 1
		SELECT t.*
			 , SUM(summa_add) OVER () AS 'sum_add_itog'
			 , SUM(kol) OVER () AS sum_kol_add
		FROM @t t
		ORDER BY dbo.Fun_SortDom(nom_kvr)

	IF COALESCE(@is_raschet, 0) = 0
		RETURN

	-- делаем перерасчёт если надо
	DECLARE @var1 INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT t.occ
		FROM @t_occ AS t

	OPEN cur

	FETCH NEXT FROM cur INTO @var1

	WHILE @@fetch_status = 0
	BEGIN

		EXEC dbo.k_raschet_1 @occ1 = @var1
						   , @fin_id1 = @fin_id

		FETCH NEXT FROM cur INTO @var1

	END

	CLOSE cur
	DEALLOCATE cur


END
go

