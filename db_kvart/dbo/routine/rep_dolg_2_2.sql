CREATE   PROCEDURE [dbo].[rep_dolg_2_2]
(
	@fin_id1		SMALLINT
	,@tip			SMALLINT	= NULL
	,@sup_id		INT			= NULL
	,@only_itogi	BIT			= 0
)
AS
	/*
	
	exec rep_dolg_2_2 @fin_id1=186,@tip=28,@all_serv=1,@sup_id=323,@only_itogi = 0
	exec rep_dolg_2_2 @fin_id1=186,@tip=28,@all_serv=1,@sup_id=323,@only_itogi = 1

	Задолженность по периодам кол.месяцев
	Отчет: rep_dolg_2.fr3
	
	Пузанов
	
	*/
	SET NOCOUNT ON


	DECLARE	@fin_current	SMALLINT
			,@fin_pred		SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	IF @only_itogi IS NULL
		SET @only_itogi = 0

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	SET @fin_pred = @fin_id1 - 1

	DECLARE @dolg TABLE
		(
			occ				INT
			,sup_id			INT			DEFAULT NULL
			,sector_id		SMALLINT
			,div_id			SMALLINT
			,sumdolg		DECIMAL(15, 2)
			,kolmes			DECIMAL(5, 1)
			,group_kolmes	VARCHAR(20)	DEFAULT ''
			,sort_no		TINYINT		DEFAULT 100
		)

	IF @sup_id = 0
		INSERT
		INTO @dolg
		(	occ
			,sup_id
			,sector_id
			,div_id
			,sumdolg
			,kolmes)
				SELECT
					o.occ
					,0 AS sup_id
					,b.sector_id
					,b.div_id
					,(o.saldo - o.PaymAccount) AS sumdolg
					,i.KolMesDolg AS kolmes
				FROM dbo.View_OCC_ALL AS o
				JOIN dbo.View_BUILD_ALL AS b 
					ON o.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.INTPRINT AS i 
					ON o.occ = i.occ
					AND o.fin_id = i.fin_id
				WHERE o.fin_id = @fin_id1
				AND o.tip_id = COALESCE(@tip, o.tip_id)
				AND o.status_id <> 'закр'
				AND (o.saldo - o.PaymAccount) > 0
				AND i.KolMesDolg >= 0
	--and i.fin_id=@fin_pred

	IF @sup_id IS NULL
		INSERT
		INTO @dolg
		(	occ
			,sup_id
			,sector_id
			,div_id
			,sumdolg
			,kolmes)
				SELECT
					o.occ
					,NULL
					,b.sector_id
					,b.div_id
					,(o.SaldoAll - o.Paymaccount_ServAll) AS sumdolg
					,i.KolMesDolgAll AS kolmes
				FROM dbo.View_OCC_ALL AS o
				JOIN dbo.View_BUILD_ALL AS b 
					ON o.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.INTPRINT AS i 
					ON o.occ = i.occ
					AND o.fin_id = i.fin_id
				WHERE o.fin_id = @fin_id1
				AND (o.tip_id = @tip
				OR @tip IS NULL)
				AND o.status_id <> 'закр'
				AND (o.SaldoAll - o.Paymaccount_ServAll) > 0
				AND i.KolMesDolgAll >= 0

	IF @sup_id > 0
		INSERT
		INTO @dolg
		(	occ
			,sup_id
			,sector_id
			,div_id
			,sumdolg
			,kolmes)
				SELECT
					o.occ
					,i.sup_id
					,b.sector_id
					,b.div_id
					,(o.SaldoAll - o.Paymaccount_ServAll) AS sumdolg
					,i.KolMesDolg AS kolmes
				FROM dbo.View_occ_all AS o
				JOIN dbo.View_build_all AS b 
					ON o.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.Occ_Suppliers AS i 
					ON o.occ = i.occ
					AND o.fin_id = i.fin_id
				WHERE 
					o.fin_id = @fin_id1
					AND (o.tip_id = @tip OR @tip IS NULL)
					AND i.sup_id = @sup_id
					AND o.status_id <> 'закр'
					AND (i.saldo - (i.paymaccount-i.paymaccount_peny) ) > 0
					AND i.KolMesDolg >= 0

	UPDATE d
	SET	group_kolmes	=
			CASE
				WHEN kolmes >= 0 AND
				kolmes < 1 THEN '0'
				WHEN kolmes >= 1 AND
				kolmes < 3 THEN '1-3'
				WHEN kolmes >= 3 AND
				kolmes < 6 THEN '3-6'
				WHEN kolmes >= 6 AND
				kolmes < 9 THEN '6-9'
				WHEN kolmes >= 9 AND
				kolmes < 12 THEN '9-12'
				WHEN kolmes >= 12 AND
				kolmes < 18 THEN '12-18'
				WHEN kolmes >= 18 AND
				kolmes < 36 THEN '18-36'
				WHEN kolmes >= 36 THEN 'более 36'
				ELSE '?'
			END
		,sort_no		=
			CASE
				WHEN kolmes >= 0 AND
				kolmes < 1 THEN 1
				WHEN kolmes >= 1 AND
				kolmes < 3 THEN 2
				WHEN kolmes >= 3 AND
				kolmes < 6 THEN 3
				WHEN kolmes >= 6 AND
				kolmes < 9 THEN 4
				WHEN kolmes >= 9 AND
				kolmes < 12 THEN 5
				WHEN kolmes >= 12 AND
				kolmes < 18 THEN 6
				WHEN kolmes >= 18 AND
				kolmes < 36 THEN 7
				WHEN kolmes >= 36 THEN 8
				ELSE 10
			END
	FROM @dolg AS d

	--SELECT *	FROM @dolg AS dolg

	SELECT
		CASE
			WHEN @only_itogi = 0 THEN div.name
			ELSE '-'
		END AS name2
		,CASE
			WHEN @only_itogi = 0 THEN s.name
			ELSE '-'
		END AS [name]
		,group_kolmes
		,sort_no
		,COUNT(dolg.occ) AS count_occ
		,SUM(dolg.sumdolg) AS sum_kolmes
	FROM @dolg AS dolg
	JOIN dbo.SECTOR AS s ON 
		dolg.sector_id = s.id
	JOIN dbo.DIVISIONS AS div ON 
		dolg.div_id = div.id
	GROUP BY	div.name
				,s.name
				,dolg.group_kolmes
				,sort_no
	ORDER BY div.name, s.name, dolg.sort_no
go

