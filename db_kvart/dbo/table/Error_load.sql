create table Error_load
(
    date_load datetime
        constraint DF__ERROR_LOA__date___0837279D default getdate() not null
        constraint PK__ERROR_LO__43BCBDCE064EDF2B
            primary key,
    occ       int                                                   not null,
    FIO       varchar(35) collate SQL_Latin1_General_CP1251_CI_AS,
    name      varchar(80) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Ошибки при загрузке данных (АРМ Экспорт)', 'SCHEMA', 'dbo', 'TABLE',
     'Error_load'
go

