CREATE   PROCEDURE [dbo].[rep_10_sup]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @div_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @PrintGroup SMALLINT = NULL
	, @town_id SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
)
AS
	/*
	
	WEB
	
	ОБОРОТНАЯ ВЕДОМОСТЬ по лицевым счетам поставщиков
	
	SET STATISTICS IO ON
	exec rep_10_sup @fin_id1=238,@tip_id=1, @sup_id=345, @fin_id2=239
	exec rep_10_sup @fin_id1=-1,@tip_id=1, @sup_id=345
	exec rep_10_sup @fin_id1=NULL,@tip_id=1, @sup_id=345
	
	*/

	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 < 0
		SELECT @fin_id1 = @fin_current
			 , @fin_id2 = @fin_current
	ELSE
	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current - 1

	IF @fin_id2 IS NULL
		OR @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1

	SELECT ROW_NUMBER() OVER (ORDER BY oh.fin_id, b.street_name, b.nom_dom_sort, oh.nom_kvr_sort) AS row_num
		 , oh.bldn_id
		 , oh.start_date
		 , oh.start_date AS 'Период'
		 , oh.tip_name
		 , b.street_name AS streets
		 , b.nom_dom AS nom_dom
		 , oh.nom_kvr AS nom_kvr
		 , '' AS Lgota --,dbo.Fun_LgotaStr(os.occ)
		 , dbo.Fun_GetKolPeopleOccStatus(os.Occ) AS KolPeople
		 , oh.proptype_id AS proptype
		 , oh.STATUS_ID AS STATUS_ID
		 , dbo.Fun_PersonStatusStr(os.Occ) AS person_status
		 , oh.total_sq
		 , os.occ
		 , os.occ_sup AS occ_sup
		 , b.sector_id AS JEU
		 , os.saldo
		 , (os.saldo + os.Penalty_old + os.PaymAccount_peny) AS  saldo_with_penalty
		 , os.value
		 , os.added
		 , os.PaymAccount
		 , os.Paid AS paid
		 , (os.Paid + os.Penalty_value + os.Penalty_added) AS PaidWithPenalty-- начислено с пени
		 , os.Debt + os.debt_peny AS Whole_payment
		 , os.Penalty_value AS Penalty_value
		 , os.Penalty_added
		 , os.Penalty_old
		 , os.Penalty_old_new
		 , os.debt_peny AS penalty_itog -- итого пени
		 , os.PaymAccount_peny
		 , (os.PaymAccount - os.PaymAccount_peny) AS Paymaccount_Serv
		 , os.Debt
		 , os.Debt + os.debt_peny AS SumPaymDebt
		 , b.div_id
		 , b.div_name AS div_name
		 , b.tip_id
		 , dbo.Fun_Initials(os.Occ) AS Initials
		 , dbo.Fun_GetDatePaymStr(os.Occ, os.fin_id, os.sup_id) AS DatePaym
		 , SA.name AS sup_name
		 , b.town_name AS town_name
	FROM dbo.VOcc_Suppliers AS os 
		JOIN dbo.Suppliers_all AS SA ON 
			os.sup_id = SA.id
		JOIN dbo.View_occ_all AS oh ON 
			os.Occ = oh.Occ
			AND os.fin_id = oh.fin_id
		JOIN dbo.View_build_all AS b ON 
			oh.bldn_id = b.bldn_id
			AND oh.fin_id = b.fin_id
	WHERE (os.sup_id = @sup_id)
		AND oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND oh.STATUS_ID <> 'закр'
		AND (oh.tip_id = @tip_id OR @tip_id IS NULL)
		AND (b.div_id = @div_id OR @div_id IS NULL)
		AND (oh.bldn_id = @build_id OR @build_id IS NULL)
		AND (b.town_id = @town_id OR @town_id IS NULL)
		AND (@PrintGroup IS NULL OR EXISTS (
			SELECT 1
			FROM dbo.Print_occ AS po 
			WHERE po.Occ = oh.Occ
				AND po.group_id = @PrintGroup
		))
	ORDER BY oh.fin_id
		   , b.street_name
		   , b.nom_dom_sort
		   , oh.nom_kvr_sort

	OPTION (MAXDOP 1, FAST 10)
go

