-- dbo.view_occ_main source

CREATE   VIEW [dbo].[view_occ_main]
AS
	SELECT *
	FROM (
		SELECT c.start_date
			 , t1.*
			 , f.bldn_id
			 , f.bldn_id AS build_id
			 , f.nom_kvr
			 , f.nom_kvr_sort
			 , f.floor
			 , o.occ_uid
			 , o.email
			 , o.telephon
		FROM (
			SELECT t.fin_id
				 , t.occ
				 , t.tip_id
				 , t.flat_id
				 , ot.name AS tip_name
				 , t.roomtype_id
				 , t.proptype_id
				 , t.status_id
				 , t.living_sq
				 , t.total_sq
				 , t.jeu
				 , t.id_jku_gis
				 , t.kol_people
				 , t.kol_people_reg
				 , t.kol_people_all
				 , t.kol_people_owner
			FROM dbo.Occ_history AS t
				JOIN dbo.Occupation_Types_History AS ot 
					ON t.tip_id = ot.Id
					AND t.fin_id = ot.fin_id
			UNION
			SELECT COALESCE(t.fin_id, ot.fin_id) AS fin_id
				 , t.occ
				 , t.tip_id
				 , t.flat_id
				 , OT.name AS tip_name
				 , t.roomtype_id
				 , t.proptype_id
				 , t.status_id
				 , t.living_sq
				 , t.total_sq
				 , t.jeu
				 , t.id_jku_gis
				 , t.kol_people
				 , t.kol_people_reg
				 , t.kol_people_all
				 , t.kol_people_owner
			FROM dbo.Occupations AS t
				JOIN dbo.Occupation_Types AS OT 
					ON t.tip_id = OT.Id
		) AS t1
			JOIN dbo.Flats AS f 
				ON t1.flat_id = f.Id
			JOIN dbo.Occupations AS o 
				ON t1.occ = o.occ
			JOIN dbo.Calendar_period AS c 
				ON t1.fin_id=c.fin_id
	) AS t2;
go

