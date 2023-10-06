create table Type_occ_gis
(
    id   smallint    not null
        constraint PK_TYPE_OCC_GIS
            primary key,
    name varchar(20) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды лицевых счетов для выгрузки в ГИС (шаблон лицевых)', 'SCHEMA',
     'dbo', 'TABLE', 'Type_occ_gis'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Type_occ_gis', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Type_occ_gis', 'COLUMN',
     'name'
go

