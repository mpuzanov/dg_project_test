create index is_current
    on Db_states (is_current) include (dbstate_id)
go

