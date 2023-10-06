create table Streets
(
    Id         int                              not null
        constraint PK_STREETS
            primary key nonclustered,
    Name       varchar(50)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    town_id    smallint
        constraint DF_STREETS_town_id default 1 not null
        constraint FK_Streets_Towns
            references Towns,
    code       bigint,
    prefix     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kod_fias   varchar(36) collate SQL_Latin1_General_CP1251_CI_AS,
    full_name  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    full_name2 varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Улицы', 'SCHEMA', 'dbo', 'TABLE', 'Streets'
go

exec sp_addextendedproperty 'MS_Description', N'Код улицы', 'SCHEMA', 'dbo', 'TABLE', 'Streets', 'COLUMN', 'Id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование улицы', 'SCHEMA', 'dbo', 'TABLE', 'Streets', 'COLUMN',
     'Name'
go

exec sp_addextendedproperty 'MS_Description', N'Код населённого пункта', 'SCHEMA', 'dbo', 'TABLE', 'Streets', 'COLUMN',
     'town_id'
go

exec sp_addextendedproperty 'MS_Description', N'код из КЛАДР', 'SCHEMA', 'dbo', 'TABLE', 'Streets', 'COLUMN', 'code'
go

exec sp_addextendedproperty 'MS_Description', N'Сокращение', 'SCHEMA', 'dbo', 'TABLE', 'Streets', 'COLUMN', 'prefix'
go

exec sp_addextendedproperty 'MS_Description', N'Уникальный идентификатор ФИАС', 'SCHEMA', 'dbo', 'TABLE', 'Streets',
     'COLUMN', 'kod_fias'
go

exec sp_addextendedproperty 'MS_Description', N'наименование, где сокращение в конце', 'SCHEMA', 'dbo', 'TABLE',
     'Streets', 'COLUMN', 'full_name'
go

exec sp_addextendedproperty 'MS_Description', N'наименование, где сокращение в начале', 'SCHEMA', 'dbo', 'TABLE',
     'Streets', 'COLUMN', 'full_name2'
go

