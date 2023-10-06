create index occ_sup
    on Occ_Suppliers (occ_sup)
go

create index occ
    on Occ_Suppliers (occ) include (fin_id, sup_id, occ_sup, dog_int)
go

