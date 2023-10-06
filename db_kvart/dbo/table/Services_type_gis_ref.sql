create table Services_type_gis_ref
(
    id_num_ref smallint    not null
        constraint PK_SERVICES_TYPE_GIS_REF
            primary key,
    name       varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Используется для выгрузки ПД в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_gis_ref'
go

