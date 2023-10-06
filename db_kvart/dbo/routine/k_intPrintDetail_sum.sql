CREATE   PROCEDURE [dbo].[k_intPrintDetail_sum]
(
	@fin_id1	SMALLINT
	,@occ1		INT				= 0
	,@build		INT				= 0
	,@jeu		SMALLINT		= 0
	,@tip_id		SMALLINT		= NULL
	,@ops		INT				= 0
	,@notocc		SMALLINT		= 0
	,@sum_dolg	DECIMAL(9, 2)	= 0 -- если не равно 0 вывод только с долгом более этой суммы
	,@group_id	INT				= 0
)
AS
	/*

Выдаем итоговые значения сумм по услугам для 
Единой квитанции

*/

	SET NOCOUNT ON

	DECLARE	@fin_current1	SMALLINT
			,@DB_NAME		VARCHAR(20)	= UPPER(DB_NAME())

	SELECT
		@fin_current1 = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, @occ1)

	DECLARE @t_occ TABLE
		(
			occ		INT
			,tip_id	SMALLINT
		)

	IF @build > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT
					occ
					,o.tip_id
				FROM dbo.OCCUPATIONS AS o 
				JOIN FLATS AS f 
					ON o.flat_id = f.id
				WHERE f.bldn_id = @build
				AND o.status_id <> 'закр'
				AND NOT EXISTS (SELECT
						1
					FROM dbo.OCC_NOT_print AS onp
					WHERE onp.flag = 1
					AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @jeu > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT
					occ
					,o.tip_id
				FROM dbo.OCCUPATIONS AS o 
				JOIN dbo.FLATS AS f 
					ON o.flat_id = f.id
				JOIN dbo.BUILDINGS AS b 
					ON f.bldn_id = b.id
				WHERE b.sector_id = @jeu
				AND (o.status_id <> 'закр'
				OR o.proptype_id = 'арен')
				AND NOT EXISTS (SELECT
						1
					FROM dbo.OCC_NOT_print AS onp
					WHERE onp.flag = 1
					AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @ops > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT
					occ
					,o.tip_id
				FROM dbo.OCCUPATIONS AS o 
				JOIN dbo.FLATS AS f
					ON o.flat_id = f.id
				JOIN dbo.BUILDINGS AS b
					ON f.bldn_id = b.id
				WHERE b.index_id = @ops
				AND (o.status_id <> 'закр'
				OR o.proptype_id = 'арен')
				AND NOT EXISTS (SELECT
						1
					FROM dbo.OCC_NOT_print AS onp
					WHERE onp.flag = 1
					AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @notocc > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT
					onp.occ
					,o.tip_id
				FROM dbo.OCC_NOT_print AS onp 
				JOIN dbo.OCCUPATIONS AS o 
					ON onp.occ = o.occ
				WHERE onp.flag = 0
		GOTO LABEL1
	END

	IF @group_id > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT DISTINCT
					po.occ
					,o.tip_id
				FROM dbo.PRINT_OCC AS po
				JOIN dbo.OCCUPATIONS AS o 
					ON po.occ = o.occ
				WHERE po.group_id = @group_id
		GOTO LABEL1
	END

	IF @occ1 > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
				SELECT
					occ
					,o.tip_id
				FROM dbo.OCCUPATIONS AS o
				WHERE occ = @occ1
				AND o.status_id <> 'закр'
	END

LABEL1:

	IF @fin_id1 >= @fin_current1
	BEGIN
		SELECT
			t.occ
			,SUM(p.value) AS 'value'
			,SUM(p.added) AS 'added'
			,SUM(p.paid) AS 'paid'
		FROM @t_occ AS t
		JOIN dbo.PAYM_LIST AS p 
			ON t.occ = p.occ
		WHERE (p.subsid_only = 0)
		AND (p.account_one = 0
		OR p.account_one IS NULL)
		GROUP BY t.occ
	END
	ELSE
	BEGIN
		SELECT
			t.occ
			,SUM(p.value) AS 'value'
			,SUM(p.added) AS 'added'
			,SUM(p.paid) AS 'paid'
		FROM @t_occ AS t
		JOIN dbo.PAYM_HISTORY AS p 
			ON t.occ = p.occ
		WHERE p.fin_id = @fin_id1
		AND (p.subsid_only = 0)
		AND (p.account_one = 0
		OR p.account_one IS NULL)
		GROUP BY t.occ
	END
go

