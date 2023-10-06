create index pack_id
    on Payings (pack_id)
go

create index occ
    on Payings (occ, forwarded) include (id, pack_id, service_id, value, paymaccount_peny, sup_id, peny_save, fin_id)
go

