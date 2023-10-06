-- dbo.view_buildings_lite source

CREATE   VIEW [dbo].[view_buildings_lite]
AS
	SELECT
		b.id
	  , sec.name AS sector_name
	  , t.name AS tip_name
	  , d.name AS div_name
	  , s.name AS street_name
	  , b.nom_dom
	  , CONCAT(s.name , ' д.' , b.nom_dom) AS adres
	  , COALESCE(b.seria, '-') AS seria
	  , COALESCE(b.godp, 0) AS godp
	  , b.street_id
	  , b.sector_id
	  , b.div_id
	  , b.tip_id
	  , b.levels
	  , b.old
	  , b.kolpodezd
	  , b.dog_bit
	  , b.index_id
	  , b.bank_account
	  , b.town_id
	  , b.court_id
	  , b.collector_id
	  , b.id_accounts
	  , b.index_postal
	  , city.name AS town_name
	  , b.date_start
	  , b.date_end
	  , b.norma_gkal
	  , b.arenda_sq
	  , b.is_paym_build
	  , b.build_total_sq
	  , b.build_total_area
	  , b.nom_dom_sort
	  , b.opu_sq
	  , b.opu_sq_elek
	  , b.opu_sq_otop
	  , b.opu_tepl_kol
	  , b.Vid_blag
	  , b.is_lift
	  , b.is_boiler
	  , b.fin_current
	  , b.build_type
	  , b.kod_fias
	  , b.CadastralNumber
	  , CONCAT(s.name , b.nom_dom_sort) AS sort_dom
	  , b.build_uid
	  , CASE WHEN(COALESCE(b.oktmo, '') = '') THEN city.oktmo ELSE b.oktmo END AS oktmo 
	  , case 
			when b.soi_is_transfer_economy=cast(1 as bit) then b.soi_is_transfer_economy
			else t.soi_is_transfer_economy 
	  end AS soi_is_transfer_economy
	FROM dbo.Buildings AS b 
		INNER JOIN dbo.VStreets AS s  ON b.street_id = s.id
		INNER JOIN dbo.VOcc_types AS t  ON b.tip_id = t.id
		LEFT OUTER JOIN dbo.Towns AS city  ON b.town_id = city.id
		LEFT OUTER JOIN dbo.Divisions AS d  ON b.div_id = d.id
		LEFT OUTER JOIN dbo.Sector AS sec  ON b.sector_id = sec.id;
go

