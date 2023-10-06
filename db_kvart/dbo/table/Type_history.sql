create table Type_history
(
    id         smallint                                 not null
        constraint PK_TYPE_HISTORY
            primary key,
    name       varchar(30)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_param   bit
        constraint DF_TYPE_HISTORY_is_param default 0   not null,
    sort_no    smallint
        constraint DF_TYPE_HISTORY_sort_no default 100  not null,
    is_visible bit
        constraint DF_Type_history_is_visible default 1 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды просмотра истории', 'SCHEMA', 'dbo', 'TABLE', 'Type_history'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Type_history', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Type_history', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'есть детализация истории', 'SCHEMA', 'dbo', 'TABLE', 'Type_history',
     'COLUMN', 'is_param'
go

exec sp_addextendedproperty 'MS_Description', N'поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Type_history',
     'COLUMN', 'sort_no'
go

exec sp_addextendedproperty 'MS_Description', N'признак видимости типа', 'SCHEMA', 'dbo', 'TABLE', 'Type_history',
     'COLUMN', 'is_visible'
go

