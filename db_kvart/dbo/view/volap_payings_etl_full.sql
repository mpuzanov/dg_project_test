-- dbo.volap_payings_etl_full source

CREATE   view [dbo].[volap_payings_etl_full]
as
	
select 
		gb.start_date as 'start_date'
	  , ba.town_name as 'town_name'
	  , ba.tip_name as 'tip_name'
	  , ba.street_name as 'street_name'
	  , ba.nom_dom as 'nom_dom'
	  , f.nom_kvr as 'nom_kvr'
	  , p.occ as 'occ'
	  , p.occ_sup as 'occ_sup'
	  , p.value as 'paymaccount'
	  , coalesce(p.paymaccount_peny, 0) as 'paymaccount_peny'
	  , p.value - coalesce(p.paymaccount_peny, 0) as 'paymaccount_serv'
	  , p.commission as 'commission'
	  --, (p.value - coalesce(p.commission, 0)) as 'paymaccount_no_commission'
	  --, (p.value - coalesce(p.paymaccount_peny, 0) - coalesce(p.commission, 0)) as 'paymaccount_no_peny_commission'
	  , pd.fin_id as fin_id
	  , p.id as 'paying_id'
	  , pd.id as 'pack_id'	  
	  , pd.day as 'day'
	  , cast(pd.date_edit as date) as 'date_close'
	  , b.short_name as 'bank_name'
	  , pt.name as 'type_paym'
	  , pd.sup_id as 'sup_id'
	  , sup.name as 'sup_name'	  
	  , prt.name as 'property_name'
	  , coalesce(bs.rasschet, '') as 'rasschet'
	  , bs.filenamedbf as 'filename'	  
	  , ba.nom_dom_sort
	  , f.nom_kvr_sort
	  , dog.dog_name as 'dog_name'
	  , pd.tip_id
	  , ba.id as build_id
	  , f.id as flat_id
	from dbo.payings as p 
		join dbo.paydoc_packs as pd on p.pack_id = pd.id
		join occupation_types tt on pd.tip_id = tt.id
		join dbo.paycoll_orgs as po on pd.source_id = po.id
			and pd.fin_id = po.fin_id
		join dbo.paying_types pt 
			on po.vid_paym = pt.id
		join dbo.bank as b 
			on po.bank = b.id
		join dbo.global_values as gb 
			on pd.fin_id = gb.fin_id
		left join dbo.suppliers_all as sup 
			on p.sup_id = sup.id
		join dbo.occupations as o 
			on p.occ = o.occ
		join dbo.flats f 
			on f.id = o.flat_id
		join dbo.view_buildings as ba 
			on f.bldn_id = ba.id
		join dbo.property_types as prt 
			on o.proptype_id = prt.id
		left join dbo.bank_tbl_spisok as bs 
			on p.filedbf_id = bs.filedbf_id
		left join dbo.dog_sup as dog 
			on p.dog_int = dog.id
	where p.forwarded = cast(1 as bit)
	and pd.fin_id<tt.fin_id;
go

