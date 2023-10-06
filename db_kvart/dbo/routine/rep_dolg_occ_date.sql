-- =============================================
-- Author:		Пузанов
-- Create date: 04/04/13
-- Description:	
-- =============================================
CREATE   PROCEDURE [dbo].[rep_dolg_occ_date]
	  @P1 SMALLINT  -- 1-по всем услугам, 2- по единой, 3- по поставщику  из rep_vibor
	, @OCC INT = NULL
	, @date1 SMALLDATETIME = NULL
	, @date2 SMALLDATETIME = NULL
	, @sup_id INT = NULL
	, @PrintGroup SMALLINT = NULL
	, @div_id SMALLINT = NULL
	, @debug BIT = 0
	, @blocked_payment BIT = 0  -- не использовать в отчёте оплате
AS
/*
для отчёта Задолженность по группе (Задолженность по услугам) по датам
в Картотеке

exec [rep_dolg_occ_date] 3,264377,'20120101','20211001',365,null,null
exec [rep_dolg_occ_date] 2,264377,'20120101','20211001',0,null,null
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_id1 SMALLINT
		  , @fin_id2 SMALLINT

	SELECT @fin_id1 = gv.fin_id
	FROM Global_values gv
	WHERE @date1 BETWEEN gv.start_date AND gv.end_date

	SELECT @fin_id2 = gv.fin_id
	FROM Global_values gv
	WHERE @date2 BETWEEN gv.start_date AND gv.end_date

	IF @OCC IS NULL
		AND @PrintGroup IS NULL
		SET @OCC = 0
	IF @OCC IS NOT NULL
		AND @PrintGroup IS NOT NULL
		SET @OCC = 0
	IF @P1 IS NULL
		OR @P1 NOT IN (1, 2, 3)
		SET @P1 = 1
	IF @fin_id1 IS NULL
		OR @fin_id2 IS NULL
		SELECT @fin_id1 = 0
			 , @fin_id2 = 0

	DECLARE @DogovorBuild VARCHAR(200)
	SELECT @DogovorBuild = dbo.Fun_GetDogovorBuild(@OCC)

	DECLARE @t_occ TABLE (
		  occ INT PRIMARY KEY
		, address VARCHAR(60) DEFAULT ''
		, KolMesDolg DECIMAL(5, 1) DEFAULT 0
		, Initials VARCHAR(120) DEFAULT ''
		, vid_blag SMALLINT DEFAULT NULL
	)

	IF @PrintGroup IS NULL
	BEGIN
		INSERT INTO @t_occ (occ
						  , address
						  , KolMesDolg
						  , Initials
						  , vid_blag)
		SELECT O.occ
			 , O.address
			 , CASE
				   WHEN @P1 = 1 THEN dbo.Fun_DolgMesCalAll_date(O.occ, @fin_id1, @fin_id2)
				   ELSE dbo.Fun_DolgMesCal_date(O.occ, @fin_id1, @fin_id2)
			   END
			 , dbo.Fun_Initials_All(O.occ) AS Initials
			 , B.vid_blag
		FROM dbo.Occupations AS O 
			JOIN dbo.Flats AS F ON 
				O.flat_id = F.id
			JOIN dbo.Buildings AS B ON 
				F.bldn_id = B.id
		WHERE 
			O.occ = @OCC
	END
	ELSE
		INSERT INTO @t_occ (occ
						  , address
						  , KolMesDolg
						  , Initials
						  , vid_blag)
		SELECT po.occ
			 , O.address
			 , CASE
				   WHEN @P1 = 1 THEN dbo.Fun_DolgMesCalAll_date(O.occ, @fin_id1, @fin_id2)
				   ELSE dbo.Fun_DolgMesCal_date(O.occ, @fin_id1, @fin_id2)
			   END
			 , dbo.Fun_Initials_All(O.occ) AS Initials
			 , B.vid_blag
		FROM dbo.Print_occ AS po 
			JOIN dbo.Occupations AS O ON 
				po.occ = O.occ
			JOIN dbo.Flats AS F ON 
				O.flat_id = F.id
			JOIN dbo.Buildings AS B ON 
				F.bldn_id = B.id
		WHERE 
			po.group_id = @PrintGroup
			AND (B.div_id = @div_id OR @div_id IS NULL)

	IF @debug=1 
	BEGIN
		SELECT @fin_id1 AS fin_id1, @fin_id2 AS fin_id2
		SELECT * FROM @t_occ
		--RETURN 1
	end

	CREATE TABLE #Table1 (
		  [occ] INT NOT NULL
		, [fin_id] SMALLINT NOT NULL
		, [occ1] INT NOT NULL
		, [Фин.период] VARCHAR(15) COLLATE database_default NULL
		, [Вх.Сальдо] DECIMAL(9, 2) NULL
		, [Начислено] DECIMAL(9, 2) NULL
		, [Пени стар.] DECIMAL(9, 2) NULL
		, [Пени] DECIMAL(9, 2) NULL
		, [Пени итого] DECIMAL(9, 2) NULL
		, [Льготы] DECIMAL(9, 2) NULL
		, [Перерасчет] DECIMAL(9, 2) NULL
		, [Итого начисл.] DECIMAL(12, 2) NULL
		, [Оплатил] DECIMAL(9, 2) NULL
		, [из них пени] DECIMAL(9, 2) NULL
		, [Кон. сальдо] DECIMAL(9, 2) NULL
		, [К оплате] DECIMAL(9, 2) NULL
		, [Год] INT NULL
		, [Вид платежа] VARCHAR(50) COLLATE database_default NULL
		, [address] VARCHAR(60) COLLATE database_default NULL
		, [KolMesDolg] DECIMAL(5, 1) NOT NULL
		, [total_sq] DECIMAL(10, 4) NULL
		, [norma_gkal] DECIMAL(9, 6) NULL
		, [kol_people] SMALLINT NULL
		, [arenda_sq] DECIMAL(10, 4) NULL
		, [build_total_sq] DECIMAL(10, 4) NULL
		, [opu_sq] DECIMAL(10, 4) NULL
		, [occ_opu_sq] MONEY NULL
		, [occ_opu_sq_str] VARCHAR(29) COLLATE database_default NULL
		, [DogovorBuild] VARCHAR(200) COLLATE database_default NULL
		, [Initials] VARCHAR(120) COLLATE database_default NULL
		, [vid_blag] VARCHAR(150) COLLATE database_default NULL
		, [kol_people_build] INT NULL
		, [koefDay] DECIMAL(10, 4) NULL
	) ON [PRIMARY]

	-- по всем услугам
	IF @P1 = 1
	BEGIN
		INSERT INTO #Table1
		SELECT p.occ
			 , p.fin_id
			 , p.occ AS occ1
			 , dbo.Fun_NameFinPeriod(p.fin_id) AS 'Фин.период'
			 , CAST(p.saldo + COALESCE(os.saldo, 0) AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(p.value + COALESCE(os.value, 0) AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(p.Penalty_old_new + COALESCE(os.Penalty_old_new, 0) AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(p.Penalty_value + COALESCE(os.Penalty_value, 0) AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((p.Penalty_old_new + p.Penalty_value) + (COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(p.Discount AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(p.added + COALESCE(os.added, 0) AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(p.paid + COALESCE(os.paid, 0) AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(p.paymaccount + COALESCE(os.paymaccount, 0) AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny + COALESCE(os.PaymAccount_peny, 0) AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(p.debt + COALESCE(os.debt, 0) AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(p.Whole_payment + COALESCE(os.Whole_payment, 0) AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(p.start_date) AS 'Год'
			 , dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL) AS 'Вид платежа'
			 , t.address
			 , t.KolMesDolg
			 , p.total_sq
			 , vba.norma_gkal
			 , p.kol_people
			 , vba.arenda_sq
			 , vba.build_total_sq
			 , vba.opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN CAST(vba.opu_sq AS MONEY) * p.total_sq / (vba.build_total_sq + COALESCE(vba.arenda_sq, 0))
				   ELSE 0
			   END AS occ_opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN STR(vba.opu_sq, 6, 2) + '*' + STR(p.total_sq, 6, 2) + '/(' + STR(vba.build_total_sq, 6, 2) + '+' + LTRIM(STR(COALESCE(vba.arenda_sq, 0), 6, 2)) + ')'
				   ELSE ''
			   END AS occ_opu_sq_str
			 , @DogovorBuild AS DogovorBuild
			 , t.Initials
			 , vb.name AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv 
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
			 , dbo.Fun_GetKoefDay_FinPeriod(@date1, @date2, p.fin_id) AS koefDay
		FROM @t_occ AS t
			JOIN dbo.View_occ_all AS p ON p.occ = t.occ
			JOIN dbo.View_build_all AS vba ON p.bldn_id = vba.bldn_id
				AND p.fin_id = vba.fin_id
			LEFT JOIN (
				SELECT os1.fin_id
					 , os1.occ
					 , SUM(os1.saldo) AS saldo
					 , SUM(os1.value) AS value
					 , SUM(os1.added) AS added
					 , SUM(os1.paid) AS paid
					 , SUM(os1.Penalty_old_new) AS Penalty_old_new
					 , SUM(os1.Penalty_value) AS Penalty_value
					 , SUM(os1.paymaccount) AS paymaccount
					 , SUM(os1.PaymAccount_peny) AS PaymAccount_peny
					 , SUM(os1.debt) AS debt
					 , SUM(os1.Whole_payment) AS Whole_payment
				FROM dbo.VOcc_Suppliers os1 
				WHERE os1.occ = @OCC
					AND os1.fin_id BETWEEN @fin_id1 AND @fin_id2
				GROUP BY os1.fin_id
					   , os1.occ
			) AS os ON p.fin_id = os.fin_id
				AND p.occ = os.occ
			LEFT JOIN dbo.vid_blag AS vb ON t.vid_blag = vb.id
		WHERE 
			p.fin_id BETWEEN @fin_id1 AND @fin_id2
	--ORDER BY p.occ
	--, p.fin_id DESC
	END

	-- По единой лицевому счёту
	IF @P1 = 2
		INSERT INTO #Table1
		SELECT p.occ
			 , p.fin_id
			 , p.occ AS occ1
			 , dbo.Fun_NameFinPeriod(p.fin_id) AS 'Фин.период'
			 , CAST(p.saldo AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(p.value AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(p.Penalty_old_new AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(p.Penalty_value AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((p.Penalty_old_new + p.Penalty_value) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(p.Discount AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(p.added AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(p.paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(p.debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(p.Whole_payment AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(p.start_date) AS 'Год'
			 , dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL) AS 'Вид платежа'
			 , t.address
			 , t.KolMesDolg
			 , p.total_sq
			 , vba.norma_gkal
			 , p.kol_people
			 , vba.arenda_sq
			 , vba.build_total_sq
			 , vba.opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN CAST(vba.opu_sq AS MONEY) * p.total_sq / (vba.build_total_sq + COALESCE(vba.arenda_sq, 0))
				   ELSE 0
			   END AS occ_opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN STR(vba.opu_sq, 6, 2) + '*' + STR(p.total_sq, 6, 2) + '/(' + STR(vba.build_total_sq, 6, 2) + '+' + LTRIM(STR(COALESCE(vba.arenda_sq, 0), 6, 2)) + ')'
				   ELSE ''
			   END AS occ_opu_sq_str
			 , @DogovorBuild AS DogovorBuild
			 , t.Initials
			 , vb.name AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
			 , dbo.Fun_GetKoefDay_FinPeriod(@date1, @date2, p.fin_id) AS koefDay
		FROM dbo.View_occ_all AS p 
			JOIN @t_occ AS t ON 
				p.occ = t.occ
			JOIN dbo.View_build_all AS vba ON 
				p.bldn_id = vba.bldn_id
				AND p.fin_id = vba.fin_id
			LEFT JOIN dbo.vid_blag AS vb ON 
				t.vid_blag = vb.id
		WHERE 
			p.fin_id BETWEEN @fin_id1 AND @fin_id2
	--ORDER BY p.occ
	--, p.fin_id DESC

	-- По поставщику
	IF @P1 = 3
	BEGIN
		INSERT INTO #Table1
		SELECT p.occ_sup AS occ
			 , p.fin_id
			 , p.occ AS occ1
			 , dbo.Fun_NameFinPeriod(p.fin_id) AS 'Фин.период'
			 , CAST(p.saldo AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(p.value AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(p.Penalty_old_new AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(p.Penalty_value AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((p.Penalty_old_new + p.Penalty_value) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(0 AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(p.added AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(p.paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(p.debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(p.Whole_payment AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(o.start_date) AS 'Год'
			 , dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, p.sup_id) AS 'Вид платежа'
			 , t.address
			 , p.KolMesDolg
			 , o.total_sq
			 , vba.norma_gkal
			 , o.kol_people
			 , vba.arenda_sq
			 , vba.build_total_sq
			 , vba.opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN CAST(vba.opu_sq AS MONEY) * o.total_sq / (vba.build_total_sq + COALESCE(vba.arenda_sq, 0))
				   ELSE 0
			   END AS occ_opu_sq
			 , CASE
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN STR(vba.opu_sq, 6, 2) + '*' + STR(o.total_sq, 6, 2) + '/(' + STR(vba.build_total_sq, 6, 2) + '+' + LTRIM(STR(COALESCE(vba.arenda_sq, 0), 6, 2)) + ')'
				   ELSE ''
			   END AS occ_opu_sq_str
			 , @DogovorBuild AS DogovorBuild
			 , t.Initials
			 , vb.name AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv 
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
			 , dbo.Fun_GetKoefDay_FinPeriod(@date1, @date2, p.fin_id) AS koefDay
		FROM dbo.VOcc_Suppliers AS p
			JOIN @t_occ AS t ON 
				p.occ = t.occ
			JOIN dbo.View_occ_all AS o ON 
				p.occ = o.occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_build_all AS vba ON 
				o.bldn_id = vba.bldn_id
				AND o.fin_id = vba.fin_id
			LEFT JOIN dbo.vid_blag AS vb  ON t.vid_blag = vb.id
		WHERE 
			p.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (p.sup_id = @sup_id) -- OR @sup_id IS NULL)
	--ORDER BY p.occ_sup
	--, p.fin_id DESC
		--OPTION (RECOMPILE)
	END

	if @blocked_payment=1
		UPDATE #Table1 SET [Оплатил]=0, [из них пени]=0

	DECLARE @var1 SMALLINT

	DECLARE cur CURSOR LOCAL FOR
		SELECT fin_id
		FROM #Table1
		ORDER BY fin_id

	OPEN cur

	FETCH NEXT FROM cur INTO @var1

	WHILE @@fetch_status = 0
	BEGIN

		UPDATE t1
		SET [Начислено] = [Начислено] * t1.koefDay
		FROM #Table1 AS t1
		WHERE fin_id = @var1;

		UPDATE t1
		SET [Вх.Сальдо] = COALESCE(t2.[Кон. сальдо], 0)
		FROM #Table1 AS t1
			LEFT JOIN #Table1 AS t2 ON t1.occ = t2.occ
				AND (t2.fin_id) = (t1.fin_id - 1);

		UPDATE t1
		SET [Итого начисл.] = [Начислено] + [Перерасчет]
		  , [Кон. сальдо] = [Вх.Сальдо] + [Начислено] + [Перерасчет] - ([Оплатил] - [из них пени])
		  , [К оплате] =
						CASE
							WHEN [Вх.Сальдо] + [Начислено] + [Перерасчет] - ([Оплатил] - [из них пени]) < 0 THEN 0
							ELSE [Вх.Сальдо] + [Начислено] + [Перерасчет] - ([Оплатил] - [из них пени])
						END
		FROM #Table1 AS t1
		WHERE fin_id = @var1;

		FETCH NEXT FROM cur INTO @var1

	END

	CLOSE cur
	DEALLOCATE cur

	SELECT *
	FROM #Table1
	ORDER BY occ1
		   , fin_id DESC

END
go

