create index build_serv
    on Counters (build_id, service_id) include (id)
go

create index flat_id
    on Counters (flat_id, service_id) include (internal)
go

create index is_build
    on Counters (is_build) include (build_id, flat_id)
go

create index Number_Service
    on Counters (serial_number, service_id, type)
go

