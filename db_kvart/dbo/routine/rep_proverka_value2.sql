-- =============================================
-- Author:		Пузанов Михаил
-- Create date: 10.01.2013
-- Description:	Для проверки расчётов (сравнение текущих и предыдущих начислений)  с использованием оконных функций
-- =============================================
CREATE     PROCEDURE [dbo].[rep_proverka_value2]
(
	  @tip_id SMALLINT = NULL
	, @div_id SMALLINT = NULL
	, @build_id INT = NULL
	, @service_id VARCHAR(10) = NULL
	, @step INT = 10
	, @fin_current SMALLINT = NULL
)
AS
/*
exec rep_proverka_value2 @tip_id=4, @service_id='площ', @fin_current=235
exec rep_proverka_value2 @tip_id=4, @build_id=6795
exec rep_proverka_value2 @tip_id=4, @build_id=6801, @service_id='вотв'
exec rep_proverka_value2 @tip_id=4
*/
BEGIN
	SET NOCOUNT ON;

	IF @step IS NULL
		SET @step = 10

	IF @tip_id IS NULL
		AND @div_id IS NULL
		AND @build_id IS NULL
		SET @tip_id = 0


	DECLARE @fin_prev SMALLINT

	IF @fin_current IS NULL
		SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	SET @fin_prev = @fin_current - 1

	DECLARE @t TABLE (
		  fin_id SMALLINT
		, id INT
		, service_id VARCHAR(10)
		, street_name VARCHAR(50) DEFAULT ''
		, nom_dom VARCHAR(12) DEFAULT ''
		, nom_kvr VARCHAR(20) DEFAULT ''
		, [address] VARCHAR(100) DEFAULT ''
		, value1 DECIMAL(10, 2) DEFAULT 0 -- начисление тек.месяца
		, value_prev DECIMAL(10, 2) DEFAULT 0 -- начисление предыдущего месяца
		, add_value DECIMAL(10, 2) DEFAULT 0
		, paid1 DECIMAL(10, 2) DEFAULT 0 -- тек.месяца
		, paid_prev DECIMAL(10, 2) DEFAULT 0 -- предыдущего месяца
		, add_paid DECIMAL(10, 2) DEFAULT 0
		, kol1 DECIMAL(12, 4) DEFAULT 0 --  тек.месяца
		, kol_prev DECIMAL(12, 4) DEFAULT 0 --  предыдущего месяца
		, add_kol DECIMAL(10, 2) DEFAULT 0
		, paymaccount1 DECIMAL(10, 2) DEFAULT 0 --  тек.месяца
		, paymaccount_prev DECIMAL(10, 2) DEFAULT 0 --  предыдущего месяца
		, add_paymaccount DECIMAL(10, 2) DEFAULT 0
	)

	--  если задан дом то анализируем лицевые счета по услугам
	IF @build_id IS NOT NULL
	BEGIN
		WITH cte AS
		(
			SELECT p1.fin_id
				 , CASE
                       WHEN p1.sup_id > 0 THEN p1.occ_sup_paym
                       ELSE p1.occ
                END AS occ
				 , p1.service_id
				 , B.street_name
				 , B.nom_dom
				 , f.nom_kvr
				 , CONCAT(B.adres , ' кв.' , f.nom_kvr) AS [address]
				 , p1.Value
				 , LAG(p1.Value, 1) OVER (PARTITION BY p1.occ, p1.service_id, p1.sup_id ORDER BY p1.fin_id) AS value_prev -- получить предыдущее значение
				 , p1.Paid
				 , LAG(p1.Paid, 1) OVER (PARTITION BY p1.occ, p1.service_id, p1.sup_id, p1.sup_id ORDER BY p1.fin_id) AS paid_prev
				 , COALESCE(p1.kol, 0) AS kol1
				 , LAG(p1.kol, 1) OVER (PARTITION BY p1.occ, p1.service_id, p1.sup_id ORDER BY p1.fin_id) AS kol_prev
				 , p1.PaymAccount
				 , LAG(p1.PaymAccount, 1) OVER (PARTITION BY p1.occ, p1.service_id, p1.sup_id ORDER BY p1.fin_id) AS paymaccount_prev
			FROM dbo.View_paym p1 
				JOIN dbo.Occupations o  ON p1.occ = o.occ
				JOIN dbo.Flats f ON o.flat_id = f.id
				JOIN dbo.View_buildings AS B ON p1.build_id = B.id
			WHERE p1.fin_id BETWEEN @fin_prev AND @fin_current
				AND (p1.service_id = @service_id OR @service_id IS NULL)
				AND o.tip_id = @tip_id
				AND p1.build_id = @build_id
				AND o.status_id <> 'закр'
				AND (B.div_id = @div_id OR @div_id IS NULL)
		)
		INSERT INTO @t
			(fin_id
		   , id
		   , service_id
		   , street_name
		   , nom_dom
		   , nom_kvr
		   , [address]
		   , value1
		   , value_prev
		   , paid1
		   , paid_prev
		   , kol1
		   , kol_prev
		   , paymaccount1
		   , paymaccount_prev)
		SELECT *
		FROM cte
		WHERE fin_id = @fin_current
	END
	ELSE --  если дом не задан то анализируем итоги по домам
	BEGIN
		WITH cte AS
		(
			SELECT t.fin_id
				 , t.build_id
				 , t.service_id
				 , B.street_name
				 , B.nom_dom
				 , B.adres
				 , T.Value
				 , LAG(t.Value, 1) OVER (PARTITION BY t.service_id, t.sup_id, t.build_id ORDER BY t.fin_id) AS value_prev
				 , T.Paid
				 , LAG(t.Paid, 1) OVER (PARTITION BY t.service_id, t.sup_id, t.build_id ORDER BY t.fin_id) AS paid_prev
				 , T.kol
				 , LAG(t.kol, 1) OVER (PARTITION BY t.service_id, t.sup_id, t.build_id ORDER BY t.fin_id) AS kol_prev
				 , T.PaymAccount
				 , LAG(t.PaymAccount, 1) OVER (PARTITION BY t.service_id, t.sup_id, t.build_id ORDER BY t.fin_id) AS paymaccount_prev
			FROM (
				SELECT p1.fin_id
					 , p1.build_id
					 , p1.service_id
					 , p1.sup_id
					 , SUM(COALESCE(p1.Value, 0)) AS Value
					 , SUM(COALESCE(p1.Paid, 0)) AS Paid
					 , SUM(COALESCE(p1.kol, 0)) AS kol
					 , SUM(COALESCE(p1.PaymAccount, 0)) AS PaymAccount
				FROM dbo.View_paym p1 
					JOIN dbo.View_occ_all o ON p1.fin_id = o.fin_id
						AND p1.occ = o.occ
				WHERE p1.fin_id BETWEEN @fin_prev AND @fin_current
					AND (p1.service_id = @service_id OR @service_id IS NULL)
					AND o.tip_id = @tip_id
					AND o.status_id <> 'закр'
				GROUP BY p1.fin_id
					   , p1.build_id
					   , p1.service_id
					   , p1.sup_id
			) AS t
				JOIN dbo.View_buildings AS B ON t.build_id = B.id
			WHERE (B.div_id = @div_id OR @div_id IS NULL)

		)
		INSERT INTO @t
			(fin_id
		   , id
		   , service_id
		   , street_name
		   , nom_dom
		   , [address]
		   , value1
		   , value_prev
		   , paid1
		   , paid_prev
		   , kol1
		   , kol_prev
		   , paymaccount1
		   , paymaccount_prev)
		SELECT *
		FROM cte
		WHERE fin_id = @fin_current
	END


	UPDATE @t
	SET add_value =
				   CASE
					   WHEN value1 = 0 AND
						   value_prev = 0 THEN 0
					   WHEN value1 = 0 AND
						   value_prev <> 0 THEN -100
					   WHEN value1 <> 0 AND
						   value_prev = 0 THEN 100
					   WHEN value1 = value_prev THEN 0
					   --ELSE (value1 * 100 / value_prev) - 100
					   ELSE ROUND((value1 - value_prev) / ABS(value_prev) * 100.0, 2)
				   END
	  , add_paid =
				  CASE
					  WHEN paid1 = 0 AND
						  paid_prev = 0 THEN 0
					  WHEN paid1 = 0 AND
						  paid_prev <> 0 THEN -100
					  WHEN paid1 <> 0 AND
						  paid_prev = 0 THEN 100
					  WHEN paid1 = paid_prev THEN 0
					  --ELSE (paid1 * 100 / paid_prev) - 100
					  ELSE ROUND((paid1 - paid_prev) / ABS(paid_prev) * 100.0, 2)
				  END
	  , add_kol =
				 CASE
					 WHEN kol1 = 0 AND
						 kol_prev = 0 THEN 0
					 WHEN kol1 = 0 AND
						 kol_prev <> 0 THEN -100
					 WHEN kol1 <> 0 AND
						 kol_prev = 0 THEN 100
					 WHEN kol1 = kol_prev THEN 0
					 --ELSE (kol1 * 100 / kol_prev) - 100
					 ELSE ROUND((kol1 - kol_prev) / ABS(kol_prev) * 100.0, 2)
				 END
	  , add_paymaccount =
						 CASE
							 WHEN paymaccount1 = 0 AND
								 paymaccount_prev = 0 THEN 0
							 WHEN paymaccount1 = 0 AND
								 paymaccount_prev <> 0 THEN -100
							 WHEN paymaccount1 <> 0 AND
								 paymaccount_prev = 0 THEN 100
							 WHEN paymaccount1 = paymaccount_prev THEN 0
							 --ELSE (paymaccount1 * 100 / paymaccount_prev) - 100
							 ELSE ROUND(100.0 * (paymaccount1 - paymaccount_prev) / ABS(paymaccount_prev), 2)
						 END

	SELECT S.name AS service_name
		 , t.*
	FROM @t AS t
		JOIN dbo.Services AS S ON t.service_id = S.id
	WHERE t.fin_id = @fin_current
		AND (ABS(add_value) > @step OR ABS(add_paid) > @step)
	ORDER BY s.name
		   , street_name
		   , dbo.Fun_SortDom(nom_dom)
		   , dbo.Fun_SortDom(nom_kvr)
END
go

