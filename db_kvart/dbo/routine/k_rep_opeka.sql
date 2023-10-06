CREATE   PROCEDURE [dbo].[k_rep_opeka]
(
	@occ1   INT
   ,@sup_id INT = NULL  -- null -все 0-ед.лицевой, больше 0 - по поставщику
)
AS
/*
Для отчета "Справкав ПВС"
	
exec k_rep_opeka 910000934
exec k_rep_opeka 680000001,0
exec k_rep_opeka 680000001,323
	
*/
	SET NOCOUNT ON

	SELECT
		t.*
	   ,CASE
			WHEN (t.SALDO + t.Penalty_old_new) <= 0 THEN 0
			ELSE (t.SALDO + t.Penalty_old_new)
		END AS Dolg
	   ,CASE
			WHEN (t.SALDO + t.Penalty_old_new) < 0 THEN '0 руб.'
			ELSE dbo.Fun_RubPhrase(t.SALDO + Penalty_old_new)
		END AS SumStr
	FROM (SELECT CASE
                     WHEN @sup_id > 0 THEN os1.occ_sup
                     ELSE dbo.Fun_GetFalseOccOut(o.OCC, o.tip_id)
                     END AS OCC
		   ,o.address AS 'Adres'
		   ,CASE
					WHEN ot.synonym_name <> '' THEN ot.synonym_name
					ELSE ot.name
			END AS UKName
		   ,CASE
					WHEN o.PROPTYPE_ID = 'прив' THEN 'приватизированное'
					WHEN o.PROPTYPE_ID = 'купл' THEN 'купленное'
					WHEN o.PROPTYPE_ID = 'непр' THEN 'не приватизированное'
			END AS PROPTYPE
		   ,o.PROPTYPE_ID
		   ,gb.start_date
		   ,CASE
				WHEN @sup_id = 0 THEN o.saldo
				WHEN @sup_id > 0 THEN os1.saldo
				ELSE o.SaldoAll
			END AS saldo
		   ,CASE
				WHEN @sup_id = 0 THEN o.Penalty_old_new
				WHEN @sup_id > 0 THEN os1.Penalty_old_new
				ELSE o.Penalty_old_new + COALESCE(os1.Penalty_old_new, 0)
			END AS Penalty_old_new
		FROM dbo.OCCUPATIONS AS o
		JOIN dbo.OCCUPATION_TYPES AS ot 
			ON o.tip_id = ot.id
		JOIN dbo.GLOBAL_VALUES AS gb 
			ON o.fin_id = gb.fin_id
		OUTER APPLY (SELECT os.occ_sup AS occ_sup
			   ,SUM(os.saldo) AS saldo
			   ,SUM(os.Penalty_old_new) AS Penalty_old_new
			FROM dbo.OCC_SUPPLIERS AS os 
			WHERE os.Occ = o.Occ
			AND os.fin_id = o.fin_id
			AND (os.sup_id = @sup_id
			OR @sup_id IS NULL)
			GROUP BY os.occ_sup
			) AS os1
		WHERE o.Occ = @occ1) AS t
go

