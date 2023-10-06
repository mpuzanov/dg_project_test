create index tip_id
    on Occupation_Types_History (id, fin_id) include (name)
go

