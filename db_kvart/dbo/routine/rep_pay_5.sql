CREATE   PROCEDURE [dbo].[rep_pay_5]
(
	  @date1 DATETIME
	, @date2 DATETIME = NULL
	, @bank_id1 INT = NULL
	, @tip SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
)
AS
	--
	-- Сводный реестр электронных платежей
	-- Показываем:
	-- 1. Сумму не вошедших платежей
	-- 2. Кол. не вошедших
	-- 3. Сумму вошедших
	-- 4. Кол. вошедших
	-- 5. Итого сумма
	-- 6. Итого количество
	--
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	IF @bank_id1 = 0
		SET @bank_id1 = NULL
	IF @tip = 0
		SET @tip = NULL

	IF @date2 IS NULL
		SET @date2 = @date1
	IF @date2 < @date1
		SET @date2 = @date1


	CREATE TABLE #t (
		  pdate SMALLDATETIME
		, bank SMALLINT
		, sum1 DECIMAL(15, 2) NULL
		, kol1 INT NULL
		, sum1_com DECIMAL(15, 2) DEFAULT 0
		, sum2 DECIMAL(15, 2) NULL
		, kol2 INT NULL
		, sum2_com DECIMAL(15, 2) DEFAULT 0
		, sum3 DECIMAL(15, 2) NULL
		, kol3 INT NULL
		, sum3_com DECIMAL(15, 2) DEFAULT 0
	)

	SELECT pdate
		 , po.bank
		 , sum1 = SUM(sum_opl)
		 , kol1 = COUNT(bd.id)
		 , sum1_com = SUM(COALESCE(bd.commission, 0))
	INTO #t1
	FROM dbo.Bank_Dbf AS bd 
		JOIN dbo.View_paycoll_orgs AS po 
			ON bd.bank_id = po.ext
	WHERE 
		bd.Occ IS NULL
		AND pdate BETWEEN @date1 AND @date2
		AND po.fin_id = @fin_current
		AND po.bank = COALESCE(@bank_id1, po.bank)
		AND (bd.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY pdate
		   , po.bank

	SELECT pdate
		 , po.bank
		 , sum2 = SUM(sum_opl)
		 , kol2 = COUNT(bd.id)
		 , sum2_com = SUM(COALESCE(bd.commission, 0))
	INTO #t2
	FROM dbo.Bank_Dbf AS bd 
		JOIN dbo.View_paycoll_orgs AS po 
			ON bd.bank_id = po.ext
		JOIN dbo.VOcc AS o 
			ON bd.Occ = o.Occ
	WHERE 
		bd.Occ IS NOT NULL
		AND o.tip_id = COALESCE(@tip, o.tip_id)
		AND pdate BETWEEN @date1 AND @date2
		AND po.fin_id = @fin_current
		AND po.bank = COALESCE(@bank_id1, po.bank)
		AND o.bldn_id = COALESCE(@build_id, o.bldn_id)
		AND (bd.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY pdate
		   , po.bank

	INSERT INTO #t
	SELECT pdate
		 , po.bank
		 , 0
		 , 0
		 , 0
		 , 0
		 , 0
		 , 0
		 , SUM(sum_opl)
		 , COUNT(bd.id)
		 , SUM(COALESCE(bd.commission, 0))
	FROM dbo.Bank_Dbf AS bd 
		JOIN dbo.View_paycoll_orgs AS po 
			ON bd.bank_id = po.ext
		JOIN dbo.VOcc AS o 
			ON bd.Occ = o.Occ
	WHERE 
		bd.pdate BETWEEN @date1 AND @date2
		--and o.tip_id=COALESCE(@tip,o.tip_id)
		AND po.fin_id = @fin_current
		AND po.bank = COALESCE(@bank_id1, po.bank)
		AND o.bldn_id = COALESCE(@build_id, o.bldn_id)
		AND (bd.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY pdate
		   , po.bank


	UPDATE #t
	SET sum2 = t2.sum2
	  , kol2 = t2.kol2
	  , sum2_com = t2.sum2_com
	FROM #t AS t
	   , #t2 AS t2
	WHERE t.pdate = t2.pdate
		AND t.bank = t2.bank

	UPDATE #t
	SET sum1 = t1.sum1
	  , kol1 = t1.kol1
	  , sum1_com = t1.sum1_com
	FROM #t AS t
	   , #t1 AS t1
	WHERE t.pdate = t1.pdate
		AND t.bank = t1.bank

	SELECT t.*
		 , b.short_name
	FROM #t AS t
		JOIN dbo.bank AS b ON t.bank = b.id
	ORDER BY t.pdate

	DROP TABLE IF EXISTS #t;
go

