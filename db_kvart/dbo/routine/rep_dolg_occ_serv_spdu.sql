-- =============================================
-- Author:		Пузанов
-- Create date: 31/10/14
-- Description:	по единой квитанции + заданные поставщики
-- =============================================
CREATE   PROCEDURE [dbo].[rep_dolg_occ_serv_spdu]
	@OCC			INT			= NULL
	,@fin_id1		SMALLINT
	,@fin_id2		SMALLINT
	,@PrintGroup	SMALLINT	= NULL
	,@div_id		SMALLINT	= NULL
AS
/*
для отчёта Задолженность по группе (Задолженность по услугам)
в Картотеке

exec [rep_dolg_occ_serv] 1,40093,108,142,null,null,null
exec [rep_dolg_occ_serv] 1,700002131,108,142,null,null,null
exec [rep_dolg_occ_serv] 3,910000723,108,143,null,null,null
exec [rep_dolg_occ_serv] 2,680002998,130,148,323,null,null
exec [rep_dolg_occ_serv] 3,700103553,132,150,null,null,null
*/
BEGIN
	SET NOCOUNT ON;
	IF @OCC IS NULL
		AND @PrintGroup IS NULL
		SET @OCC = 0
	IF @OCC IS NOT NULL
		AND @PrintGroup IS NOT NULL
		SET @OCC = 0

	IF @fin_id1 IS NULL
		OR @fin_id2 IS NULL
		SELECT
			@fin_id1 = 0
			,@fin_id2 = 0

	DECLARE @DogovorBuild VARCHAR(200)
	SELECT
		@DogovorBuild = dbo.Fun_GetDogovorBuild(@OCC)

	DECLARE @t_occ TABLE
		(
			occ			INT				PRIMARY KEY
			,address	VARCHAR(60)		DEFAULT ''
			,KolMesDolg	DECIMAL(5, 1)	DEFAULT 0
			,Initials	VARCHAR(120)	DEFAULT ''
			,vid_blag	SMALLINT		DEFAULT NULL
		)

	IF @PrintGroup IS NULL
	BEGIN
		;
		WITH cte_intprint
		AS
		(SELECT TOP 1
				occ
				,Initials
				,KolMesDolg
				,KolMesDolgAll
			FROM dbo.INTPRINT
			WHERE occ = @OCC
			AND fin_id <= @fin_id2
			ORDER BY fin_id DESC)
		INSERT INTO @t_occ
		(	occ
			,address
			,KolMesDolg
			,Initials
			,vid_blag)
				SELECT
					O.occ
					,O.address
					,i.KolMesDolgAll  --,i.KolMesDolg
					,i.Initials
					,B.vid_blag
				FROM dbo.OCCUPATIONS AS O 
				JOIN dbo.FLATS AS F 
					ON O.flat_id = F.id
				JOIN dbo.BUILDINGS AS B 
					ON F.bldn_id = B.id
				LEFT JOIN cte_intprint AS i 
					ON O.occ = i.occ
				WHERE O.occ = @OCC
	END
	ELSE
		INSERT INTO @t_occ
		(	occ
			,address
			,KolMesDolg
			,Initials
			,vid_blag)
				SELECT
					po.occ
					,O.address
					,i.KolMesDolgAll --,i.KolMesDolg
					,i.Initials
					,B.vid_blag
				FROM dbo.PRINT_OCC AS po 
				JOIN dbo.OCCUPATIONS AS O 
					ON po.occ = O.occ
				JOIN dbo.FLATS AS F 
					ON O.flat_id = F.id
				JOIN dbo.BUILDINGS AS B 
					ON F.bldn_id = B.id
				LEFT JOIN dbo.INTPRINT AS i 
					ON O.occ = i.occ
					AND i.fin_id = @fin_id2 -- кол-во месяцев долга только в последнем периоде
				WHERE po.group_id = @PrintGroup
				AND B.div_id = COALESCE(@div_id, B.div_id)

	--SELECT * FROM @t_occ
	SELECT
		p.occ
		,p.fin_id
		,p.occ AS occ1
		,dbo.Fun_NameFinPeriod(p.fin_id) AS 'Фин.период'
		,CAST(p.saldo + COALESCE(os.saldo, 0) AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
		,CAST(p.Value + COALESCE(os.Value, 0) AS DECIMAL(9, 2)) AS 'Начислено'
		,CAST(p.Penalty_old_new + COALESCE(os.Penalty_old_new, 0) AS DECIMAL(9, 2)) AS 'Пени стар.'
		,CAST(p.Penalty_value + COALESCE(os.Penalty_value, 0) AS DECIMAL(9, 2)) AS 'Пени'
		,CAST((p.Penalty_old_new + p.Penalty_value) + (COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS DECIMAL(9, 2)) AS 'Пени итого'
		,CAST(p.Discount AS DECIMAL(9, 2)) AS 'Льготы'
		,CAST(p.Added + COALESCE(os.Added, 0) AS DECIMAL(9, 2)) AS 'Перерасчет'
		,CAST(p.Paid + COALESCE(os.Paid, 0) AS DECIMAL(12, 2)) AS 'Итого начисл.'
		,CAST(p.PaymAccount + COALESCE(os.PaymAccount, 0) AS DECIMAL(9, 2)) AS 'Оплатил'
		,CAST(p.PaymAccount_peny + COALESCE(os.PaymAccount_peny, 0) AS DECIMAL(9, 2)) AS 'из них пени'
		,CAST(p.Debt + COALESCE(os.Debt, 0) AS DECIMAL(9, 2)) AS 'Кон. сальдо'
		,CAST(p.Whole_payment + COALESCE(os.Whole_payment, 0) AS DECIMAL(9, 2)) AS 'К оплате'
		,YEAR(p.start_date) AS 'Год'
		,dbo.Fun_GetDateVidPaymStr(p.occ, p.fin_id, NULL) AS 'Вид платежа'
		,t.address
		,t.KolMesDolg
		,p.total_sq
		,vba.norma_gkal
		,p.kol_people
		,vba.arenda_sq
		,vba.build_total_sq
		,vba.opu_sq
		,CASE
			WHEN (vba.opu_sq > 0 AND
			vba.build_total_sq > 0) THEN CAST(vba.opu_sq AS MONEY) * p.total_sq / (vba.build_total_sq + COALESCE(vba.arenda_sq, 0))
			ELSE 0
		END AS occ_opu_sq
		,CASE
			WHEN (vba.opu_sq > 0 AND
			vba.build_total_sq > 0) THEN STR(vba.opu_sq, 6, 2) + '*' + STR(p.total_sq, 6, 2) + '/(' + STR(vba.build_total_sq, 6, 2) + '+' + LTRIM(STR(COALESCE(vba.arenda_sq, 0), 6, 2)) + ')'
			ELSE ''
		END AS occ_opu_sq_str
		,@DogovorBuild AS DogovorBuild
		,t.Initials
		,vb.name AS vid_blag
		,COALESCE((SELECT
				SUM(bsv.[kol_people_serv])
			FROM dbo.[BUILD_SOURCE_VALUE] AS bsv 
			WHERE bsv.fin_id = vba.fin_id
			AND bsv.[build_id] = vba.bldn_id
			AND bsv.service_id IN ('хвод', 'хвс2'))
		, 0) AS kol_people_build
	FROM @t_occ AS t
	JOIN dbo.View_OCC_ALL AS p 
		ON p.occ = t.occ
	JOIN dbo.View_BUILD_ALL AS vba 
		ON p.bldn_id = vba.bldn_id
		AND p.fin_id = vba.fin_id
	LEFT JOIN (SELECT
			os1.fin_id
			,os1.occ
			,SUM(os1.saldo) AS saldo
			,SUM(os1.value) AS value
			,SUM(os1.added) AS added
			,SUM(os1.paid) AS paid
			,SUM(os1.Penalty_old_new) AS Penalty_old_new
			,SUM(os1.Penalty_value) AS Penalty_value
			,SUM(os1.paymaccount) AS paymaccount
			,SUM(os1.PaymAccount_peny) AS PaymAccount_peny
			,SUM(os1.debt) AS debt
			,SUM(os1.Whole_payment) AS Whole_payment
		FROM dbo.VOcc_Suppliers os1
		WHERE 
			os1.occ = @OCC
			AND os1.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND os1.sup_id IN (300)
		GROUP BY	os1.fin_id
					,os1.occ
		) AS os
		ON p.fin_id = os.fin_id
			AND p.occ = os.occ
	LEFT JOIN dbo.vid_blag AS vb
		ON t.vid_blag = vb.id
	WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
	ORDER BY p.occ
	, p.fin_id DESC


END
go

