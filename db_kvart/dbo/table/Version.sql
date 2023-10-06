create table Version
(
    program_name  varchar(20)                       not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_VERSION
            primary key,
    major         int
        constraint DF_VERSION_Major default 0       not null,
    minor         int
        constraint DF_VERSION_Minor default 0       not null,
    release       int
        constraint DF_VERSION_Release default 0     not null,
    build         int
        constraint DF_VERSION_Build default 0       not null,
    versiastr     varchar(50)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    versiaint     int,
    major_min     int
        constraint DF_VERSION_major_min default 0   not null,
    minor_min     int
        constraint DF_VERSION_minor_min default 0   not null,
    release_min   int
        constraint DF_VERSION_release_min default 0 not null,
    build_min     int
        constraint DF_VERSION_build_min default 0   not null,
    versiastr_min varchar(50)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    versiaint_min int
)
go

exec sp_addextendedproperty 'MS_Description', N'Код последних версий клиентских программ', 'SCHEMA', 'dbo', 'TABLE',
     'Version'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование программы', 'SCHEMA', 'dbo', 'TABLE', 'Version', 'COLUMN',
     'program_name'
go

exec sp_addextendedproperty 'MS_Description', N'Текущий номер версии', 'SCHEMA', 'dbo', 'TABLE', 'Version', 'COLUMN',
     'major'
go

exec sp_addextendedproperty 'MS_Description', N'Строковое значение текущей версии', 'SCHEMA', 'dbo', 'TABLE', 'Version',
     'COLUMN', 'versiastr'
go

exec sp_addextendedproperty 'MS_Description', N'Числовое значение текущей версии', 'SCHEMA', 'dbo', 'TABLE', 'Version',
     'COLUMN', 'versiaint'
go

exec sp_addextendedproperty 'MS_Description', N'Строковое значение минимально разрешённой для работы версии', 'SCHEMA',
     'dbo', 'TABLE', 'Version', 'COLUMN', 'versiastr_min'
go

exec sp_addextendedproperty 'MS_Description', N'Числовое значение минимально разрешённой для работы версии', 'SCHEMA',
     'dbo', 'TABLE', 'Version', 'COLUMN', 'versiaint_min'
go

