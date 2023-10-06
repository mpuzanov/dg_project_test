-- =============================================
-- Author:		Пузанов Михаил
-- Create date: 10.01.2013
-- Description:	Для проверки расчётов (сравнение текущих и предыдущих начислений)
-- =============================================
CREATE     PROCEDURE [dbo].[rep_proverka_value]
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
exec rep_proverka_value @tip_id=28, @service_id='анте', @fin_current=203
exec rep_proverka_value @tip_id=28, @service_id='анте', @fin_current=201
exec rep_proverka_value @tip_id=4, @build_id=6795
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

	SET @fin_prev -= @fin_current

	DECLARE @t TABLE (
		  id INT
		, service_id VARCHAR(10)
		, street_name VARCHAR(50) DEFAULT ''
		, nom_dom VARCHAR(12) DEFAULT ''
		, nom_kvr VARCHAR(20) DEFAULT ''
		, [address] VARCHAR(100) DEFAULT ''
		, value1 DECIMAL(10, 2) DEFAULT 0 -- начисление тек.месяца
		, value2 DECIMAL(10, 2) DEFAULT 0 -- начисление предыдущего месяца
		, add_value DECIMAL(10, 2) DEFAULT 0
		, paid1 DECIMAL(10, 2) DEFAULT 0 -- тек.месяца
		, paid2 DECIMAL(10, 2) DEFAULT 0 -- предыдущего месяца
		, add_paid DECIMAL(10, 2) DEFAULT 0
		, kol1 DECIMAL(12, 4) DEFAULT 0 --  тек.месяца
		, kol2 DECIMAL(12, 4) DEFAULT 0 --  предыдущего месяца
		, add_kol DECIMAL(10, 2) DEFAULT 0
		, paymaccount1 DECIMAL(10, 2) DEFAULT 0 --  тек.месяца
		, paymaccount2 DECIMAL(10, 2) DEFAULT 0 --  предыдущего месяца
		, add_paymaccount DECIMAL(10, 2) DEFAULT 0
	)

	--  если задан дом то анализируем лицевые счета
	IF @build_id IS NOT NULL
		INSERT INTO @t (id
					  , service_id
					  , street_name
					  , nom_dom
					  , nom_kvr
					  , [address]
					  , value1
					  , value2
					  , paid1
					  , paid2
					  , kol1
					  , kol2
					  , paymaccount1
					  , paymaccount2)
		SELECT CASE
                   WHEN p1.sup_id > 0 THEN MIN(p1.occ_sup_paym)
                   ELSE p1.occ
            END AS occ
			 , p1.service_id
			 , MAX(B.street_name)
			 , MAX(B.nom_dom)
			 , MAX(voa.nom_kvr)
			 , MAX(CONCAT(B.adres , ' кв.' , voa.nom_kvr))		     
			 , SUM(COALESCE(p1.Value, 0))
			 , SUM(COALESCE(p2.Value, 0))
			 , SUM(COALESCE(p1.Paid, 0))
			 , SUM(COALESCE(p2.Paid, 0))
			 , SUM(COALESCE(p1.kol, 0))
			 , SUM(COALESCE(p2.kol, 0))
			 , SUM(COALESCE(p1.PaymAccount, 0))
			 , SUM(COALESCE(p2.PaymAccount, 0))
		FROM dbo.View_paym p1 
			JOIN dbo.View_occ_all voa ON p1.fin_id = voa.fin_id
				AND p1.occ = voa.occ
			JOIN dbo.View_paym p2 ON p2.occ = p1.occ
				AND p2.service_id = p1.service_id
				AND p2.sup_id = p1.sup_id
			JOIN dbo.View_buildings AS B ON voa.bldn_id = B.id
		WHERE p1.fin_id = @fin_current
			AND (p1.service_id = @service_id OR @service_id IS NULL)
			AND voa.tip_id = @tip_id
			AND p2.fin_id = @fin_prev
			AND voa.bldn_id = @build_id
			AND voa.status_id <> 'закр'
			AND (B.div_id = @div_id OR @div_id IS NULL)
		GROUP BY B.id
			   , p1.occ
			   , p1.service_id
			   , p1.sup_id

	ELSE --  если дом не задан то анализируем дома
		INSERT INTO @t (id
					  , service_id
					  , street_name
					  , nom_dom
					  , [address]
					  , value1
					  , value2
					  , paid1
					  , paid2
					  , kol1
					  , kol2
					  , paymaccount1
					  , paymaccount2)
		SELECT voa.bldn_id
			 , p1.service_id
			 , MAX(B.street_name)
			 , MAX(B.nom_dom)
			 , MAX(B.adres)
			 , SUM(COALESCE(p1.Value, 0))
			 , SUM(COALESCE(p2.Value, 0))
			 , SUM(COALESCE(p1.Paid, 0))
			 , SUM(COALESCE(p2.Paid, 0))
			 , SUM(COALESCE(p1.kol, 0))
			 , SUM(COALESCE(p2.kol, 0))
			 , SUM(COALESCE(p1.PaymAccount, 0))
			 , SUM(COALESCE(p2.PaymAccount, 0))
		FROM dbo.View_paym p1 
			JOIN dbo.View_occ_all voa ON p1.fin_id = voa.fin_id
				AND p1.Occ = voa.Occ
			JOIN dbo.View_paym p2 ON p2.Occ = p1.Occ
				AND p2.service_id = p1.service_id
				AND p2.sup_id = p1.sup_id
			JOIN dbo.View_buildings AS B ON voa.bldn_id = B.id
		WHERE p1.fin_id = @fin_current
			AND (p1.service_id = @service_id OR @service_id IS NULL)
			AND voa.tip_id = @tip_id
			AND voa.status_id <> 'закр'
			AND p2.fin_id = @fin_prev
			AND (B.div_id = @div_id OR @div_id IS NULL)
		GROUP BY voa.bldn_id
			   , p1.service_id
			   , p1.sup_id

	UPDATE @t
	SET add_value =
				   CASE
					   WHEN value1 = 0 AND
						   value2 = 0 THEN 0
					   WHEN value1 = 0 AND
						   value2 <> 0 THEN -100
					   WHEN value1 <> 0 AND
						   value2 = 0 THEN 100
					   WHEN value1 = value2 THEN 0
					   ELSE (value1 * 100 / value2) - 100
				   END
	  , add_paid =
				  CASE
					  WHEN paid1 = 0 AND
						  paid2 = 0 THEN 0
					  WHEN paid1 = 0 AND
						  paid2 <> 0 THEN -100
					  WHEN paid1 <> 0 AND
						  paid2 = 0 THEN 100
					  WHEN paid1 = paid2 THEN 0
					  ELSE (paid1 * 100 / paid2) - 100
				  END
	  , add_kol =
				 CASE
					 WHEN kol1 = 0 AND
						 kol2 = 0 THEN 0
					 WHEN kol1 = 0 AND
						 kol2 <> 0 THEN -100
					 WHEN kol1 <> 0 AND
						 kol2 = 0 THEN 100
					 WHEN kol1 = kol2 THEN 0
					 ELSE (kol1 * 100 / kol2) - 100
				 END
	  , add_paymaccount =
						 CASE
							 WHEN paymaccount1 = 0 AND
								 paymaccount2 = 0 THEN 0
							 WHEN paymaccount1 = 0 AND
								 paymaccount2 <> 0 THEN -100
							 WHEN paymaccount1 <> 0 AND
								 paymaccount2 = 0 THEN 100
							 WHEN paymaccount1 = paymaccount2 THEN 0
							 ELSE (paymaccount1 * 100 / paymaccount2) - 100
						 END

	SELECT service_id = S.name
		 , t.*
	FROM @t AS t
		JOIN dbo.Services AS S 
			ON t.service_id = S.id
	WHERE ABS(add_value) > @step
		OR ABS(add_paid) > @step
	ORDER BY s.name
		   , street_name
		   , dbo.Fun_SortDom(nom_dom)
		   , dbo.Fun_SortDom(nom_kvr)
END
go

