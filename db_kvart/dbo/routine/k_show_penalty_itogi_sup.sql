CREATE   PROCEDURE [dbo].[k_show_penalty_itogi_sup]
(
	  @occ1 INT
	, @sup_id INT = NULL
)
AS
/* 
Просмотр пени по поставщикам

exec k_show_penalty_itogi_sup 265012, 345

*/

	SET NOCOUNT ON

	-- Выбираем лицевые поставщика

	SELECT os.occ_sup AS occ
		 , ph.fin_id
		 , ph.strmes AS strmes
		 , ph.dolg AS dolg
		 , ph.dolg_peny AS dolg_peny
		 , ph.paid_pred AS paid_pred
		 , ph.paymaccount AS paymaccount
		 , ph.peny_old AS peny_old
		 , ph.Paymaccount_peny AS Paymaccount_peny
		 , ph.peny_old_new AS peny_old_new
		 , ph.penalty_added AS penalty_added
		 , ph.kolday AS kolday
		 , ph.PenyProc AS PenyProc		 
		 , ph.penalty_value AS Penalty_value
		 , ph.penalty_value + ph.penalty_added AS penalty_period
		 , ph.debt_peny AS debt_peny
		 , pm.name AS metod
		 , sa.name AS sup_name
		 , ph.data_rascheta
		 , ph.StavkaCB
		 , ph.penalty_calc
	FROM dbo.Occ_Suppliers AS os
		JOIN dbo.View_peny_all AS ph ON os.occ_sup = ph.occ
			AND os.fin_id = ph.fin_id
		JOIN dbo.Suppliers_all sa ON os.sup_id = sa.Id
		LEFT JOIN dbo.Peny_metod pm ON ph.metod = pm.Id
	WHERE os.occ = @occ1
		AND (@sup_id IS NULL OR os.sup_id = @sup_id)
		AND (ph.dolg <> 0 OR ph.dolg_peny <> 0 OR ph.peny_old <> 0 OR ph.debt_peny <> 0)
	ORDER BY os.fin_id DESC
go

