create index counter_id
    on Counter_list_all (counter_id)
go

create index occ_fin_serv
    on Counter_list_all (occ, fin_id, service_id)
go

