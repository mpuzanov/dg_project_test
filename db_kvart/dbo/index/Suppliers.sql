create unique index id
    on Suppliers (id)
go

create index sup_id_etc
    on Suppliers (id) include (name, service_id, sup_id)
go

create unique index serv_sup
    on Suppliers (service_id, sup_id)
go

