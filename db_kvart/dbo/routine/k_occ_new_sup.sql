CREATE   PROCEDURE [dbo].[k_occ_new_sup]
(
	  @dog_int INT
	, @occ_sup_new INT = 0 OUTPUT
	, @rang_max INT = 0 OUTPUT
	, @debug BIT = 0
)
AS
	/*
	Процедура возвращает значение ключа в таблице OCC_SUPPLIERS
	
	DECLARE	@return_value int,
			@occ_sup_new int,
			@rang_max int
	
	EXEC	@return_value = [dbo].k_occ_new_sup
			@dog_int = 156,
			@occ_sup_new = @occ_sup_new OUTPUT,
			@rang_max = @rang_max OUTPUT
	
	SELECT	@occ_sup_new as N'@occ_sup_new',
			@rang_max as N'@rang_max'
	
	SELECT 'Return Value' = @return_value
	
	*/
	SET NOCOUNT ON

	DECLARE @occ_min INT
		  , @occ_max INT
		  , @rang_max_db INT = 100000


	IF @dog_int IS NOT NULL
		SELECT @occ_min = first_occ
			 , @occ_max = last_occ
		FROM dbo.Dog_sup
		WHERE id = @dog_int
	ELSE
		RETURN

	IF (COALESCE(@occ_min, 0) = 0)
		OR (COALESCE(@occ_max, 0) = 0)
	BEGIN
		SELECT @occ_min = 1
			 , @occ_max = 999999999
			 , @rang_max_db = 100000

		-- вычисляем @occ_min
		-- находим максимальные единый лицевой и лицевой поставщика по договору
		DECLARE @occ_min_tmp INT
		SELECT @occ_min_tmp = CASE
                                  WHEN MAX(o.Occ) > MAX(os.occ_sup) THEN MAX(o.Occ)
                                  ELSE MAX(os.occ_sup)
            END
		FROM dbo.Dog_build db
			JOIN Flats f ON f.bldn_id = db.build_id
			JOIN Occupations o ON o.flat_id = f.id
			LEFT JOIN Occ_Suppliers AS os ON os.Occ = o.Occ
				AND os.fin_id = o.fin_id
		WHERE db.dog_int = @dog_int

		IF (@occ_min_tmp > @occ_min)
			SET @occ_min = @occ_min_tmp

		IF (@occ_min > 1)
			AND (@occ_max - @occ_min > @rang_max_db)
			SET @occ_max = @occ_min + @rang_max_db
	END

	DROP TABLE IF EXISTS #tally;

	SELECT @rang_max = @occ_max - @occ_min

	IF @rang_max > @rang_max_db
		SELECT @rang_max = @rang_max_db

	IF @debug=1 PRINT 'rang_max:' + STR(@rang_max) + ', occ_min:' + STR(@occ_min) + ', occ_max:' + STR(@occ_max)

	SELECT occ_new = @occ_min
	INTO #tally
	UNION ALL
	SELECT TOP (@rang_max) occ_new = ROW_NUMBER() OVER (ORDER BY t.n) + @occ_min
	FROM dbo.Fun_GetNums(@occ_min, @occ_max) AS t
	WHERE NOT EXISTS (
			SELECT *
			FROM dbo.Occupations AS o 
			WHERE t.n = o.Occ
		)
		AND NOT EXISTS (
			SELECT *
			FROM dbo.Occ_Suppliers AS o 
			WHERE t.n = o.occ_sup
		)

	--SELECT TOP (@rang_max)
	--	occ_new = ROW_NUMBER() OVER (ORDER BY sc1.id) + @occ_min
	--FROM	sys.syscolumns AS sc1
	--		,sys.syscolumns AS sc2
	--OPTION (MAXDOP 1);

	--SELECT * FROM #tally AS t

	--UPDATE t
	--SET occ_new = (t.N + @occ_min)
	--FROM #tally AS t

	--SELECT * FROM #tally AS t

	DELETE t
	FROM dbo.#tally AS t
		JOIN dbo.Dog_sup AS DS ON t.occ_new BETWEEN DS.first_occ AND DS.last_occ
	WHERE DS.id <> @dog_int
		OR occ_new = 0

	SELECT TOP (1) @occ_sup_new = t.occ_new
	FROM #tally AS t
	ORDER BY occ_new
	--SELECT *
	--FROM #tally AS t

	SELECT @rang_max = COUNT(t.occ_new)
	FROM #tally AS t

	-- проверяем нет ли такого лицевого в цессии
	IF EXISTS (
			SELECT 1
			FROM dbo.Cessia AS C
			WHERE occ_sup = @occ_sup_new
		)
		SELECT @occ_sup_new = NULL

	SET @occ_sup_new =COALESCE(@occ_sup_new, 0)
go

