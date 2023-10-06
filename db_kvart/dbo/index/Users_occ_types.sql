create index sysuser
    on Users_occ_types (SYSUSER) include (fin_id_start, ONLY_TIP_ID)
go

