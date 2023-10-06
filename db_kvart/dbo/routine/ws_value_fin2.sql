-- =============================================
-- Author:		Пузанов
-- Create date: 20.10.2008
-- Description:	
-- =============================================
CREATE       PROCEDURE [dbo].[ws_value_fin2]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@max_rows	INT				= 1000
	,@xml1		VARCHAR(MAX)	= '' OUTPUT
	,@sup_id	INT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	IF @max_rows IS NULL
		SET @max_rows = 99999999

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	DECLARE @tip_table TABLE
		(
			tip_id SMALLINT DEFAULT NULL
		)

	INSERT
	INTO @tip_table
			SELECT CASE
                       WHEN value = 'Null' THEN NULL
                       ELSE value
                       END
			FROM STRING_SPLIT(@tip_str1, ',') WHERE RTRIM(value) <> ''

	IF EXISTS (SELECT
				1
			FROM @tip_table
			WHERE tip_id IS NULL)
	BEGIN  -- Заносим все типы жилого фонда
		DELETE FROM @tip_table
		INSERT
		INTO @tip_table
				SELECT
					id
				FROM dbo.VOCC_TYPES
	END
	--select * from @tip_table
	--************************************************************************************

	-- выбираем дома по типам фонда
	DECLARE @table_bldn TABLE
		(
			bldn_id INT PRIMARY KEY
		)
	INSERT
	INTO @table_bldn
			SELECT DISTINCT
				bldn_id
			FROM dbo.BUILDINGS_HISTORY BH
			WHERE EXISTS (SELECT
					*
				FROM @tip_table AS t
				WHERE t.tip_id = BH.tip_id)

	-- Выбираем разовые: корректировка оплаты
	DECLARE @add_paym_table TABLE
		(
			occ					INT
			,service_id			VARCHAR(10)
			,sup_id				INT
			,add_paymaccount	DECIMAL(9, 2)
		)

	INSERT
	INTO @add_paym_table
	(	occ
		,service_id
		,sup_id
		,add_paymaccount)
			SELECT
				ap.occ
				,service_id
				,sup_id
				,SUM(ap.value)
			FROM dbo.View_ADDED AS ap 
			JOIN dbo.OCCUPATIONS AS o
				ON ap.occ = o.occ
			JOIN dbo.FLATS AS f
				ON o.flat_id = f.id
			WHERE ap.fin_id = @fin_id1
			AND add_type = 13 -- корректировка оплаты
			AND EXISTS (SELECT
					1
				FROM @table_bldn t
				WHERE t.bldn_id = f.bldn_id)
			GROUP BY	ap.occ
						,service_id
						,ap.sup_id

	--DECLARE @xml1 XML

	SELECT TOP (@max_rows)
		o.bldn_id -- код дома
		,0 AS occ -- лицевой счет
		,pl.service_id -- код услуги
		,pl.mode_id -- код режима потребления 
		,pl.tarif -- тариф
		,SUM(pl.saldo) AS saldo -- нач.сальдо
		,SUM(pl.VALUE) AS VALUE -- начислено
		,SUM(pl.discount) AS discount -- льгота
		,SUM(pl.added - COALESCE(AT.add_paymaccount, 0)) AS added -- перерасчеты
		,SUM(pl.paid - COALESCE(AT.add_paymaccount, 0)) AS paid -- пост.начисления (value-discount+added)
		,SUM(pl.debt) AS debt      -- конечное сальдо
	INTO #t
	FROM dbo.View_PAYM AS pl 
	JOIN dbo.View_OCC_ALL AS o 
		ON pl.occ = o.occ
		AND pl.fin_id = o.fin_id
	LEFT JOIN @add_paym_table AS AT
		ON pl.occ = AT.occ
		AND pl.service_id = AT.service_id
		AND pl.sup_id = AT.sup_id
	WHERE o.fin_id = @fin_id1
	AND EXISTS (SELECT
			1
		FROM @tip_table
		WHERE tip_id = o.tip_id)
	AND EXISTS (SELECT
			1
		FROM @table_bldn
		WHERE bldn_id = o.bldn_id)
	--AND pl.account_one=0
	AND (pl.sup_id = @sup_id
	OR (pl.sup_id = 0
	AND @sup_id IS NULL))
	GROUP BY	o.bldn_id
				,pl.service_id
				,pl.mode_id
				,pl.tarif
	HAVING SUM(pl.VALUE) <> 0
	OR SUM(pl.added - COALESCE(AT.add_paymaccount, 0)) <> 0
	OR SUM(pl.paid - COALESCE(AT.add_paymaccount, 0)) <> 0
	OR SUM(pl.saldo) <> 0
	OR SUM(pl.debt) <> 0

	SET @xml1 = (SELECT
			*
		FROM #t
		FOR XML RAW ('VALUE'), ROOT ('root'))

	SELECT
		*
	FROM #t

--SELECT @xml1 AS xml1

END
go

