create index pack_id
    on Paydoc_packs (id, fin_id, forwarded) include (day, source_id, date_edit, sup_id)
go

create index fin_id
    on Paydoc_packs (fin_id, tip_id) include (day, date_edit, sup_id, forwarded, source_id)
go

