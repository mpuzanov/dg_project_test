-- dbo.view_build_all_lite source

CREATE   VIEW [dbo].[view_build_all_lite]
AS
	SELECT t1.*
		 , ot.start_date
		 , ot.Name AS tip_name
		 , ot.is_counter_cur_tarif
	FROM (
		SELECT t.fin_id
			 , t.bldn_id
			 , t.bldn_id AS build_id
			 , t.street_id
			 , t.sector_id
			 , t.div_id
			 , t.tip_id
			 , t.nom_dom
			 , t.dog_bit
			 , t.old
			 , t.arenda_sq
			 , t.build_total_sq
			 , t.build_total_area
			 , t.opu_sq
			 , t.opu_sq_elek
			 , t.opu_sq_otop
			 , t.norma_gkal
			 , t.build_type
			 , t.norma_gkal_gvs
			 , t.is_paym_build
			 , t.norma_gaz_gvs
			 , t.account_rich
		FROM dbo.Buildings_history AS t
		UNION
		SELECT t.fin_current AS fin_id
			 , t.id
			 , t.id AS build_id
			 , t.street_id
			 , t.sector_id
			 , t.div_id
			 , t.tip_id
			 , t.nom_dom
			 , t.dog_bit
			 , t.old
			 , t.arenda_sq
			 , t.build_total_sq
			 , t.build_total_area
			 , t.opu_sq
			 , t.opu_sq_elek
			 , t.opu_sq_otop
			 , t.norma_gkal
			 , t.build_type
			 , t.norma_gkal_gvs
			 , t.is_paym_build
			 , t.norma_gaz_gvs
			 , t.account_rich
		FROM dbo.Buildings AS t 
	) AS t1
		INNER JOIN dbo.VOcc_types_all_lite AS ot 
			ON t1.tip_id = ot.id
			AND t1.fin_id = ot.fin_id;
go

