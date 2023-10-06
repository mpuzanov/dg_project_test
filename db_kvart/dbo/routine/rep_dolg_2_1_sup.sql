CREATE   PROCEDURE [dbo].[rep_dolg_2_1_sup]
(
	@fin_id1 SMALLINT
   ,@tip	 SMALLINT = NULL
   ,@sup_id	 INT	  = NULL
)
AS
	/*
		Задолженность по периодам кол.месяцев по поставщику
		Отчет: 
		
		Пузанов	
	*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
		   ,@fin_pred	 SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	SET @fin_pred = @fin_id1 - 1

	DECLARE @dolg TABLE
		(
			occ		  INT PRIMARY KEY
		   ,sector_id SMALLINT
		   ,div_id	  SMALLINT
		   ,sumdolg	  DECIMAL(15, 2)
		   ,kolmes	  DECIMAL(5, 1)
		)

	INSERT INTO @dolg
		SELECT
			os.occ
		   ,b.sector_id
		   ,b.div_id
		   ,(os.saldo - os.paymaccount) AS sumdolg
		   ,os.KolMesDolg AS kolmes
		FROM dbo.OCC_SUPPLIERS AS os
		JOIN dbo.View_OCC_ALL AS o
			ON os.fin_id = o.fin_id
			AND os.occ = o.occ
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id
			AND o.fin_id = b.fin_id
		WHERE os.fin_id = @fin_id1
		AND (o.tip_id = @tip OR @tip IS NULL)
		AND o.status_id <> 'закр'
		AND (os.saldo - os.paymaccount) > 0
		AND os.KolMesDolg >= 0
		AND (os.sup_id = @sup_id OR @sup_id IS NULL)

	SELECT
		d.name AS name2
	   ,s.name
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 0 AND
			dolg.kolmes < 1 THEN dolg.occ
			ELSE NULL
		END) AS ooc0
	   ,SUM(CASE
			WHEN dolg.kolmes >= 0 AND
			dolg.kolmes < 1 THEN dolg.sumdolg
			ELSE 0
		END) AS sum0
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 1 AND
			dolg.kolmes < 3 THEN dolg.occ
			ELSE NULL
		END) AS ooc1
	   ,SUM(CASE
			WHEN dolg.kolmes >= 1 AND
			dolg.kolmes < 3 THEN dolg.sumdolg
			ELSE 0
		END) AS sum1
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 3 AND
			dolg.kolmes < 6 THEN dolg.occ
			ELSE NULL
		END) AS ooc2
	   ,SUM(CASE
			WHEN dolg.kolmes >= 3 AND
			dolg.kolmes < 6 THEN dolg.sumdolg
			ELSE 0
		END) AS sum2
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 6 AND
			dolg.kolmes < 9 THEN dolg.occ
			ELSE NULL
		END) AS ooc3
	   ,SUM(CASE
			WHEN dolg.kolmes >= 6 AND
			dolg.kolmes < 9 THEN dolg.sumdolg
			ELSE 0
		END) AS sum3
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 9 AND
			dolg.kolmes < 12 THEN dolg.occ
			ELSE NULL
		END) AS ooc4
	   ,SUM(CASE
			WHEN dolg.kolmes >= 9 AND
			dolg.kolmes < 12 THEN dolg.sumdolg
			ELSE 0
		END) AS sum4
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 12 AND
			dolg.kolmes < 18 THEN dolg.occ
			ELSE NULL
		END) AS ooc5
	   ,SUM(CASE
			WHEN dolg.kolmes >= 12 AND
			dolg.kolmes < 18 THEN dolg.sumdolg
			ELSE 0
		END) AS sum5
	   ,COUNT(CASE
			WHEN dolg.kolmes >= 18 AND
			dolg.kolmes < 36 THEN dolg.occ
			ELSE NULL
		END) AS ooc6
	   ,SUM(CASE
			WHEN dolg.kolmes >= 18 AND
			dolg.kolmes < 36 THEN dolg.sumdolg
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
	GROUP BY d.name
			,s.name
	ORDER BY d.name, s.name

--select * from @dolg where kolmes=0
--select kolmes, COUNT(*) from @dolg group by kolmes
go

