create table Reports_styles
(
    id          int         not null
        constraint PK_REPORTS_STYLES
            primary key,
    name        varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    filename    varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    body_styles varbinary(max)
)
go

exec sp_addextendedproperty 'MS_Description', N'Стили для отчётов (FastReport)', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_styles'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reports_styles', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reports_styles', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'имя файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports_styles', 'COLUMN',
     'filename'
go

exec sp_addextendedproperty 'MS_Description', N'сам файл стиля', 'SCHEMA', 'dbo', 'TABLE', 'Reports_styles', 'COLUMN',
     'body_styles'
go

