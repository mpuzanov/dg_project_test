create table Collectors
(
    id           smallint identity
        constraint PK_COLLECTORS
            primary key,
    name         varchar(50)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    procent      decimal(6, 2)
        constraint DF_COLLECTORS_procent default 0 not null,
    contact_info varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Коллекторские агенства', 'SCHEMA', 'dbo', 'TABLE', 'Collectors'
go

