create index occ
    on Consmodes_list (occ) include (service_id, sup_id, source_id, mode_id, is_counter, account_one, fin_id)
go

