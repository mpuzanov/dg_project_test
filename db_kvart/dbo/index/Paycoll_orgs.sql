create index id
    on Paycoll_orgs (id, fin_id, vid_paym)
go

create index pc_bank
    on Paycoll_orgs (bank) include (ext)
go

