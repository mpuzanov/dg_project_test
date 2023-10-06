CREATE   PROCEDURE [dbo].[rep_10_itog]
(
	@fin_id		SMALLINT	= NULL
	,@tip_id	SMALLINT
	,@build		INT			= NULL
	,@town_id	SMALLINT	= NULL
)
/*

ОБОРОТНАЯ ВЕДОМОСТЬ по лицевым счетам вместе с поставщиками
rep10.fr3

SET STATISTICS IO ON
exec rep_10_itog 180, 28, 1031

*/
AS
	SET NOCOUNT ON


	IF @fin_id IS NULL
	begin
	-- находим значение текущего фин периода
		SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)
		SET @fin_id = @fin_id - 1
	end

	SELECT
		oh.bldn_id
		,oh.[start_date]
		,b.town_name AS town_name
		,b.street_name AS STREETS
		,b.nom_dom AS nom_dom
		,oh.nom_kvr AS nom_kvr
		,oh.TOTAL_SQ
		,oh.kol_people
		,dbo.Fun_Initials(oh.occ) AS Initials
		,oh.occ
		,[dbo].[Fun_GetOccSupStr](oh.occ, oh.fin_id,NULL) AS occ_sup_str
		,oh.SaldoAll
		,COALESCE(oh.AddedAll, 0) AS AddedAll
		,COALESCE(oh.Paymaccount_ServAll, 0) AS Paymaccount_ServAll
		,oh.PaidAll
		,oh.SaldoAll - COALESCE(oh.Paymaccount_ServAll, 0) + oh.PaidAll AS debtAll
		,I.KolMesDolgAll
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON oh.bldn_id = b.bldn_id
	JOIN dbo.INTPRINT I 
		ON oh.occ = I.occ
		AND I.fin_id = oh.fin_id
	WHERE oh.fin_id = @fin_id
		AND oh.STATUS_ID <> 'закр'
		AND b.fin_id = @fin_id
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@build IS NULL OR oh.bldn_id = @build)
		AND (@town_id IS NULL OR b.town_id = @town_id)
	ORDER BY b.street_name, b.nom_dom_sort, oh.nom_kvr_sort
go

