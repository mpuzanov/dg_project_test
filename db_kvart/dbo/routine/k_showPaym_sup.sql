CREATE   PROCEDURE [dbo].[k_showPaym_sup]
(
	  @occ INT
	, @sup_id INT = NULL
	, @fin_id SMALLINT = NULL
)
/*
EXEC k_showPaym_sup @occ=910001131, @sup_id=347, @fin_id=244
*/
AS

	SET NOCOUNT ON

	IF @fin_id IS NULL
		OR @fin_id = 0
		SELECT @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	--DECLARE @t TABLE (
	--	  short_name VARCHAR(20)
	--	, service_no SMALLINT
	--	, occ INT
	--	, service_id VARCHAR(10)
	--	, subsid_only BIT
	--	, account_one BIT
	--	, is_counter TINYINT
	--	, kol DECIMAL(15, 6) DEFAULT NULL
	--	, tarif DECIMAL(10, 4)
	--	, koef DECIMAL(10, 4) DEFAULT NULL
	--	, saldo DECIMAL(9, 2)
	--	, socvalue DECIMAL(9, 2)
	--	, value DECIMAL(9, 2)
	--	, added DECIMAL(9, 2)
	--	, paid DECIMAL(9, 2)
	--	, paymaccount DECIMAL(9, 2)
	--	, paymaccount_peny DECIMAL(9, 2)
	--	, debt DECIMAL(9, 2)
	--	, short_id VARCHAR(6)
	--	, metod VARCHAR(12) DEFAULT NULL
	--	, occ_sup INT
	--	, kol_norma DECIMAL(10, 4) DEFAULT NULL
	--	, penalty_prev DECIMAL(9, 2)
	--	, penalty_old DECIMAL(9, 2)
	--	, penalty_serv DECIMAL(9, 2)
	--	, penalty_itog DECIMAL(9, 2)
	--)

	--INSERT INTO @t
;WITH cte AS (
	SELECT s.short_name
		 , service_no = s.sort_no
		 , p.occ
		 , p.service_id
		 , p.subsid_only
		 , p.account_one
		 , p.is_counter
		 , CASE WHEN(p.kol = 0) THEN NULL ELSE ROUND(p.kol, COALESCE(u.precision, 4)) END AS kol
		 , p.tarif
		 , NULL AS koef
		 , p.saldo
		 , 0.0 AS socvalue
		 , p.value
		 , p.added
		 , p.paid
		 , p.paymaccount
		 , p.paymaccount_peny
		 , p.debt
		 , u.short_id
		 , metod =
				  CASE
					  WHEN p.metod = 0 THEN 'не начислять'
					  WHEN p.metod = 2 THEN 'по среднему'
					  WHEN p.metod = 3 THEN 'по счетчику'
					  WHEN p.metod = 4 THEN 'по домовому'
					  WHEN p.is_counter > 0 THEN 'по норме'
					  ELSE NULL
				  END
		 , occ_sup
		 , p.kol_norma
		 , p.penalty_prev
		 , p.penalty_old
		 , p.penalty_serv
		 , p.penalty_old + p.penalty_serv AS penalty_itog
	FROM dbo.Occ_Suppliers AS os 
		JOIN dbo.View_paym AS p ON os.occ = p.occ
			AND os.fin_id = p.fin_id
			AND os.sup_id = p.sup_id
		JOIN dbo.View_services AS s ON p.service_id = s.id
		LEFT JOIN dbo.Units AS u ON p.unit_id = u.id
	WHERE os.occ = @occ
		AND os.fin_id = @fin_id
		AND (os.sup_id = @sup_id OR @sup_id IS NULL)
		AND p.account_one = 1
		AND (p.saldo <> 0 OR p.value <> 0 OR p.added <> 0 OR p.paid <> 0 OR p.paymaccount <> 0 OR p.penalty_serv <> 0 OR p.penalty_old <> 0 OR p.penalty_prev <> 0 OR p.tarif <> 0 OR p.kol <> 0 OR 
		(p.mode_id % 1000 <> 0 OR p.source_id % 1000 <> 0))
)
	--select * from @t
	SELECT short_name
		 , service_no
		 , occ
		 , service_id
		 , subsid_only
		 , account_one
		 , is_counter
		 , short_id
		 , CAST(kol AS DECIMAL(12, 6)) AS kol
		 , tarif
		 , CAST(koef AS DECIMAL(10, 4)) AS koef
		 , metod
		 , occ_sup
		 , kol_norma
		 , CAST(saldo AS DECIMAL(9, 2)) AS saldo
		 , CAST(socvalue AS DECIMAL(9, 2)) AS socvalue
		 , CAST(value AS DECIMAL(9, 2)) AS value
		 , CAST(added AS DECIMAL(9, 2)) AS added
		 , CAST(paid AS DECIMAL(9, 2)) AS paid
		 , CAST(paymaccount AS DECIMAL(9, 2)) AS paymaccount
		 , CAST(paymaccount_peny AS DECIMAL(9, 2)) AS paymaccount_peny
		 , CAST(debt AS DECIMAL(9, 2)) AS debt
		 , CAST(penalty_prev AS DECIMAL(9, 2)) AS penalty_prev
		 , CAST(penalty_old AS DECIMAL(9, 2)) AS penalty_old
		 , CAST(penalty_serv AS DECIMAL(9, 2)) AS penalty_serv
		 , CAST(penalty_itog AS DECIMAL(9, 2)) AS penalty_itog
	FROM cte
	UNION ALL
	SELECT 'Итого:'
		 , 999
		 , NULL
		 , NULL
		 ,            -- p.occ,p.service_id,
		   NULL
		 , NULL
		 , NULL
		 , NULL
		 , -- cl.subsid_only, p.account_one,cl.is_counter,short_id,
		   NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , -- kol,tarif,koef,metod,occ_sup, kol_norma
		   SUM(saldo)
		 , SUM(socvalue)
		 , SUM(value)
		 , SUM(added)
		 , SUM(paid)
		 , SUM(paymaccount)
		 , SUM(paymaccount_peny)
		 , SUM(debt)
		 , SUM(penalty_prev)
		 , SUM(penalty_old)
		 , SUM(penalty_serv)
		 , SUM(penalty_itog)
	FROM cte
	ORDER BY service_no
go

