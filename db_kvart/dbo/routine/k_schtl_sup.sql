CREATE   PROCEDURE [dbo].[k_schtl_sup]
(
	  @occ INT
	, @sup_id INT
	, @fin_id SMALLINT = NULL
)
AS
	/*
		выдаём лицевой счет поставщика
	*/
	SET NOCOUNT ON

	IF @fin_id IS NULL
		OR @fin_id = 0
		SELECT @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	SELECT 
		os.[fin_id]
		, os.[occ]
		, os.[sup_id]
		, os.[occ_sup]
		, os.[saldo]
		, os.[value]
		, os.[added]
		, os.[paid]
		, os.[paymaccount]
		, os.[paymaccount_peny]
		, os.[penalty_calc]
		, os.[penalty_old_edit]
		, os.[penalty_old]
		, os.[penalty_old_new]
		, os.[penalty_added]
		, os.[penalty_value]
		, os.[kolmesdolg]
		, os.[debt]
		, os.[paid_old]
		, os.[dog_int]
		, os.[cessia_dolg_mes_old]
		, os.[cessia_dolg_mes_new]
		, os.[whole_payment]
		, os.[whole_payment_minus]
		, os.[paymaccount_serv]
		, os.[id_jku_gis]
		, os.[rasschet]
		, os.[occ_sup_uid]
		, os.[schtl_old]
		, os.[debt_peny]
		, os.[paymaccount_storno]
		 , (os.penalty_old_new + os.penalty_added + os.penalty_value) AS peny_itog
		 , (os.penalty_value + os.penalty_added) AS penalty_period
	FROM dbo.VOcc_Suppliers AS os
	WHERE os.occ = @occ
		AND os.sup_id = @sup_id
		AND os.fin_id = @fin_id
go

