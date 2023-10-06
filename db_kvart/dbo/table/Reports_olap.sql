create table Reports_olap
(
    id           smallint identity
        constraint PK_REPORTS_OLAP
            primary key,
    name         varchar(50)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    ID_PARENT    smallint
        constraint DF_REPORTS_OLAP_ID_PARENT default 0   not null,
    comments     varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS,
    sort_no      smallint
        constraint DF_REPORTS_OLAP_sort_no default 100,
    slice_body   varbinary(max),
    sql_query    varchar(8000) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit    smalldatetime,
    FileDateEdit smalldatetime,
    FileName     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    only_export  bit
        constraint DF_REPORTS_OLAP_only_export default 0 not null,
    description  nvarchar(2000) collate SQL_Latin1_General_CP1251_CI_AS,
    size_body    decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Аналитические выборки в программе Отчёты', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_olap'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Описание', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'ID_PARENT'
go

exec sp_addextendedproperty 'MS_Description', N'для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'sort_no'
go

exec sp_addextendedproperty 'MS_Description', N'сам файл', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'slice_body'
go

exec sp_addextendedproperty 'MS_Description', N'запрос к БД', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'sql_query'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap',
     'COLUMN', 'FileDateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'Имя файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'только выгрузка', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'only_export'
go

exec sp_addextendedproperty 'MS_Description', N'Описание аналитического отчета', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_olap', 'COLUMN', 'description'
go

exec sp_addextendedproperty 'MS_Description', N'размер отчета', 'SCHEMA', 'dbo', 'TABLE', 'Reports_olap', 'COLUMN',
     'size_body'
go

