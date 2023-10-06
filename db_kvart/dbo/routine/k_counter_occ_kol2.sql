-- =============================================
-- Author:		Пузанов
-- Create date: 02.03.2011
-- Description:	Раскидка потребения услуги по счетчику по лицевым счетам
-- =============================================
CREATE         PROCEDURE [dbo].[k_counter_occ_kol2]
	@flat_id1	 INT -- код квартиры
   ,@service_id1 VARCHAR(10) -- услуга
   ,@tip_value1	 SMALLINT = 1 -- 1-показания квартиросъемщика, 0-инспектора
   ,@debug		 BIT	  = 0
   ,@fin_current SMALLINT = NULL
AS
/*

exec k_counter_occ_kol2 300343,'хвод',1,1

exec k_counter_occ_kol2 74158,'элек',1,0

*/
BEGIN
	SET NOCOUNT ON;

	IF @debug = 1
		PRINT 'k_counter_occ_kol ' + @service_id1;

	DECLARE @fin_start	 SMALLINT
		   ,@counter_id1 INT;

	IF @fin_current IS NULL
		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, @flat_id1, NULL);
	SET @fin_start = @fin_current - 36;

	--DECLARE @t1 TABLE
	CREATE TABLE #t1
	(
		fin_id	   SMALLINT
	   ,counter_id INT
	   ,kol		   DECIMAL(9, 4)
	   ,value	   DECIMAL(12, 4)
	   ,kol_occ	   SMALLINT
	);

	-- список л/сч по квартире и услуге
	--DECLARE @t2 TABLE
	CREATE TABLE #t2
	(
		fin_id		SMALLINT
	   ,counter_id  INT
	   ,occ			INT
	   ,service_id  VARCHAR(10) COLLATE database_default
	   ,tip_value   TINYINT
	   ,kol			DECIMAL(9, 4) DEFAULT 0
	   ,value		DECIMAL(9, 2) DEFAULT 0
	   ,total_sq	DECIMAL(10, 4) DEFAULT 0
	   ,kol_people  SMALLINT	  DEFAULT 0
	   ,value_norma DECIMAL(9, 2) DEFAULT 0
	   ,PRIMARY KEY (fin_id, counter_id, occ, service_id, tip_value)
	--CREATE INDEX fin_id ON (fin_id)
	);

	INSERT INTO #t1 
	(fin_id
	,counter_id
	,kol
	,value)
		SELECT
			cp.fin_id
		   ,c.id
		   ,COALESCE(SUM(kol_day * value_vday), 0) AS kol
		   ,COALESCE(SUM(VALUE), 0) AS VALUE
		FROM dbo.COUNTERS AS c 
		JOIN dbo.COUNTER_PAYM AS cp 
			ON c.id = cp.counter_id
		WHERE c.flat_id = @flat_id1
		AND c.service_id = @service_id1
		AND cp.tip_value = @tip_value1
		AND cp.fin_id > @fin_start
		GROUP BY cp.fin_id
				,c.id
		OPTION (RECOMPILE)
	--,c.flat_id
	--,c.service_id

	UPDATE t
	SET kol_occ = COALESCE((SELECT
			COUNT(DISTINCT occ) AS kol_occ
		FROM dbo.Counter_list_all AS CLA 
		WHERE CLA.counter_id = t.counter_id
		AND CLA.fin_id = t.fin_id
	--GROUP BY CLA.fin_id
	)
	, 0)
	FROM #t1 AS t
	WHERE t.fin_id > @fin_start

	IF @debug = 1
		SELECT
			'#t1' AS tabl
		   ,*
		FROM #t1;

	INSERT INTO #t2 
		SELECT DISTINCT
			t.fin_id
		   ,t.counter_id
		   ,o.occ
		   ,@service_id1 AS service_id
		   ,@tip_value1 AS tip_value
		   ,t1.kol AS kol
		   ,t1.value AS value
		   ,o.total_sq
		   ,o.kol_people
		   ,0 AS value_norma
		FROM dbo.Occupations AS o 
		JOIN dbo.Counter_list_all AS t
			ON o.occ = t.occ
		JOIN #t1 AS t1
			ON t.counter_id = t1.counter_id
			AND t.fin_id = t1.fin_id
		WHERE 
			o.flat_id = @flat_id1
			AND o.STATUS_ID <> 'закр'
			AND t.fin_id = @fin_current

	IF EXISTS (SELECT
				*
			FROM #t1
			WHERE kol_occ > 1)
	BEGIN
		IF @debug = 1
			PRINT 'надо раскидывать по лицевым';

		DECLARE @kol_occ		 TINYINT
			   ,@sum_value_norma DECIMAL(10, 2)
			   ,@ostatok		 DECIMAL(9, 2) = 0;
		DECLARE @sum_total_sq DECIMAL(10, 4)
			   ,@kol_people	  TINYINT
			   ,@fin_id1	  SMALLINT
			   ,@sum_value	  DECIMAL(9, 2);

		DECLARE curs1 CURSOR LOCAL FOR
			SELECT
				fin_id
			   ,counter_id
			   ,value
			   ,kol_occ
			FROM #t1
			WHERE kol_occ > 1;
		OPEN curs1;
		FETCH NEXT FROM curs1 INTO @fin_id1, @counter_id1, @sum_value, @kol_occ;
		WHILE (@@fetch_status = 0)
		BEGIN

			SELECT
				@sum_total_sq = SUM(total_sq)
			   ,@kol_people = SUM(kol_people)
			   ,@sum_value_norma = SUM(value_norma)
			FROM #t2
			WHERE fin_id = @fin_id1
			AND counter_id = @counter_id1

			IF @debug = 1
				SELECT
					'@fin_id1' = @fin_id1
				   ,'@sum_total_sq' = @sum_total_sq
				   ,'@kol_people' = @kol_people
				   ,'@sum_value_norma' = @sum_value_norma
				   ,'@kol_occ' = @kol_occ;
			--IF @debug=1 SELECT * FROM @t2 WHERE fin_id=@fin_id1

			IF @service_id1 = 'отоп'
			BEGIN
				IF @debug = 1
					PRINT 'раскидываем по площади ' + STR(@sum_total_sq, 9, 2)
				UPDATE t
				SET kol	  = kol * total_sq / @sum_total_sq
				   ,value = value * total_sq / @sum_total_sq
				FROM #t2 AS t
				WHERE fin_id = @fin_id1
				AND counter_id = @counter_id1
			END
			ELSE
			--IF @service_id1 = 'элек'
			--	AND @sum_value_norma != 0
			--BEGIN
			--	IF @debug = 1
			--		PRINT 'раскидываем по начислению по норме ' + STR(@sum_value_norma, 9, 2)
			--	UPDATE t
			--	SET kol	  = kol * value_norma / @sum_value_norma
			--	   ,value = value * value_norma / @sum_value_norma
			--	FROM #t2 AS t
			--	WHERE fin_id = @fin_id1
			--	AND counter_id=@counter_id1
			--END
			--ELSE
			BEGIN
				IF @kol_people > 0
				BEGIN
					IF @debug = 1
						PRINT 'раскидываем по людям ' + STR(@kol_people)
					UPDATE t
					SET kol	  = kol * kol_people / @kol_people
					   ,value = value * kol_people / @kol_people
					FROM #t2 AS t
					WHERE 
						fin_id = @fin_id1
						AND counter_id = @counter_id1
				END;
				ELSE
				BEGIN
					IF @debug = 1
						PRINT 'делим на кол.лицевых ' + STR(@kol_occ)
					UPDATE t -- 
					SET kol	  = kol / @kol_occ
					   ,value = value / @kol_occ
					FROM #t2 AS t
					WHERE 
						fin_id = @fin_id1
						AND counter_id = @counter_id1
				END;
			END;

			-- проверяем остаток
			SELECT
				@ostatok = @sum_value - COALESCE(SUM(value), 0)
			FROM #t2
			WHERE fin_id = @fin_id1
				AND counter_id = @counter_id1;

			IF @ostatok <> 0
			BEGIN
				IF @debug = 1
					PRINT '@ostatok:' + STR(@ostatok, 9, 4);

				WITH cte AS (
					SELECT TOP (1) *
					FROM #t2 AS p
					WHERE 
						fin_id = @fin_id1
						AND counter_id = @counter_id1
						AND service_id = @service_id1
						AND p.value > ABS(@ostatok)
				)
				UPDATE cte
				SET [value] = [value] + @ostatok;

			END;

			-- читаем следующий фин. период
			FETCH NEXT FROM curs1 INTO @fin_id1, @counter_id1, @sum_value, @kol_occ;
		END;
		CLOSE curs1;
		DEALLOCATE curs1;

	END;

	--DELETE FROM @t2 WHERE occ=59422

	IF @debug = 1
		SELECT
			'#t2' AS tbl
		   ,*
		FROM #t2;
	IF @debug = 1
		SELECT
			'COUNTER_PAYM_OCC' AS tbl
		   ,*
		FROM dbo.COUNTER_PAYM_OCC 
		WHERE flat_id = @flat_id1
		AND service_id = @service_id1;

	--DELETE FROM dbo.COUNTER_PAYM_OCC WHERE flat_id=@flat_id1 AND service_id=@service_id1 AND tip_value=@tip_value1
	--INSERT INTO dbo.COUNTER_PAYM_OCC(flat_id, fin_id, occ, service_id, tip_value, kol, VALUE)        
	--SELECT @flat_id1, t2.fin_id, t2.occ, t2.service_id, t2.tip_value, t2.kol, t2.value FROM @t2 AS t2

	DELETE FROM #t2
	WHERE COALESCE(kol, 0) = 0
		AND COALESCE(value, 0) = 0;

	MERGE dbo.COUNTER_PAYM_OCC AS cpo USING (SELECT
			fin_id
		   ,occ
		   ,service_id
		   ,tip_value
		   ,SUM(kol) AS kol
		   ,SUM(value) AS value
		FROM #t2
		GROUP BY fin_id
				,occ
				,service_id
				,tip_value) AS t2
	ON cpo.flat_id = @flat_id1
		AND cpo.fin_id = t2.fin_id
		AND cpo.occ = t2.occ
		AND cpo.service_id = t2.service_id
		AND cpo.tip_value = t2.tip_value
	WHEN MATCHED
		AND cpo.kol <> t2.kol
		OR cpo.value <> t2.value
		THEN UPDATE
			SET cpo.kol	  = t2.kol
			   ,cpo.value = t2.value
	WHEN NOT MATCHED
		THEN INSERT
			(flat_id
			,fin_id
			,occ
			,service_id
			,tip_value
			,kol
			,value)
			VALUES (@flat_id1
				   ,t2.fin_id
				   ,t2.occ
				   ,t2.service_id
				   ,t2.tip_value
				   ,t2.kol
				   ,t2.value)

	--WHEN NOT MATCHED BY SOURCE AND cpo.flat_id=@flat_id1 AND cpo.service_id=@service_id1
	--	AND cpo.tip_value=@tip_value1
	--	THEN DELETE
	;

	DELETE cpo
		FROM dbo.COUNTER_PAYM_OCC AS cpo
	WHERE cpo.flat_id = @flat_id1
		AND cpo.service_id = @service_id1
		AND cpo.tip_value = @tip_value1
		AND NOT EXISTS (SELECT
				occ
			FROM #t2 AS t
			WHERE t.occ = cpo.occ);

	IF @debug = 1
		SELECT
			'COUNTER_PAYM_OCC' AS tbl
		   ,*
		FROM dbo.COUNTER_PAYM_OCC
		WHERE flat_id = @flat_id1
		AND service_id = @service_id1;

	DROP TABLE IF EXISTS #t1;
	DROP TABLE IF EXISTS #t2;
END;
go

