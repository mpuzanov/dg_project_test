CREATE   PROCEDURE [dbo].[rep_people_list]
/*
   Информация по человеку, используется в различных отчетах
   rep_people_list 146303
*/
(
	@owner_id INT --код человека
)
AS
	SET NOCOUNT ON


	SELECT
		p.*
		,c.name AS grajd
		,b.street_name as name
		,b.nom_dom
		,b.nom_dom_without_korp AS nom_dom_without_korp
		,b.korp  AS korp
		,f.nom_kvr
		,gb.Region
		,gb.Town
		,CASE
				WHEN p.sex = 0 THEN 0
				WHEN p.sex = 1 THEN 1
				ELSE 3
			END AS SexPol
		,P2.*
		,ID.*
	FROM dbo.VPEOPLE AS p
	JOIN dbo.OCCUPATIONS AS o 
		ON p.occ = o.occ
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.ID
	JOIN dbo.View_BUILDINGS AS b 
		ON f.bldn_id = b.ID
	JOIN dbo.OCCUPATION_TYPES AS ot 
		ON b.tip_id = ot.ID
	JOIN dbo.GLOBAL_VALUES AS gb 
		ON b.fin_current = gb.fin_id
	LEFT OUTER JOIN dbo.CITIZEN AS c
		ON p.CITIZEN = c.ID
	LEFT JOIN dbo.View_PEOPLE2 P2 
		ON p.ID = P2.owner_id
	LEFT JOIN dbo.IDDOC ID 
		ON p.ID = ID.owner_id
		AND ID.active = 1
	WHERE p.ID = @owner_id
go

