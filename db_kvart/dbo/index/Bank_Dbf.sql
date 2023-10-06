create index filedbf_id
    on Bank_Dbf (filedbf_id)
go

create index pack_id
    on Bank_Dbf (pack_id, pdate, occ) include (id, bank_id, sum_opl, service_id)
go

