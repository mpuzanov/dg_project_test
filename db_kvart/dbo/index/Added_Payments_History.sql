create index occ
    on Added_Payments_History (occ, fin_id, service_id, sup_id) include (add_type, value, kol, doc_no)
go

