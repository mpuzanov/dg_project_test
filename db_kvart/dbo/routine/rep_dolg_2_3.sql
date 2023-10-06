CREATE   PROCEDURE [dbo].[rep_dolg_2_3]
(
	@fin_id1	SMALLINT
	,@tip		SMALLINT	= NULL
	,@sup_id		INT			= NULL
)
AS
	/*
	
	exec rep_dolg_2_3 182,28,323
	exec rep_dolg_2_3 182,28,347
	
		Задолженность по периодам кол.месяцев
		Отчет: rep_dolg_2.fr3
	
	*/
	SET NOCOUNT ON


	DECLARE	@fin_current	SMALLINT
			,@fin_pred		SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	SET @fin_pred = @fin_id1 - 1

	DECLARE @dolg TABLE
		(
			occ			INT	PRIMARY KEY
			,sector_id	SMALLINT
			,div_id		SMALLINT
			,sumdolg	DECIMAL(15, 2)
			,kolmes		DECIMAL(5, 1)
		)

	IF @sup_id=0
	INSERT INTO @dolg
		SELECT
			o.occ
			,b.sector_id
			,b.div_id
			,(o.saldo - o.paymaccount) AS sumdolg
			,i.KolMesDolg AS kolmes
		FROM dbo.View_OCC_ALL AS o
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id AND o.fin_id = b.fin_id
		JOIN dbo.INTPRINT AS i 
			ON o.occ = i.occ AND o.fin_id = i.fin_id
		WHERE o.fin_id = @fin_id1
		AND o.tip_id = COALESCE(@tip, o.tip_id)
		AND o.status_id <> 'закр'
		AND (o.saldo - o.paymaccount) > 0
		AND i.KolMesDolg >= 0
	--and i.fin_id=@fin_pred

IF @sup_id IS NULL
	INSERT INTO @dolg
		SELECT
			o.occ
			,b.sector_id
			,b.div_id
			,(o.SaldoAll - o.Paymaccount_ServAll) AS sumdolg
			,i.KolMesDolgAll AS kolmes
		FROM dbo.View_OCC_ALL AS o
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id AND o.fin_id = b.fin_id
		JOIN dbo.INTPRINT AS i 
			ON o.occ = i.occ AND o.fin_id = i.fin_id
		WHERE o.fin_id = @fin_id1
		AND o.tip_id = COALESCE(@tip, o.tip_id)
		AND o.status_id <> 'закр'
		AND (o.SaldoAll - o.Paymaccount_ServAll) > 0


	IF @sup_id > 0
		INSERT
		INTO @dolg
				SELECT
					o.occ
					,b.sector_id
					,b.div_id
					,(o.SaldoAll - o.Paymaccount_ServAll) AS sumdolg
					,i.KolMesDolg AS kolmes
				FROM dbo.View_occ_all AS o
				JOIN dbo.View_build_all AS b ON 
					o.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.Occ_Suppliers AS i ON 
					o.occ = i.occ
					AND o.fin_id = i.fin_id
				WHERE 
					o.fin_id = @fin_id1
					AND (o.tip_id = @tip OR @tip IS NULL)
					AND i.sup_id = @sup_id
					AND o.status_id <> 'закр'
					AND (i.saldo - (i.paymaccount-i.paymaccount_peny) ) > 0
					AND i.KolMesDolg >= 0



	SELECT
		d.Name AS name2
		,s.Name
		,COUNT(CASE
			WHEN dolg.sumdolg >= 0 AND dolg.sumdolg < 5000 THEN dolg.occ ELSE NULL
		END) AS ooc5
		,SUM(CASE
			WHEN dolg.sumdolg >= 0 AND dolg.sumdolg < 5000 THEN dolg.sumdolg ELSE 0
		END) AS sum5
		,COUNT(CASE
			WHEN dolg.sumdolg >= 5000 AND dolg.sumdolg < 10000 THEN dolg.occ ELSE NULL
		END) AS ooc10
		,SUM(CASE
			WHEN dolg.sumdolg >= 5000 AND dolg.sumdolg < 10000 THEN dolg.sumdolg ELSE 0
		END) AS sum10
		,COUNT(CASE
			WHEN dolg.sumdolg >= 10000 AND dolg.sumdolg < 20000 THEN dolg.occ ELSE NULL
		END) AS ooc20
		,SUM(CASE
			WHEN dolg.sumdolg >= 10000 AND dolg.sumdolg < 20000 THEN dolg.sumdolg ELSE 0
		END) AS sum20
		,COUNT(CASE
			WHEN dolg.sumdolg >= 20000 AND dolg.sumdolg < 30000 THEN dolg.occ ELSE NULL
		END) AS ooc30
		,SUM(CASE
			WHEN dolg.sumdolg >= 20000 AND dolg.sumdolg < 30000 THEN dolg.sumdolg ELSE 0
		END) AS sum30
		,COUNT(CASE
			WHEN dolg.sumdolg >= 30000 AND dolg.sumdolg < 40000 THEN dolg.occ ELSE NULL
		END) AS ooc40
		,SUM(CASE
			WHEN dolg.sumdolg >= 30000 AND dolg.sumdolg < 40000 THEN dolg.sumdolg ELSE 0
		END) AS sum40
		,COUNT(CASE
			WHEN dolg.sumdolg >= 40000 AND dolg.sumdolg < 50000 THEN dolg.occ ELSE NULL
		END) AS ooc50
		,SUM(CASE
			WHEN dolg.sumdolg >= 40000 AND dolg.sumdolg < 50000 THEN dolg.sumdolg ELSE 0
		END) AS sum50
		,COUNT(CASE
			WHEN dolg.sumdolg >= 50000 THEN dolg.occ ELSE NULL
		END) AS ooc60
		,SUM(CASE
			WHEN dolg.sumdolg >= 50000 THEN dolg.sumdolg ELSE 0
		END) AS sum60
		,COUNT(dolg.occ) AS occITOG
		,SUM(dolg.sumdolg) AS sumITOG
	FROM @dolg AS dolg
	JOIN dbo.SECTOR AS s
		ON dolg.sector_id = s.id
	JOIN dbo.DIVISIONS AS d
		ON dolg.div_id = d.id
	GROUP BY	d.Name
				,s.Name
	ORDER BY d.Name, s.Name

--select * from @dolg where kolmes=0
--select kolmes, COUNT(*) from @dolg group by kolmes
go

