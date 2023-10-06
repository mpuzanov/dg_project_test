CREATE   PROCEDURE [dbo].[rep_dolg_2]
(
	@fin_id1	SMALLINT
	,@tip		SMALLINT	= NULL
)
AS
	/*
		Задолженность по периодам кол.месяцев
		Отчет: rep_dolg_2.fr3
		
		Сделал заново 25.09.09
		Пузанов
		
		в прошлой версии были ошибки 
		использовались суммы по услугам 
		и сальдо с минусом не бралось
		
	*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)
	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	DECLARE @dolg TABLE
		(
			occ			INT	PRIMARY KEY
			,sector_id	SMALLINT
			,div_id		SMALLINT
			,sumdolg	DECIMAL(15, 2)
			,kolmes		DECIMAL(15, 2)
		)

	-- Если задан текущий период
	IF @fin_id1 >= @fin_current
	BEGIN

		INSERT INTO @dolg
			SELECT
				o.occ
				,b.sector_id
				,b.div_id
				,(o.saldo - o.paymaccount) AS sumdolg
				,(o.saldo - o.paymaccount) / (o.value + 0.1) AS kolmes
			FROM dbo.VOCC AS o
			JOIN dbo.FLATS AS f
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS AS b
				ON f.bldn_id = b.id
			WHERE o.tip_id = COALESCE(@tip, o.tip_id)
			AND o.status_id <> 'закр'
			AND (o.saldo - o.paymaccount) > 0
			AND (CAST((o.saldo - o.paymaccount) / (o.value + 0.1) AS DECIMAL(15, 2)) > 0)

		SELECT
			s.id
			,s.Name
			,d.id AS 'div'
			,d.Name AS name2
			,COUNT(CASE
				WHEN dolg.kolmes > 0 AND dolg.kolmes < 1 THEN dolg.occ
			ELSE NULL
			END) AS ooc0
			,SUM(CASE
				WHEN dolg.kolmes > 0 AND dolg.kolmes < 1 THEN dolg.sumdolg
			ELSE 0
			END) AS sum0
			,COUNT(CASE
				WHEN dolg.kolmes >= 1 AND dolg.kolmes < 3 THEN dolg.occ
			ELSE NULL
			END) AS ooc1
			,SUM(CASE
				WHEN dolg.kolmes >= 1 AND dolg.kolmes < 3 THEN dolg.sumdolg
			ELSE 0
			END) AS sum1
			,COUNT(CASE
				WHEN dolg.kolmes >= 3 AND dolg.kolmes < 6 THEN dolg.occ
			ELSE NULL
			END) AS ooc2
			,SUM(CASE
				WHEN dolg.kolmes >= 3 AND dolg.kolmes < 6 THEN dolg.sumdolg
			ELSE 0
			END) AS sum2
			,COUNT(CASE
				WHEN dolg.kolmes >= 6 AND dolg.kolmes < 9 THEN dolg.occ
			ELSE NULL
			END) AS ooc3
			,SUM(CASE
				WHEN dolg.kolmes >= 6 AND dolg.kolmes < 9 THEN dolg.sumdolg
			ELSE 0
			END) AS sum3
			,COUNT(CASE
				WHEN dolg.kolmes >= 9 AND dolg.kolmes < 12 THEN dolg.occ
			ELSE NULL
			END) AS ooc4
			,SUM(CASE
				WHEN dolg.kolmes >= 9 AND dolg.kolmes < 12 THEN dolg.sumdolg
			ELSE 0
			END) AS sum4
			,COUNT(CASE
				WHEN dolg.kolmes >= 12 AND dolg.kolmes < 18 THEN dolg.occ
			ELSE NULL
			END) AS ooc5
			,SUM(CASE
				WHEN dolg.kolmes >= 12 AND dolg.kolmes < 18 THEN dolg.sumdolg
			ELSE 0
			END) AS sum5
			,COUNT(CASE
				WHEN dolg.kolmes >= 18 AND dolg.kolmes < 36 THEN dolg.occ
			ELSE NULL
			END) AS ooc6
			,SUM(CASE
				WHEN dolg.kolmes >= 18 AND dolg.kolmes < 36 THEN dolg.sumdolg
			ELSE 0
			END) AS sum6
			,COUNT(CASE
				WHEN dolg.kolmes >= 36 THEN dolg.occ
			ELSE NULL
			END) AS ooc7
			,SUM(CASE
				WHEN dolg.kolmes >= 36 THEN dolg.sumdolg
			ELSE 0
			END) AS sum7
			,COUNT(dolg.occ) AS occITOG
			,SUM(dolg.sumdolg) AS sumITOG
		FROM @dolg AS dolg
		JOIN dbo.SECTOR AS s
			ON dolg.sector_id = s.id
		JOIN dbo.DIVISIONS AS d
			ON dolg.div_id = d.id
		GROUP BY	s.id
					,s.Name
					,d.id
					,d.Name
		ORDER BY d.id DESC, s.id

	END

	IF @fin_id1 < @fin_current
	BEGIN

		INSERT INTO @dolg
			SELECT
				o.occ
				,b.sector_id
				,b.div_id
				,(o.saldo - o.paymaccount) AS sumdolg
				,(o.saldo - o.paymaccount) / (o.value + 0.1) AS kolmes
			FROM dbo.VOCC_HISTORY AS o
			JOIN dbo.FLATS AS f
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS_HISTORY AS b
				ON f.bldn_id = b.bldn_id AND o.fin_id = b.fin_id
			WHERE o.fin_id = @fin_id1
			AND o.tip_id = COALESCE(@tip, o.tip_id)
			AND o.status_id <> 'закр'
			AND (o.saldo - o.paymaccount) > 0
			AND (CAST((o.saldo - o.paymaccount) / (o.value + 0.1) AS DECIMAL(15, 2)) > 0)

		SELECT
			s.id
			,s.Name
			,d.id AS 'div'
			,d.Name AS name2
			,COUNT(CASE
				WHEN dolg.kolmes > 0 AND dolg.kolmes < 1 THEN dolg.occ
			ELSE NULL
			END) AS ooc0
			,SUM(CASE
				WHEN dolg.kolmes > 0 AND dolg.kolmes < 1 THEN dolg.sumdolg
			ELSE 0
			END) AS sum0
			,COUNT(CASE
				WHEN dolg.kolmes >= 1 AND dolg.kolmes < 3 THEN dolg.occ
			ELSE NULL
			END) AS ooc1
			,SUM(CASE
				WHEN dolg.kolmes >= 1 AND dolg.kolmes < 3 THEN dolg.sumdolg
			ELSE 0
			END) AS sum1
			,COUNT(CASE
				WHEN dolg.kolmes >= 3 AND dolg.kolmes < 6 THEN dolg.occ
			ELSE NULL
			END) AS ooc2
			,SUM(CASE
				WHEN dolg.kolmes >= 3 AND dolg.kolmes < 6 THEN dolg.sumdolg
			ELSE 0
			END) AS sum2
			,COUNT(CASE
				WHEN dolg.kolmes >= 6 AND dolg.kolmes < 9 THEN dolg.occ
			ELSE NULL
			END) AS ooc3
			,SUM(CASE
				WHEN dolg.kolmes >= 6 AND dolg.kolmes < 9 THEN dolg.sumdolg
			ELSE 0
			END) AS sum3
			,COUNT(CASE
				WHEN dolg.kolmes >= 9 AND dolg.kolmes < 12 THEN dolg.occ
			ELSE NULL
			END) AS ooc4
			,SUM(CASE
				WHEN dolg.kolmes >= 9 AND dolg.kolmes < 12 THEN dolg.sumdolg
			ELSE 0
			END) AS sum4
			,COUNT(CASE
				WHEN dolg.kolmes >= 12 AND dolg.kolmes < 18 THEN dolg.occ
			ELSE NULL
			END) AS ooc5
			,SUM(CASE
				WHEN dolg.kolmes >= 12 AND dolg.kolmes < 18 THEN dolg.sumdolg
			ELSE 0
			END) AS sum5
			,COUNT(CASE
				WHEN dolg.kolmes >= 18 AND dolg.kolmes < 36 THEN dolg.occ
			ELSE NULL
			END) AS ooc6
			,SUM(CASE
				WHEN dolg.kolmes >= 18 AND dolg.kolmes < 36 THEN dolg.sumdolg
			ELSE 0
			END) AS sum6
			,COUNT(CASE
				WHEN dolg.kolmes >= 36 THEN dolg.occ
			ELSE NULL
			END) AS ooc7
			,SUM(CASE
				WHEN dolg.kolmes >= 36 THEN dolg.sumdolg
			ELSE 0
			END) AS sum7
			,COUNT(dolg.occ) AS occITOG
			,SUM(dolg.sumdolg) AS sumITOG
		FROM @dolg AS dolg
		JOIN dbo.SECTOR AS s
			ON dolg.sector_id = s.id
		JOIN dbo.DIVISIONS AS d
			ON dolg.div_id = d.id
		GROUP BY	s.id
					,s.Name
					,d.id
					,d.Name
		ORDER BY d.id DESC, s.id

	--select * from @dolg where kolmes=0
	--select kolmes, COUNT(*) from @dolg group by kolmes

	END
go

