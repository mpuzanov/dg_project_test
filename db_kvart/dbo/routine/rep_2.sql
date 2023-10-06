CREATE   PROCEDURE [dbo].[rep_2]
(
	@fin_id			SMALLINT
	,@tip_id		SMALLINT
	,@jeu_id		SMALLINT	= NULL
	,@div_id		SMALLINT	= NULL
	,@service_id	VARCHAR(10)	= NULL
	,@build_id		SMALLINT	= NULL
	,@sup_id		INT			= NULL -- поставщик  
)

AS
/*

rep_2 172,28

*/
	SET NOCOUNT ON;


	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL) -- находим значение текущего фин периода

	IF @tip_id IS NULL AND @build_id IS NULL AND @div_id IS NULL
		SELECT
			@tip_id = 0
			,@build_id = 0

	SELECT
		s.short_name
		,vs.Name AS source_name
		,cm.Name AS mode_name
		,SUM(pl.VALUE) AS VALUE
		,SUM(pl.added) AS added
		,SUM(pl.discount) AS discount
		,SUM(pl.compens) AS compens
		,SUM(pl.paid) AS paid
		,SUM(pl.paymaccount) AS paymaccount
		,SUM(pl.paymaccount_peny) AS paymaccount_peny
		,SUM(pl.paymaccount - pl.paymaccount_peny) AS paymaccount_serv
		,SUM(pl.kol) AS kol
	FROM dbo.View_OCC_ALL_LITE AS o 
	JOIN dbo.View_BUILD_ALL AS b 
		ON o.bldn_id = b.bldn_id AND o.fin_id = b.fin_id		
	JOIN dbo.View_PAYM AS pl 
		ON o.fin_id = pl.fin_id AND o.occ = pl.occ 
	JOIN dbo.View_SERVICES AS s
		ON pl.service_id = s.id
	JOIN dbo.CONS_MODES AS cm 
		ON cm.id = pl.mode_id
	JOIN dbo.View_SUPPLIERS AS vs
		ON vs.service_id = s.id AND vs.id = pl.source_id
	WHERE 1=1
		AND o.fin_id = @fin_id
		AND (o.tip_id = @tip_id OR @tip_id IS NULL)
		AND (o.bldn_id = @build_id OR @build_id IS NULL)
		AND (b.sector_id = @jeu_id OR @jeu_id IS null)
		AND (b.div_id = @div_id OR @div_id IS NULL)
		AND (pl.service_id = @service_id OR @service_id IS NULL)
		AND pl.subsid_only = 0
		AND (vs.SUP_ID = @sup_id OR @sup_id IS NULL)
	GROUP BY	s.short_name
				,vs.Name
				,cm.Name
	ORDER BY s.short_name
	OPTION (RECOMPILE)
go

