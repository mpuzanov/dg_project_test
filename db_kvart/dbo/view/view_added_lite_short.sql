-- dbo.view_added_lite_short source

CREATE   VIEW [dbo].[view_added_lite_short]
AS
		SELECT t.fin_id
			 , t.occ
			 , t.service_id
			 , t.add_type
			 , t.value
			 , t.kol
			 , t.sup_id
			 , t.doc_no
			 , t.id
		FROM dbo.Added_Payments AS t
		UNION ALL
		SELECT t.fin_id
			 , t.occ
			 , t.service_id
			 , t.add_type
			 , t.value
			 , t.kol
			 , t.sup_id
			 , t.doc_no
			 , t.id
		FROM dbo.Added_Payments_History AS t;
go

