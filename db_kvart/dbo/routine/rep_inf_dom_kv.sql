CREATE   PROCEDURE [dbo].[rep_inf_dom_kv]
(
	@fin_id1		SMALLINT	= NULL
	,@tip_id1		SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@build1		INT			= NULL
	,@proptype_id1	VARCHAR(10)	= NULL
)
AS
	--
	-- Показываем список лицевых в заданном доме
	--
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, @build1, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	SELECT
		b.div_id AS ID
		,o.jeu
		,o.occ
		,b.street_name AS name
		,b.nom_dom
		,o.nom_kvr
		,o.proptype_id
		,b.div_name AS 'div_name'
	FROM dbo.View_OCC_ALL AS o 
	JOIN dbo.View_BUILD_ALL AS b 
		ON o.bldn_id = b.bldn_id
	WHERE b.bldn_id = COALESCE(@build1, b.bldn_id)
	AND b.div_id = COALESCE(@div_id1, b.div_id)
	AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
	AND o.status_id <> 'закр'
	AND o.proptype_id = COALESCE(@proptype_id1, o.proptype_id)  -- отбор по типу квартиры
	AND o.fin_id = @fin_id1
	AND b.fin_id = o.fin_id
	ORDER BY b.street_name, b.nom_dom_sort, o.nom_kvr_sort
go

