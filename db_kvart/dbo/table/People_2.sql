create table People_2
(
    id           int identity
        constraint PK_People_2_1
            primary key,
    owner_id     int not null,
    KraiOld      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionOld     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownOld      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageOld   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    StreetOld    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_domOld   varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_kvrOld   varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    KraiNew      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionNew     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownNew      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageNew   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    StreetNew    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_domNew   varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_kvrNew   varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    KraiBirth    varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionBirth   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownBirth    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageBirth varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Предыдущее место жительство, будущее и место рождения', 'SCHEMA', 'dbo',
     'TABLE', 'People_2'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Край предыдущего места жительства', 'SCHEMA', 'dbo', 'TABLE',
     'People_2', 'COLUMN', 'KraiOld'
go

exec sp_addextendedproperty 'MS_Description', N'Район', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'RaionOld'
go

exec sp_addextendedproperty 'MS_Description', N'Город, пгт', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'TownOld'
go

exec sp_addextendedproperty 'MS_Description', N'Село, деревня', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'VillageOld'
go

exec sp_addextendedproperty 'MS_Description', N'Улица', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'StreetOld'
go

exec sp_addextendedproperty 'MS_Description', N'Номер дома', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'Nom_domOld'
go

exec sp_addextendedproperty 'MS_Description', N'Номер квартиры', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'Nom_kvrOld'
go

exec sp_addextendedproperty 'MS_Description', N'Край нового места жительства', 'SCHEMA', 'dbo', 'TABLE', 'People_2',
     'COLUMN', 'KraiNew'
go

exec sp_addextendedproperty 'MS_Description', N'Район', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'RaionNew'
go

exec sp_addextendedproperty 'MS_Description', N'Город, пгт', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'TownNew'
go

exec sp_addextendedproperty 'MS_Description', N'Село, деревня', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'VillageNew'
go

exec sp_addextendedproperty 'MS_Description', N'Улица', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'StreetNew'
go

exec sp_addextendedproperty 'MS_Description', N'Номер дома', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'Nom_domNew'
go

exec sp_addextendedproperty 'MS_Description', N'Номер квартиры', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'Nom_kvrNew'
go

exec sp_addextendedproperty 'MS_Description', N'Край места рождения', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'KraiBirth'
go

exec sp_addextendedproperty 'MS_Description', N'Район', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'RaionBirth'
go

exec sp_addextendedproperty 'MS_Description', N'Город, пгт', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN', 'TownBirth'
go

exec sp_addextendedproperty 'MS_Description', N'Село, деревня', 'SCHEMA', 'dbo', 'TABLE', 'People_2', 'COLUMN',
     'VillageBirth'
go

