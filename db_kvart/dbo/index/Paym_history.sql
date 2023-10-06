create index NonClusteredColumnStoreIndex
    on Paym_history ()
    with (allow_row_locks = OFF, allow_page_locks = OFF)
go

create index occ
    on Paym_history (occ)
go

