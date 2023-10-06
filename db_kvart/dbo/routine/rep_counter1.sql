CREATE   PROCEDURE [dbo].[rep_counter1]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT = NULL
	, @div_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @service_id1 VARCHAR(10) = NULL
	, @internal BIT = NULL
)

/*
Список счетчиков

автор:		    Пузанов
дата создания:	01.04.09
дата изменеия:	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	Counter1.fr3

exec rep_counter1 250, 1

*/
AS

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)

	SELECT cl.occ
			 , MAX(o.address) AS [address]
			 , dbo.Fun_Initials(cl.occ) AS Initials
			 , SUM(CASE WHEN service_id='хвод' THEN 1 ELSE 0 END) AS [хвод]
			 , SUM(CASE WHEN service_id='гвод' THEN 1 ELSE 0 END) AS [гвод]
			 , SUM(CASE WHEN service_id='элек' THEN 1 ELSE 0 END) AS [элек]
			 , SUM(CASE WHEN service_id='пгаз' THEN 1 ELSE 0 END) AS [пгаз]
			 , SUM(CASE WHEN service_id='отоп' THEN 1 ELSE 0 END) AS [отоп]
		FROM dbo.View_counter_all AS cl 
			JOIN dbo.View_occ_all_lite AS o ON 
				cl.occ = o.occ
				AND cl.fin_id = o.fin_id
			JOIN dbo.View_build_all AS b ON 
				o.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
		WHERE 
			cl.fin_id = @fin_id1
			AND b.bldn_id = COALESCE(@build_id1, b.bldn_id)
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
			AND cl.service_id = COALESCE(@service_id1, cl.service_id)
			AND cl.internal = COALESCE(@internal, cl.internal)
			AND o.Total_sq > 0
	GROUP BY
		cl.occ
	ORDER BY MAX(b.street_name)
		   , MAX(nom_dom_sort)
		   , MAX(nom_kvr_sort)
	OPTION (OPTIMIZE FOR UNKNOWN, MAXDOP 1)

	--SELECT *
	--FROM (
	--	SELECT cl.occ
	--		 , cl.service_id
	--		 , cl.counter_id
	--		 , CONCAT(b.street_name , ' д.' , b.nom_dom , ' кв.' , o.nom_kvr) AS [address]
	--		 , b.adres AS address_house
	--		 , b.street_name AS name
	--		 , b.nom_dom
	--		 , b.nom_dom_sort
	--		 , o.nom_kvr
	--		 , o.nom_kvr_sort
	--		 , dbo.Fun_Initials(o.occ) AS Initials
	--	FROM dbo.View_counter_all AS cl 
	--		JOIN dbo.View_occ_all_lite AS o ON 
	--			cl.occ = o.occ
	--			AND cl.fin_id = o.fin_id
	--		JOIN dbo.View_build_all AS b ON 
	--			o.bldn_id = b.bldn_id
	--			AND o.fin_id = b.fin_id
	--	WHERE 
	--		cl.fin_id = @fin_id1
	--		AND b.bldn_id = COALESCE(@build_id1, b.bldn_id)
	--		AND b.div_id = COALESCE(@div_id1, b.div_id)
	--		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
	--		AND cl.service_id = COALESCE(@service_id1, cl.service_id)
	--		AND cl.internal = COALESCE(@internal, cl.internal)
	--		AND o.Total_sq > 0
	--) AS t
	--PIVOT (COUNT(t.counter_id) FOR t.service_id IN ([хвод], [гвод], [элек], [пгаз], [отоп])) AS p
	--ORDER BY name
	--	   , nom_dom_sort
	--	   , nom_kvr_sort
	--OPTION (RECOMPILE)
go

