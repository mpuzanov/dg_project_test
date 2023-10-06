-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_suppliers_occ]
(
	  @fin_id SMALLINT = NULL
	, @occ INT
)
AS
/*
exec k_suppliers_occ @occ=276158
exec k_suppliers_occ @occ=700072141
exec k_suppliers_occ @occ=680001155
exec k_suppliers_occ @occ=680000035
exec k_suppliers_occ null,null
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @build_id INT
		  , @tip_id SMALLINT

	SELECT TOP (1) @build_id = v.bldn_id
				 , @tip_id = v.tip_id
	FROM VOcc v
	WHERE v.occ = @occ
	;
	WITH cte_sup AS
	(
		SELECT DISTINCT os.sup_id
					  , @occ AS occ
					  , os.occ_sup
		FROM dbo.Occ_Suppliers AS os 
		WHERE os.occ = @occ
	)
	SELECT sup.id
		 , sup.name
		 , sup.id_accounts
		 , ra.FileName AS filename_accounts
		 , sup.bank_account
		 , CASE
			   WHEN sb.is_peny = 'N' THEN 0
			   WHEN sb.is_peny = 'Y' THEN 1
			   WHEN st.is_peny = 'N' THEN 0
			   WHEN st.is_peny = 'Y' THEN 1
			   ELSE COALESCE(sup.penalty_calc, 0)
		   END AS penalty_calc
		 , sup.account_one
		 , CASE
			   WHEN sb.lastday_without_peny > 0 THEN sb.lastday_without_peny
			   WHEN st.lastday_without_peny > 0 THEN st.lastday_without_peny
			   ELSE sup.LastPaym
		   END AS LastPaym
		 , CASE
			   WHEN (sb.build_id IS NOT NULL AND sb.is_peny = 'Y') THEN (
					   SELECT TOP 1 name
					   FROM Peny_metod pm
					   WHERE pm.id = sb.penalty_metod
				   )
			   WHEN (st.tip_id IS NOT NULL AND st.is_peny = 'Y') THEN (
					   SELECT TOP 1 name
					   FROM Peny_metod pm
					   WHERE pm.id = st.penalty_metod
				   )
			   ELSE COALESCE(pm.name, '-')
		   END AS penalty_metod
		 , occ_sup
	FROM cte_sup AS os 
		JOIN dbo.Occupations o ON os.occ = o.occ
		JOIN dbo.Flats f ON o.flat_id = f.id
		JOIN dbo.View_suppliers_all AS sup ON os.sup_id = sup.id
		LEFT JOIN dbo.Reports_account AS ra ON sup.id_accounts = ra.id
		LEFT JOIN (
			SELECT *
			FROM (
				SELECT tt.*
					 , DENSE_RANK() OVER (PARTITION BY tt.sup_id ORDER BY tt.service_id) AS toprank
				FROM dbo.Suppliers_types tt 
				WHERE tt.tip_id = @tip_id
			) AS t
			WHERE t.toprank = 1
		) AS st ON os.sup_id = st.sup_id
		LEFT JOIN (
			SELECT *
			FROM (
				SELECT tt.*
					 , DENSE_RANK() OVER (PARTITION BY tt.sup_id ORDER BY tt.service_id) AS toprank
				FROM dbo.Suppliers_build tt
				WHERE tt.build_id = @build_id
			) AS t
			WHERE t.toprank = 1
		) AS sb ON os.sup_id = sb.sup_id

		LEFT JOIN dbo.Peny_metod pm  ON sup.penalty_metod = pm.id
	--WHERE os.Occ = @occ
	ORDER BY sup.name --desc


END
go

