CREATE   PROCEDURE [dbo].[k_occ_new]
(
	@tip_id		SMALLINT	= NULL
	,@occ_new	INT			= 0 OUTPUT
	,@rang_max	INT			= 0 OUTPUT
	,@debug		BIT			= 0
)
AS
	/*
--
--  Процедура возвращает значение ключа в таблице OCCUPATIONS
--

DECLARE	@return_value int,
		@occ_new int,
		@rang_max int

EXEC	@return_value = [dbo].[k_occ_new]
		@tip_id = 188,
		@occ_new = @occ_new OUTPUT,
		@rang_max = @rang_max OUTPUT

SELECT	@occ_new as N'@occ_new',
		@rang_max as N'@rang_max'

SELECT	'Return Value' = @return_value

*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE	@db_name		NVARCHAR(128) = DB_NAME()
			,@occ_min		INT
			,@occ_max		INT
			,@rang_max_db	INT	= 100000


	IF @tip_id IS NOT NULL
		SELECT
			@occ_min = occ_min
			,@occ_max = occ_max
		FROM dbo.VOCC_TYPES
		WHERE id = @tip_id

	IF (COALESCE(@occ_min, 0) = 0)
		OR (COALESCE(@occ_max, 0) = 0)
	BEGIN

		IF @db_name = 'komp'
			SELECT
				@occ_min = 40000
				,@occ_max = 500000
				,@rang_max_db = 500000

		IF @db_name = 'naim'
			SELECT
				@occ_min = 6040000
				,@occ_max = 7000000
				,@rang_max_db = 100000

		IF @db_name = 'kvart'
			SELECT
				@occ_min = 100000000
				,@occ_max = 200000000
				,@rang_max_db = 300000

		IF @db_name = 'kr1'
			SELECT
				@occ_min = 100000
				,@occ_max = 999999999
				,@rang_max_db = 100000

	END

	DROP TABLE IF EXISTS #tally
	CREATE TABLE #tally
	(
		occ_new BIGINT PRIMARY KEY
	)


	SELECT
		@rang_max = @occ_max - @occ_min

    IF @rang_max = 0
    BEGIN
		RAISERROR ('Закончился диапазон чисел для организации', 16, 1)
		RETURN
	END 
    
	IF @rang_max > @rang_max_db
		SELECT
			@rang_max = @rang_max_db

	--SELECT @occ_min, @occ_max, @rang_max

	--SELECT TOP (@rang_max) identity(INT, 1, 1) AS N
	--					 , occ_new = row_number() OVER (ORDER BY sc1.id)+@occ_min
	--INTO #tally
	--FROM sys.syscolumns AS sc1, sys.syscolumns AS sc2, sys.syscolumns AS sc3

	--SELECT
	--	occ_new = @occ_min
	--INTO #tally
	--UNION ALL
	--SELECT TOP (@rang_max)
	--	occ_new = ROW_NUMBER() OVER (ORDER BY sc1.id) + @occ_min
	--FROM	sys.syscolumns AS sc1
	--		,sys.syscolumns AS sc2
	--OPTION (MAXDOP 1);
	IF @db_name = 'komp'
		INSERT
		INTO #tally
			SELECT TOP (@rang_max)
				occ_new = n
			FROM dbo.Fun_GetNums(@occ_min, @occ_max) AS t
			WHERE NOT EXISTS(SELECT * FROM dbo.OCCUPATIONS AS o WHERE t.n = o.Occ)
			AND NOT EXISTS(SELECT * FROM dbo.OCC_SUPPLIERS AS o WHERE t.n = o.occ_sup)
	ELSE
	INSERT
	INTO #tally
		SELECT TOP (@rang_max)
			occ_new = n
		FROM dbo.Fun_GetNums(@occ_min, @occ_max) AS t
		WHERE NOT EXISTS(SELECT * FROM dbo.OCCUPATIONS AS o WHERE t.n = o.Occ)
		AND NOT EXISTS(SELECT * FROM dbo.OCC_SUPPLIERS AS o WHERE t.n = o.occ_sup)

	--SELECT * FROM #tally AS t

	---- убраем используемые диапазоны
	--DELETE t
	--	FROM dbo.#tally AS t
	--	JOIN dbo.OCCUPATIONS AS o
	--		ON t.occ_new = o.occ

	-- --убраем если есть в поставщиках
	--DELETE t
	--	FROM dbo.#tally AS t
	--	JOIN dbo.OCC_SUPPLIERS AS o
	--		ON t.occ_new = o.occ_sup

	---- проверяем с другой базой где так же не должно быть
	--IF @db_name = 'komp'
	--	DELETE t
	--		FROM dbo.#tally AS t
	--		JOIN kvart.dbo.OCCUPATIONS AS o 
	--			ON t.occ_new = o.occ

	--SELECT TOP 100 * FROM #tally AS t
	--RETURN
	
	--DELETE t
	--	FROM #tally AS t
	--	JOIN dbo.OCCUPATION_TYPES AS OT 
	--		ON t.occ_new BETWEEN OT.occ_min AND OT.occ_max
	--WHERE OT.id <> @tip_id
	--	AND @tip_id IS NOT NULL

	--if 1=0	
	--SELECT t.*, OT.id, OT.occ_min, OT.occ_max
	--FROM dbo.#tally AS t
	--	JOIN dbo.OCCUPATION_TYPES AS OT
	--		ON t.occ_new BETWEEN OT.occ_min AND OT.occ_max
	--WHERE OT.id <> @tip_id OR
	--	occ_new = 0

	--SELECT * FROM #tally AS t

	SELECT TOP (1)
		@occ_new = t.occ_new
	FROM #tally AS t
	WHERE NOT EXISTS (SELECT
			1
		FROM dbo.OCCUPATION_TYPES AS OT 
		WHERE t.occ_new BETWEEN OT.occ_min AND OT.occ_max
		AND OT.id <> @tip_id
		AND @tip_id IS NOT NULL)
	ORDER BY occ_new

	SELECT
		@rang_max = COUNT(t.occ_new)
	FROM #tally AS t
	
	--IF @rang_max = 0
	--BEGIN
	--	RAISERROR ('Закончился диапазон чисел для организации', 16, 1)
	--	RETURN
	--END 
	---- проверяем нет ли такого лицевого в поставщиках
	--IF EXISTS (SELECT
	--			1
	--		FROM dbo.OCC_SUPPLIERS AS OS
	--		WHERE occ_sup = @occ_new)
	--BEGIN
	--	PRINT 'лицевой ' + STR(@occ_new) + ' есть в поставщиках'
	--	SELECT
	--		@occ_new = NULL
	--END

	-- проверяем нет ли такого лицевого в цессии
	IF EXISTS (SELECT
				1
			FROM dbo.CESSIA AS C 
			WHERE occ_sup = @occ_new)
	BEGIN
		PRINT N'лицевой ' + STR(@occ_new) + N' есть в цессии'
		SELECT
			@occ_new = NULL
	END

	SET @occ_new=COALESCE(@occ_new, 0)

	IF @debug = 1
	BEGIN
		PRINT CONCAT('@occ_new=',@occ_new,', @occ_min=',@occ_min,', @occ_max=',@occ_max,', @rang_max=', @rang_max)
	END
go

