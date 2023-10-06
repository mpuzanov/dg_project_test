CREATE   PROCEDURE [dbo].[rep_10] --WEB-- Оборотная ведомость по лицевым счетам 
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT
	, @div_id SMALLINT = NULL
	, @jeu_id SMALLINT = NULL
	, @build_id INT = NULL
	, @PrintGroup SMALLINT = NULL
	, @town_id SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
)
/*

ОБОРОТНАЯ ВЕДОМОСТЬ по лицевым счетам
rep10.fr3

SET STATISTICS IO ON
exec rep_10 @fin_id=251, @tip_id=1, @fin_id2=251
exec rep_10 @fin_id=232, @tip_id=1, @fin_id2=232
exec rep_10 @fin_id=-1, @tip_id=1, @fin_id2=232
exec rep_10 @fin_id=null, @tip_id=1

*/
AS
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id < 0
		SELECT @fin_id = @fin_current
			 , @fin_id2 = @fin_current
	ELSE
	IF @fin_id IS NULL
		SET @fin_id = @fin_current - 1

	IF @fin_id2 IS NULL
		OR @fin_id2 < @fin_id
		SET @fin_id2 = @fin_id

	SELECT oh.bldn_id
		 , oh.[start_date]
		 , b.town_name
		 , oh.tip_name
		 , b.street_name AS streets
		 , b.nom_dom AS nom_dom
		 , oh.nom_kvr AS nom_kvr
		 , oh.[floor] AS [floor]
		 , '' AS lgota
		 , oh.kol_people AS KolPeople --dbo.Fun_GetKolPeopleOccStatus(oh.occ) AS KolPeople,
		 , oh.proptype_id AS proptype
		 , oh.roomtype_id AS roomtype_id
		 , oh.status_id AS status_id
		 , dbo.Fun_PersonStatusStr(oh.occ) AS person_status
		 , oh.total_sq
		 , oh.occ
		 , b.sector_id AS jeu
		 , NULL AS schtl
		 , (oh.saldo - oh.Paymaccount_Serv) AS dolg -- задолженность
		 , oh.saldo AS saldo
		 , (oh.saldo + oh.penalty_old + oh.PaymAccount_peny) AS saldo_with_penalty
		 , oh.value AS value
		 , (oh.added - COALESCE(ap.val, 0)) AS added		 
		 , COALESCE(ap.val, 0) AS compens
		 , oh.discount AS discount
		 , oh.PaymAccount
		 , oh.paid + oh.Paid_minus AS paid
		 , (oh.paid + oh.Paid_minus + oh.penalty_value + oh.penalty_added) AS paid_with_penalty
		 , oh.SumPaymDebt AS whole_payment  --oh.Whole_payment  11.01.21
		 , oh.penalty_old AS penalty_old-- пред. месяц
		 , oh.penalty_old_new AS penalty_old_new -- изменённый с учётом оплаты
		 , oh.penalty_added AS penalty_added
		 , oh.penalty_value AS penalty_value -- начисленное в этом месяце
		 , oh.penalty_itog AS penalty_itog -- итого пени
		 , oh.PaymAccount_peny
		 , oh.Paymaccount_Serv
		 , oh.debt AS debt
		 , oh.SumPaymDebt AS SumPaymDebt -- к оплате (может быть отрицательной)
		 , b.div_id
		 , b.div_name AS div_name
		 , b2.index_id
		 , b2.index_postal
		 , b.tip_id
		 , dbo.Fun_Initials(oh.occ) AS Initials
		 , dbo.Fun_GetDatePaymStr(oh.occ, oh.fin_id, NULL) AS DatePaym
		 , o.id_els_gis
		 , oh.id_nom_gis AS id_nom_gis
		 , o.id_jku_gis
	FROM dbo.View_occ_all_lite AS oh 
		JOIN dbo.View_build_all AS b ON oh.bldn_id = b.bldn_id And b.fin_id=oh.fin_id
		JOIN dbo.Buildings AS b2 ON b2.ID = b.bldn_id
		JOIN dbo.Occupations o ON oh.occ = o.occ
		JOIN dbo.VOcc_types AS ot ON oh.tip_id = ot.id
		OUTER APPLY (
			SELECT SUM(va.value) AS val
			FROM dbo.View_added va
			WHERE va.fin_id = oh.fin_id
				AND va.occ = oh.occ
				AND va.add_type = 15
		) AS ap
	WHERE oh.fin_id BETWEEN @fin_id AND @fin_id2
		AND oh.status_id <> 'закр'
		--AND b.fin_id = @fin_id
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@div_id IS NULL OR b.div_id = @div_id)
		AND (@jeu_id IS NULL OR b.sector_id = @jeu_id)
		AND (@build_id IS NULL OR b.build_id = @build_id)
		AND (@town_id IS NULL OR @town_id IS NULL)
		AND (@PrintGroup IS NULL OR EXISTS (
			SELECT 1
			FROM dbo.Print_occ AS po 
			WHERE po.occ = oh.occ
				AND po.group_id = @PrintGroup
		))
	ORDER BY oh.fin_id
		   , b.street_name
		   , b.nom_dom_sort
		   , oh.nom_kvr_sort
	OPTION (RECOMPILE)
go

