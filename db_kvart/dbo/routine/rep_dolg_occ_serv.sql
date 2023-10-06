-- =============================================
-- Author:		Пузанов
-- Create date: 04/04/13
-- Description:	
-- =============================================
CREATE      PROCEDURE [dbo].[rep_dolg_occ_serv]
	  @P1 SMALLINT  -- 1-по всем услугам, 2- по единой, 3- по поставщику  из rep_vibor
	, @OCC INT = NULL
	, @fin_id1 SMALLINT
	, @fin_id2 SMALLINT
	, @sup_id INT = NULL
	, @PrintGroup SMALLINT = NULL
	, @div_id SMALLINT = NULL
	, @KolMesDolg SMALLINT = -1
	, @debug BIT = NULL
AS
/*
для отчёта Задолженность по группе (Задолженность по услугам)
в Картотеке

exec [rep_dolg_occ_serv] @P1=1, @OCC=33014, @fin_id1=240, @fin_id2=245,@sup_id=0, @debug=0
exec [rep_dolg_occ_serv] @P1=2, @OCC=33014, @fin_id1=240, @fin_id2=245,@sup_id=0, @debug=0
exec [rep_dolg_occ_serv] @P1=3, @OCC=33014, @fin_id1=240, @fin_id2=245,@sup_id=345, @debug=0

exec [rep_dolg_occ_serv] 3,401014,250,258,345,null,null
exec [rep_dolg_occ_serv] 2,680003940,150,162,323,null,null
exec [rep_dolg_occ_serv] 2,680002998,169,172,323,1,null
exec [rep_dolg_occ_serv] @P1=3, @OCC=299614, @fin_id1=240, @fin_id2=245,@sup_id=365, @debug=0
*/
BEGIN
	SET NOCOUNT ON;

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
	IF @KolMesDolg IS NULL
		SET @KolMesDolg = -1

	IF @P1 = 3
		AND @sup_id IS NULL  -- нужно вернуть пустую выборку
		SET @OCC = 0

	DECLARE @DogovorBuild VARCHAR(200)
	SELECT @DogovorBuild = dbo.Fun_GetDogovorBuild(@OCC)

	CREATE TABLE #t_occ(
		  occ INT --PRIMARY KEY
		, occ_false INT
		, [address] VARCHAR(60) COLLATE database_default DEFAULT ''
		, KolMesDolg DECIMAL(5, 1) DEFAULT 0
		, Initials VARCHAR(120) COLLATE database_default DEFAULT ''
		, vid_blag VARCHAR(150) COLLATE database_default DEFAULT ''
	)
	CREATE UNIQUE INDEX occ ON #t_occ (occ, KolMesDolg) 

	IF @PrintGroup IS NULL
	BEGIN
		;
		WITH cte_intprint AS
		(
			SELECT TOP 1 occ
					   , Initials
					   , KolMesDolg
					   , KolMesDolgAll
			FROM dbo.Intprint
			WHERE occ = @OCC
				AND fin_id <= @fin_id2
			ORDER BY fin_id DESC
		)
		INSERT INTO #t_occ (occ
						  , occ_false
						  , address
						  , KolMesDolg
						  , Initials
						  , vid_blag)
		SELECT O.occ
			 , dbo.Fun_GetFalseOccOut(O.occ, O.tip_id) AS occ_false
			 , O.address
			 , CASE
				   WHEN @P1 = 1 THEN i.KolMesDolgAll
				   ELSE i.KolMesDolg
			   END
			 , i.Initials
			 , COALESCE(vb.name,'')
		FROM dbo.Occupations AS O
			JOIN dbo.Flats AS F ON 
				O.flat_id = F.id
			JOIN dbo.Buildings AS B ON 
				F.bldn_id = B.id
			LEFT JOIN cte_intprint AS i ON 
				O.occ = i.occ
			LEFT JOIN dbo.vid_blag AS vb ON 
				b.vid_blag = vb.id
		WHERE O.occ = @OCC
	END
	ELSE
		INSERT INTO #t_occ (occ
						  , occ_false
						  , address
						  , KolMesDolg
						  , Initials
						  , vid_blag)
		SELECT po.occ
			 , dbo.Fun_GetFalseOccOut(O.occ, O.tip_id) AS occ_false
			 , O.address
			 , CASE
				   WHEN @P1 = 1 THEN i.KolMesDolgAll
				   ELSE i.KolMesDolg
			   END
			 , i.Initials
			 , COALESCE(vb.name,'')
		FROM dbo.Print_occ AS po 
			JOIN dbo.Occupations AS O ON 
				po.occ = O.occ
			JOIN dbo.Flats AS F ON 
				O.flat_id = F.id
			JOIN dbo.Buildings AS B ON 
				F.bldn_id = B.id
			LEFT JOIN dbo.Intprint AS i ON 
				O.occ = i.occ
				AND i.fin_id = @fin_id2 -- кол-во месяцев долга только в последнем периоде
			LEFT JOIN dbo.vid_blag AS vb ON 
				b.vid_blag = vb.id
		WHERE po.group_id = @PrintGroup
			AND (B.div_id = @div_id OR @div_id IS NULL)

	IF @debug = 1 
		SELECT * FROM #t_occ

	-- по всем услугам
	IF @P1 = 1
		SELECT t.occ_false AS occ  --p.occ
			 , p.fin_id
			 , p.occ AS occ1
			 , dbo.Fun_NameFinPeriodDate(p.start_date) AS 'Фин.период' --'MMMM yyyy'
			 , 0 AS 'Тариф'
			 , CAST(p.SALDO + COALESCE(os.SALDO, 0) AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(p.Value + COALESCE(os.Value, 0) AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(p.Penalty_old_new + COALESCE(os.Penalty_old_new, 0) AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(p.Penalty_value + COALESCE(os.Penalty_value, 0) AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((p.Penalty_old_new + p.Penalty_value) + (COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(p.Discount AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(p.Added + COALESCE(os.Added, 0) AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(p.Paid + COALESCE(os.Paid, 0) AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(p.PaymAccount + COALESCE(os.PaymAccount, 0) AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny + COALESCE(os.PaymAccount_peny, 0) AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(p.Debt + COALESCE(os.Debt, 0) AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(p.Whole_payment + COALESCE(os.Whole_payment, 0) AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(p.start_date) AS 'Год'
			 , dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL) AS 'Вид платежа'
			 , dbo.Fun_GetDatePaymStr(p.occ, p.fin_id, NULL) AS 'Даты платежей'
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
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) 
				   THEN CONCAT(vba.opu_sq, '*', p.total_sq, '/(', vba.build_total_sq, '+', COALESCE(vba.arenda_sq, 0), ')')
				   ELSE ''
			   END AS occ_opu_sq_str
			 , @DogovorBuild AS DogovorBuild
			 , t.Initials
			 , t.vid_blag AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv 
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
		FROM #t_occ AS t
			JOIN dbo.View_occ_all AS p ON 
				p.occ = t.occ
			JOIN dbo.View_build_all AS vba ON 
				p.bldn_id = vba.bldn_id
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
				FROM #t_occ AS t1
					JOIN dbo.VOcc_Suppliers os1 
						ON os1.occ = t1.occ
						AND os1.fin_id BETWEEN @fin_id1 AND @fin_id2
				GROUP BY os1.fin_id
					   , os1.occ
			) AS os ON p.fin_id = os.fin_id
				AND p.occ = os.occ
		WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND t.KolMesDolg > @KolMesDolg
		ORDER BY vba.street_name
			   , vba.nom_dom_sort
			   , p.nom_kvr_sort
			   , p.occ
			   , p.fin_id DESC

	-- По единой лицевому счёту
	IF @P1 = 2
		SELECT t.occ_false AS occ --p.occ
			 , p.fin_id
			 , p.occ AS occ1
			 , dbo.Fun_NameFinPeriodDate(p.start_date) AS 'Фин.период' --'MMMM yyyy'
			 , 0 AS 'Тариф'
			 , CAST(p.SALDO AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(p.Value AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(p.Penalty_old_new AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(p.Penalty_value AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((p.Penalty_old_new + p.Penalty_value) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(p.Discount AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(p.Added AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(p.Paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(p.PaymAccount AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(p.Debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(p.Whole_payment AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(p.start_date) AS 'Год'
			 , CASE WHEN p.PaymAccount>0 THEN dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL) ELSE '' END AS 'Вид платежа'
			 , dbo.Fun_GetDatePaymStr(p.occ, p.fin_id, NULL) AS 'Даты платежей'
			 , t.address
			 , t.KolMesDolg
			 , p.total_sq
			 , vba.norma_gkal
			 , p.kol_people
			 , vba.arenda_sq
			 , vba.build_total_sq
			 , vba.opu_sq
			 , occ_opu_sq =
						   CASE
							   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) THEN CAST(vba.opu_sq AS MONEY) * p.total_sq / (vba.build_total_sq + COALESCE(vba.arenda_sq, 0))
							   ELSE 0
						   END
			 , occ_opu_sq_str =
							CASE
								WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) 								   
								THEN CONCAT(vba.opu_sq, '*', p.total_sq, '/(', vba.build_total_sq, '+', COALESCE(vba.arenda_sq, 0), ')')
								ELSE ''
							END
			 , DogovorBuild = @DogovorBuild
			 , t.Initials
			 , t.vid_blag AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv 
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
		FROM dbo.View_occ_all AS p 
			JOIN #t_occ AS t ON 
				p.occ = t.occ
			JOIN dbo.View_build_all AS vba ON 
				p.bldn_id = vba.bldn_id
				AND p.fin_id = vba.fin_id
		WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND t.KolMesDolg > @KolMesDolg
		ORDER BY vba.street_name
			   , vba.nom_dom_sort
			   , p.nom_kvr_sort
			   , p.occ
			   , p.fin_id DESC

	-- По поставщику
	IF @P1 = 3
	BEGIN

		UPDATE t
		SET KolMesDolg = p.KolMesDolg
		FROM #t_occ AS t
			JOIN dbo.Occ_Suppliers AS p ON 
				p.occ = t.occ
		WHERE p.fin_id = @fin_id2
			AND p.sup_id = @sup_id

		SELECT os.occ_sup AS occ  --t.occ_false p.occ
			 , p.fin_id
			 , p.occ AS occ1  --
			 , dbo.Fun_NameFinPeriodDate(p.start_date) AS 'Фин.период' --'MMMM yyyy'
			 --, 0 AS 'Тариф'
			 , CAST(CASE
				   WHEN p.total_sq > 0 AND
					   os.Value > 0 THEN os.Value / p.total_sq
				   ELSE 0
			   END AS DECIMAL(9, 4)) AS 'Тариф'
			 , CAST(COALESCE(os.SALDO, 0) AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			 , CAST(COALESCE(os.Value, 0) AS DECIMAL(9, 2)) AS 'Начислено'
			 , CAST(COALESCE(os.Penalty_old_new, 0) AS DECIMAL(9, 2)) AS 'Пени стар.'
			 , CAST(COALESCE(os.Penalty_value, 0) AS DECIMAL(9, 2)) AS 'Пени'
			 , CAST((COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS DECIMAL(9, 2)) AS 'Пени итого'
			 , CAST(0 AS DECIMAL(9, 2)) AS 'Льготы'
			 , CAST(COALESCE(os.Added, 0) AS DECIMAL(9, 2)) AS 'Перерасчет'
			 , CAST(COALESCE(os.Paid, 0) AS DECIMAL(12, 2)) AS 'Итого начисл.'
			 , CAST(COALESCE(os.PaymAccount, 0) AS DECIMAL(9, 2)) AS 'Оплатил'
			 , CAST(COALESCE(os.PaymAccount_peny, 0) AS DECIMAL(9, 2)) AS 'из них пени'
			 , CAST(COALESCE(os.Debt, 0) AS DECIMAL(9, 2)) AS 'Кон. сальдо'
			 , CAST(COALESCE(os.Whole_payment, 0) AS DECIMAL(9, 2)) AS 'К оплате'
			 , YEAR(p.start_date) AS 'Год'
			 , CASE WHEN os.PaymAccount>0 THEN dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL)  ELSE '' END AS 'Вид платежа'
			 , dbo.Fun_GetDatePaymStr(p.occ, p.fin_id, @sup_id) AS 'Даты платежей'
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
				   WHEN (vba.opu_sq > 0 AND vba.build_total_sq > 0) 					
				   THEN CONCAT(vba.opu_sq, '*', p.total_sq, '/(', vba.build_total_sq, '+', COALESCE(vba.arenda_sq, 0), ')')
				   ELSE ''
			   END AS occ_opu_sq_str
			 , @DogovorBuild AS DogovorBuild
			 , t.Initials
			 , t.vid_blag AS vid_blag
			 , COALESCE((
				   SELECT SUM(bsv.[kol_people_serv])
				   FROM dbo.[Build_source_value] AS bsv
				   WHERE bsv.fin_id = vba.fin_id
					   AND bsv.[build_id] = vba.bldn_id
					   AND bsv.service_id IN ('хвод', 'хвс2')
			   ), 0) AS kol_people_build
		FROM #t_occ AS t
			JOIN dbo.View_occ_all AS p ON 
				p.occ = t.occ
			JOIN dbo.View_build_all AS vba ON 
				p.bldn_id = vba.bldn_id
				AND p.fin_id = vba.fin_id
			JOIN (
				SELECT os1.fin_id
					 , os1.occ
					 , os1.occ_sup
					 , os1.saldo AS saldo
					 , os1.value AS value
					 , os1.added AS added
					 , os1.paid AS paid
					 , os1.Penalty_old_new AS Penalty_old_new
					 , os1.Penalty_value AS Penalty_value
					 , os1.paymaccount AS paymaccount
					 , os1.PaymAccount_peny AS PaymAccount_peny
					 , os1.debt AS debt
					 , os1.Whole_payment AS Whole_payment
				FROM #t_occ AS t1
					JOIN dbo.VOcc_Suppliers os1 ON 
						os1.occ = t1.occ
						AND os1.fin_id BETWEEN @fin_id1 AND @fin_id2
				WHERE os1.sup_id=@sup_id
					AND os1.occ_sup>0
			) AS os ON 
				p.fin_id = os.fin_id
				AND p.occ = os.occ				
		WHERE 
			p.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND t.KolMesDolg > @KolMesDolg
		ORDER BY vba.street_name
			   , vba.nom_dom_sort
			   , p.nom_kvr_sort
			   , p.occ
			   , p.fin_id DESC

	END


END
go

