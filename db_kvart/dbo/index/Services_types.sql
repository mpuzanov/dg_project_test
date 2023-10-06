create unique index service_id_serv_name_uniq
    on Services_types (tip_id, service_id, service_name)
go

create index tip_id
    on Services_types (tip_id) include (service_id)
go

