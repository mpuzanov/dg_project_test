CREATE   PROCEDURE [dbo].[rep_i]
(
	@build_id		INT			= NULL
	,@fin_id		SMALLINT	= NULL
	,@tip_id		SMALLINT	= NULL
	,@proptype_id	VARCHAR(10)	= NULL
)

AS

	--
	--  Информация по дому
	--  отчет: rep_i.fr3
	--
	/*dbo.rep_i
	
	дата последней модификации: 20.07.11
	автор изменений:  Пузанов
	
	rep_i @tip_id=28
	
	*/

	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	IF @fin_id IS NULL
		OR @fin_id = 0
		SET @fin_id = @fin_current;


	SELECT
		b.street_id AS street_id
		,b.street_name AS street_name
		,b.id AS build_id
		,b.nom_dom AS nom_dom
		,o.proptype_id
		,o.socnaim
		,COUNT(DISTINCT o.flat_id) AS kol_flat
		,COUNT(o.occ) AS kol_occ
		,SUM(o.kol_people) AS kol_people
		,SUM(o.Total_sq) AS Total_sq
	FROM dbo.View_OCC_ALL AS o 
	JOIN dbo.View_BUILDINGS AS b 
		ON o.build_id = b.id
	WHERE o.status_id <> 'закр'
	AND o.fin_id = @fin_id
	AND (b.id = @build_id OR @build_id IS NULL)
	AND (b.tip_id = @tip_id OR @tip_id IS NULL)
	AND o.proptype_id = COALESCE(@proptype_id, o.proptype_id)
	GROUP BY	b.street_id
				,b.street_name
				,b.id
		        ,b.nom_dom
				,o.proptype_id
				,o.socnaim
	ORDER BY b.street_name, MIN(b.nom_dom_sort)
go

