create table Gis_shablons
(
    id           varchar(50)  not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_GIS_SHABLONS
            primary key,
    name         varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments     varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    FileName     varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    FileDateEdit smalldatetime,
    REPORT_BODY  varbinary(max),
    Versia       varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    VersionInt   bigint,
    UserEdit     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DateEdit     smalldatetime,
    size_body    as CONVERT([decimal](9, 2), datalength([REPORT_BODY]) / 1024.00)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список шаблонов ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons'
go

exec sp_addextendedproperty 'MS_Description', N'Код шаблона', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Имя файла', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'Дата файла', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'FileDateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'файл', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN', 'REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'Версия шаблона (строка)', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons',
     'COLUMN', 'Versia'
go

exec sp_addextendedproperty 'MS_Description', N'Версия шаблона (число)', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons',
     'COLUMN', 'VersionInt'
go

exec sp_addextendedproperty 'MS_Description', N'ФИО пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'UserEdit'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'DateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'Размер файла', 'SCHEMA', 'dbo', 'TABLE', 'Gis_shablons', 'COLUMN',
     'size_body'
go

