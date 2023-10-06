create table Counter_format
(
    id              int                                        not null
        constraint PK_Counter_format
            primary key,
    name            varchar(50)                                not null collate SQL_Latin1_General_CP1251_CI_AS,
    visible         bit
        constraint DF_Counter_format_visible default 1         not null,
    is_input_format bit
        constraint DF_Counter_format_is_input_format default 1 not null,
    tip             varchar(10)
        constraint DF_Counter_format_tip default 'ППУ'         not null collate SQL_Latin1_General_CP1251_CI_AS,
    ext             varchar(10)
        constraint DF_Counter_format_ext default 'EXCEL'       not null collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit       smalldatetime                              not null,
    settings_json   nvarchar(max) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_Counter_format
            check (isjson([settings_json]) = 1)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список форматов для импорта-экспорта ПУ', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_format'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование формата', 'SCHEMA', 'dbo', 'TABLE', 'Counter_format',
     'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'признак видимости в списке выбора', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_format', 'COLUMN', 'visible'
go

exec sp_addextendedproperty 'MS_Description', N'True - формат для загрузки показаний ПУ, False - выгрузки показаний',
     'SCHEMA', 'dbo', 'TABLE', 'Counter_format', 'COLUMN', 'is_input_format'
go

exec sp_addextendedproperty 'MS_Description', N'формат файла (TXT, EXCEL)', 'SCHEMA', 'dbo', 'TABLE', 'Counter_format',
     'COLUMN', 'ext'
go

exec sp_addextendedproperty 'MS_Description', N'настройки формата в JSON', 'SCHEMA', 'dbo', 'TABLE', 'Counter_format',
     'COLUMN', 'settings_json'
go

