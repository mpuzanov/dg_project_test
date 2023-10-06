create index tip_id
    on Occupation_Types (id) include (fin_id, name)
go

create unique index type_name
    on Occupation_Types (name)
go

