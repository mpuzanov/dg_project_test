create table Type_gis_file
(
    id           int identity
        constraint PK_TYPE_GIS_FILE_1
            primary key,
    tip_id       smallint     not null,
    FileName     varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS,
    FileDateEdit smalldatetime,
    REPORT_BODY  varbinary(max),
    Version      varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    VersionInt   bigint,
    Name         nvarchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    UserEdit     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    size_body    decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Шаблоны ПД для выгрузки в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Type_gis_file'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование файла', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file',
     'COLUMN', 'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования файла', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file',
     'COLUMN', 'FileDateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'сам файл', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file', 'COLUMN',
     'REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'версия шаблона в файле', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file',
     'COLUMN', 'Version'
go

exec sp_addextendedproperty 'MS_Description', N'Числовое значение версии шаблона', 'SCHEMA', 'dbo', 'TABLE',
     'Type_gis_file', 'COLUMN', 'VersionInt'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование шаблона с версией и датой', 'SCHEMA', 'dbo', 'TABLE',
     'Type_gis_file', 'COLUMN', 'Name'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь, загрузивший шаблон', 'SCHEMA', 'dbo', 'TABLE',
     'Type_gis_file', 'COLUMN', 'UserEdit'
go

exec sp_addextendedproperty 'MS_Description', N'Размер файла', 'SCHEMA', 'dbo', 'TABLE', 'Type_gis_file', 'COLUMN',
     'size_body'
go

