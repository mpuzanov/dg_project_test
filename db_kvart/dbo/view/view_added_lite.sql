-- dbo.view_added_lite source

-- dbo.view_added_lite source

CREATE   view [dbo].[view_added_lite]
as
	select cp.start_date as start_date
		 , t.*
	from (
		select t.fin_id
			 , occ
			 , service_id
			 , add_type
			 , value
			 , add_type2
			 , doc
			 , data1
			 , data2
			 , hours
			 , vin1
			 , vin2
			 , doc_no
			 , doc_date
			 , tnorm2
			 , kol
			 , dsc_owner_id
			 , user_edit
			 , manual_bit
			 , fin_id_paym
			 , comments
			 , id as kod
			 , date_edit
			 , t.id as id
			 , t.sup_id
			 , t.repeat_for_fin
		from dbo.added_payments as t
		union
		select t.fin_id
			 , t.occ
			 , t.service_id
			 , t.add_type
			 , t.value
			 , t.add_type2
			 , t.doc
			 , t.data1
			 , t.data2
			 , t.hours
			 , t.vin1
			 , t.vin2
			 , t.doc_no
			 , t.doc_date
			 , t.tnorm2
			 , t.kol
			 , t.dsc_owner_id
			 , t.user_edit
			 , t.manual_bit
			 , t.fin_id_paym
			 , t.comments
			 , null as kod
			 , null as date_edit
			 , t.id as id
			 , t.sup_id
			 , t.repeat_for_fin
		from dbo.added_payments_history as t
	) as t
		left join dbo.calendar_period cp on cp.fin_id = t.fin_id;
go

