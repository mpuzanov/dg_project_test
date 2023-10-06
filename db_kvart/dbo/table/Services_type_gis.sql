create table Services_type_gis
(
    tip_id           smallint     not null
        constraint FK_SERVICES_TYPE_GIS_OCCUPATION_TYPES
            references Occupation_Types,
    service_name_gis varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS,
    num_ref          smallint
        constraint FK_SERVICES_TYPE_GIS_SERVICES_TYPE_GIS_REF
            references Services_type_gis_ref,
    constraint PK_SERVICES_TYPE_GIS_1
        primary key (tip_id, service_name_gis)
)
go

exec sp_addextendedproperty 'MS_Description', N'Используется для выгрузки ПД в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Реестровый номер справочника', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_gis', 'COLUMN', 'num_ref'
go

