CREATE   PROCEDURE [dbo].[rep_svod_jeu]
(
	@fin_id1	SMALLINT
	,@tip		SMALLINT	= 0
)
/*
 
 Выдаем сводный отчет по участкам на базе таблицы  DOM_SVOD
 rep_svod_jeu 180,28
*/
AS
	SET NOCOUNT ON


	SELECT
		t.name AS tip
		,b.sector_id AS jeu
		,CurrentDate
		,SUM(CountLic) as CountLic
		,SUM(CountLicLgot) AS CountLicLgot
		,SUM(CountLicSubsid) AS CountLicSubsid
		,SUM(CountPeople) as CountPeople
		,SUM(CountPeoplelgot) as CountPeoplelgot
		,SUM(SQUARE) as [SQUARE]
		,SUM(SquareLive) AS SquareLive
	FROM dbo.DOM_SVOD AS d 
	JOIN dbo.View_BUILD_ALL b
		ON d.build_id = b.bldn_id
		AND d.fin_id = b.fin_id
	JOIN dbo.OCCUPATION_TYPES AS t 
		ON b.tip_id = t.id
	WHERE d.fin_id = @fin_id1
	AND (b.tip_id = @tip
	OR @tip IS NULL)
	GROUP BY	t.name
				,b.sector_id
				,CurrentDate
	ORDER BY b.sector_id
go

