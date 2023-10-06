create index dog_sup_id
    on Dog_sup (sup_id)
go

create index dog_tip_id
    on Dog_sup (tip_id)
go

create unique index id
    on Dog_sup (id)
go

