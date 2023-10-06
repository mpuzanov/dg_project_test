CREATE   PROCEDURE [dbo].[ka_show_add_build]
(
	  @build1 INT -- код дома
	, @fin_id1 SMALLINT = NULL-- Фин.период
	, @fin_id2 SMALLINT = NULL-- Фин.период2
)
AS
	/*
	
	  Список разовых по дому
	  
	  exec ka_show_add_build  1037, 167, 169 
	  exec ka_show_add_build  3239, 171, 171
	  
	*/
	SET NOCOUNT ON
	--SET LOCK_TIMEOUT 2000

	SET LANGUAGE Russian

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, @build1, NULL, NULL)
	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	SELECT ap.kod AS kod
		 , ap.occ AS occ
		 , ap.service_id
		 , s.name AS 'services'
		 , ap.Add_type AS kod_add_type
		 , t.name AS Add_type
		 , ap.doc AS Docum
		 , ap.value AS value
		 , ap.value AS Summa
		 , o.address
		 , CONVERT(VARCHAR(12), data1, 106) AS data1 --'dd MMM yyyy'
		 , CONVERT(VARCHAR(12), data2, 106) AS data2
		 , CONVERT(VARCHAR(12), doc_date, 106) AS doc_date
		 , ap.doc_no AS doc_no
		 , SUBSTRING(s1.name, 1, 20) AS Vin1
		 , SUBSTRING(s2.name, 1, 20) AS Vin2
		 , u.Initials AS username
		 , CASE
			   WHEN ap.Add_type = 6 AND
				   ap.dsc_owner_id IS NOT NULL THEN (
					   SELECT dbo.Fun_InitialsPeople(p.owner_id)
					   FROM dbo.People_history AS p 
						   JOIN dbo.Dsc_owners AS do ON p.owner_id = do.owner_id
					   WHERE do.id = ap.dsc_owner_id
						   AND p.fin_id = ap.fin_id
				   )
			   WHEN ap.dsc_owner_id IS NOT NULL THEN (
					   SELECT dbo.Fun_InitialsPeople(ap.dsc_owner_id)
				   )
			   ELSE ''

		   END AS lgotnik_name
		 , Hours
		 , manual_bit
		 , t2.name AS Add_name2
		 , ap.comments
		 , cl.is_counter
		 , f.nom_kvr
		 , ap.tnorm2
		 , ap.date_edit
		 , ap.kol
		 , ap.id
		 , ap.fin_id
		 , ap.start_date
		 , sa.name AS sup_name
		 , f.nom_kvr_sort
		 , ap.fin_id_paym
		 , dbo.Fun_NameFinPeriod(ap.fin_id_paym) AS fin_paym_name
		 , ap.repeat_for_fin
		 , CASE
				WHEN ap.repeat_for_fin IS NULL THEN NULL
				ELSE dbo.Fun_NameFinPeriod(repeat_for_fin)
			END AS repeat_for_fin_str
	FROM dbo.View_added AS ap 
		JOIN View_services AS s ON 
			ap.service_id = s.id
		JOIN dbo.Added_Types AS t ON 
			ap.Add_type = t.id
		JOIN dbo.Occupations AS o ON 
			ap.occ = o.occ
		JOIN dbo.Flats AS f ON 
			o.flat_id = f.id
		JOIN dbo.Suppliers_all sa ON 
			ap.sup_id = sa.id
		LEFT JOIN dbo.Sector AS s1 ON 
			ap.Vin1 = s1.id
		LEFT JOIN dbo.Suppliers_all AS s2 ON 
			ap.Vin2 = s2.id
		LEFT JOIN dbo.Added_Types_2 AS t2 ON 
			ap.add_type2 = t2.id
		LEFT OUTER JOIN dbo.Consmodes_list cl ON 
			ap.occ = cl.occ
			AND ap.service_id = cl.service_id
			AND ap.fin_id = cl.fin_id
			AND ap.sup_id = cl.sup_id
		LEFT JOIN dbo.Users AS u ON 
			ap.user_edit = u.id		
	WHERE 
		ap.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND f.bldn_id = @build1
	ORDER BY nom_kvr_sort
	OPTION (RECOMPILE)
go

