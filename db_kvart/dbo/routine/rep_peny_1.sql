CREATE   PROCEDURE [dbo].[rep_peny_1]
(
	  @fin_id1 SMALLINT
	, @tip SMALLINT = NULL
	, @sector_id1 SMALLINT = NULL
	, @div_id SMALLINT = NULL
	, @build INT = NULL
)
AS
	/*
		--
		-- Список лицевых с пенями
		-- 
		-- отчет: peny1.fr3
		--
	
		rep_peny_1 177,28
	
	*/
	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip, @build, NULL, NULL)

	SELECT s.name
		 , b.nom_dom AS nom_dom
		 , oh.nom_kvr
		 , b.nom_dom_sort
		 , oh.nom_kvr_sort
		 , oh.Occ
		 , o.address
		 , oh.Penalty_calc
		 , oh.Penalty_old
		 , oh.PaymAccount_peny
		 , oh.Penalty_old_new
		 , oh.Penalty_value
		 , oh.Penalty_value + oh.Penalty_added + oh.Penalty_old_new AS itogo
		 , oh.Penalty_added AS penalty_add
	FROM dbo.View_occ_all AS oh 
		JOIN dbo.Occupations AS o ON oh.Occ = o.Occ
		JOIN dbo.Buildings AS b ON oh.bldn_id = b.id
		JOIN dbo.VStreets AS s ON b.street_id = s.id
	WHERE 
		oh.fin_id = @fin_id1
		AND (b.tip_id = @tip OR @tip IS NULL)
		AND (b.sector_id = @sector_id1 OR @sector_id1 IS NULL)
		AND (oh.bldn_id = @build OR @build IS NULL)
		AND (b.div_id = @div_id OR @div_id IS NULL)
		AND (oh.Penalty_value <> 0 OR oh.Penalty_old_new <> 0 OR oh.Penalty_added <> 0)
	UNION ALL
	SELECT s.name
		 , b.nom_dom AS nom_dom
		 , o.nom_kvr
		 , b.nom_dom_sort
		 , o.nom_kvr_sort
		 , oh.occ_sup
		 , o.address
		 , o.Penalty_calc
		 , oh.Penalty_old
		 , oh.PaymAccount_peny
		 , oh.Penalty_old_new
		 , oh.Penalty_value
		 , oh.Penalty_value + oh.Penalty_added + oh.Penalty_old_new AS itogo
		 , oh.Penalty_added AS penalty_add
	FROM dbo.Occ_Suppliers AS oh 
		JOIN dbo.VOcc AS o ON oh.Occ = o.Occ
		JOIN dbo.Buildings AS b ON o.build_id = b.id
		JOIN dbo.VStreets AS s ON b.street_id = s.id
	WHERE 
		oh.fin_id = @fin_id1
		AND (b.tip_id = @tip OR @tip IS NULL)
		AND (b.sector_id = @sector_id1 OR @sector_id1 IS NULL)
		AND (o.bldn_id = @build OR @build IS NULL)
		AND (b.div_id = @div_id OR @div_id IS NULL)
		AND (oh.Penalty_value <> 0 OR oh.Penalty_old_new <> 0 OR oh.Penalty_added <> 0)
	ORDER BY s.name
		   , nom_dom_sort
		   , nom_kvr_sort
	OPTION (RECOMPILE)
go

