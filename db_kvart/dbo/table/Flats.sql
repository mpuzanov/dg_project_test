create table Flats
(
    id              int identity
        constraint PK_FLATS
            primary key,
    bldn_id         int                       not null
        constraint FK_FLATS_BUILDINGS
            references Buildings,
    nom_kvr         varchar(20)               not null collate SQL_Latin1_General_CP1251_CI_AS,
    floor           smallint,
    rooms           smallint,
    approach        smallint,
    telephon        int,
    nom_kvr_sort    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    id_nom_gis      varchar(14) collate SQL_Latin1_General_CP1251_CI_AS,
    CadastralNumber varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    is_flat         bit
        constraint DF_FLATS_is_flat default 1 not null,
    is_unpopulated  bit default 0             not null,
    flat_uid        uniqueidentifier,
    area            decimal(9, 2)
        constraint DF_Flats_area default 0    not null,
    constraint IX_FLATS
        unique (bldn_id, nom_kvr)
)
go

exec sp_addextendedproperty 'MS_Description', N'Квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Flats'
go

exec sp_addextendedproperty 'MS_Description', N'код квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'bldn_id'
go

exec sp_addextendedproperty 'MS_Description', N'номер квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'nom_kvr'
go

exec sp_addextendedproperty 'MS_Description', N'этаж', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'floor'
go

exec sp_addextendedproperty 'MS_Description', N'кол. комнат', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'rooms'
go

exec sp_addextendedproperty 'MS_Description', N'номер подъезда', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'approach'
go

exec sp_addextendedproperty 'MS_Description', N'телефон', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'telephon'
go

exec sp_addextendedproperty 'MS_Description', N'№ квартиры для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN',
     'nom_kvr_sort'
go

exec sp_addextendedproperty 'MS_Description', N'код квартиры в ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN',
     'id_nom_gis'
go

exec sp_addextendedproperty 'MS_Description', N'кадастровый номер', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN',
     'CadastralNumber'
go

exec sp_addextendedproperty 'MS_Description', N'Признак квартиры (а не машиноместа или др.)', 'SCHEMA', 'dbo', 'TABLE',
     'Flats', 'COLUMN', 'is_flat'
go

exec sp_addextendedproperty 'MS_Description', N'Признак нежилого помещения', 'SCHEMA', 'dbo', 'TABLE', 'Flats',
     'COLUMN', 'is_unpopulated'
go

exec sp_addextendedproperty 'MS_Description', N'Площадь помещения', 'SCHEMA', 'dbo', 'TABLE', 'Flats', 'COLUMN', 'area'
go

