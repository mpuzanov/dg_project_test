create unique index IX_STREETS
    on Streets (town_id, Name, prefix)
go

create index kod_fias
    on Streets (kod_fias)
go

create index town_id
    on Streets (town_id) include (Name)
go

