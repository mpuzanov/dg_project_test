CREATE   PROCEDURE [dbo].[rep_flatcard1]
(
	  @occ1 INT = NULL
	, @flat_id1 INT = NULL
)
AS
	SET NOCOUNT ON
	/*
	
	Выдаем первую часть информации для 
	поквартирной карточки
	
	exec rep_flatcard1 @occ1=177028, @flat_id1=79948
	exec rep_flatcard1 @occ1=null, @flat_id1=79948
	
	*/
	SET NOCOUNT ON

	IF @occ1 IS NULL
		AND @flat_id1 IS NULL
		SET @occ1 = 0

	SELECT TOP (1)
		 o.Occ
		 , b.socr_street AS socr_name
		 , b.street_name AS name
		 , b.nom_dom
		 , b.nom_dom_without_korp AS nom_dom_without_korp
		 , b.korp AS korp
		 , f.nom_kvr
		 , o.Total_sq
		 , o.living_sq
		 , o.[address]
		 , CASE
			   WHEN T.region_short IS NOT NULL THEN concat(T.region_short , ',' , o.address)
			   ELSE o.address
		   END AS Adres_full
		 , (
			   SELECT TOP (1) vp.fio
			   FROM VPeople vp
			   WHERE vp.Occ = @occ1
				   AND vp.Fam_id = 'отвл'
				   AND vp.Del = 0
		   ) AS [OWNER]
		 , gb.[State] AS [State]
		 , gb.Region AS Region
		 , T.full_name_region AS Town
		 , o.jeu AS jeu
		 , o.proptype_id
		 , o.roomtype_id
		 , o.socnaim
		 , o.comments
		 , o.doc_order_kvr
		 , o.rooms
		 , f.floor
		 , f.approach
		 , CASE
			   WHEN ot.synonym_name <> '' THEN ot.synonym_name
			   ELSE ot.name
		   END AS UK_name
		 , ot.adres AS UK_Adres
		 , ot.telefon AS UK_telefon
		 , ot.telefon_pasp AS UK_telefon_pasp
		 , ot.logo
		   --,o.kol_people_reg AS kol_people
		 , [dbo].[Fun_GetKolPeopleOccReg](b.fin_current, o.Occ) AS kol_people
		 , o.flat_id
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.ID
		JOIN dbo.View_buildings AS b 
			ON f.bldn_id = b.ID
		JOIN dbo.Occupation_Types AS ot 
			ON o.tip_id = ot.ID
		JOIN dbo.Global_values AS gb 
			ON ot.fin_id = gb.fin_id
		LEFT JOIN dbo.Towns AS T 
			ON b.town_id = T.ID
	WHERE (o.Occ = @occ1 OR @occ1 IS NULL)
		AND (o.flat_id = @flat_id1 OR @flat_id1 IS NULL)
go

