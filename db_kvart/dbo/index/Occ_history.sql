create index fin_id_tip_id
    on Occ_history (fin_id, tip_id) include (occ, flat_id)
go

create index flat_id
    on Occ_history (flat_id)
go

create index occ
    on Occ_history (occ) include (tip_id, flat_id)
go

