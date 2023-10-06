create index IX_ADDED
    on Added_Payments (occ, service_id, sup_id) include (add_type, value, kol, fin_id, doc_no)
go

