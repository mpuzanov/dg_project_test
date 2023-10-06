create index IX_PEOPLE
    on People (occ) include (Del, Status2_id)
go

