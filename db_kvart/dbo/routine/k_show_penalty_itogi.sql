CREATE   PROCEDURE [dbo].[k_show_penalty_itogi]
(
	  @occ1 INT
)
AS
/*
	Просмотр пени 

	exec k_show_penalty_itogi 265012
*/
	SET NOCOUNT ON

	SELECT ph.occ
		 , ph.fin_id
		 , ph.StrMes AS StrMes
		 , ph.dolg AS dolg
		 , ph.dolg_peny AS dolg_peny
		 , ph.paid_pred AS paid_pred
		 , ph.paymaccount AS paymaccount
		 , peny_old AS peny_old
		 , ph.paymaccount_peny AS paymaccount_peny
		 , ph.peny_old_new AS peny_old_new
		 , ph.penalty_added AS penalty_added
		 , ph.kolday AS kolday
		 , ph.PenyProc AS PenyProc
		 , ph.penalty_value AS Penalty_value
		 , ph.penalty_value + ph.penalty_added AS penalty_period
		 , ph.debt_peny AS debt_peny
		 , pm.name AS metod
		 , ot.PaymClosedData
		 , ph.data_rascheta
		 , ph.StavkaCB
		 , ph.penalty_calc
	FROM dbo.View_peny_all AS ph 
		JOIN dbo.View_occ_all_lite AS o ON ph.fin_id = o.fin_id AND ph.occ = o.occ
		JOIN dbo.VOcc_types_all AS ot ON o.tip_id = ot.Id AND ot.fin_id=ph.fin_id		
		LEFT JOIN dbo.Peny_metod pm ON ph.metod = pm.Id
	WHERE ph.occ = @occ1
		AND (ph.dolg <> 0 OR ph.dolg_peny <> 0 OR ph.peny_old <> 0 OR ph.debt_peny <> 0)
	ORDER BY ph.fin_id DESC
go

