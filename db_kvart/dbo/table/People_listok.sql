create table People_listok
(
    id             int identity
        constraint PK_PEOPLE_LISTOK
            primary key,
    listok_id      smallint    not null,
    occ            int         not null,
    last_name      varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    first_name     varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    second_name    varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    DateCreate     smalldatetime,
    owner_id       int,
    birthdate      smalldatetime,
    KraiOld        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionOld       varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownOld        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageOld     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    StreetOld      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_domOld     varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_krpOld     varchar(5) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_kvrOld     varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    KraiNew        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionNew       varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownNew        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageNew     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    StreetNew      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_domNew     varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_krpNew     varchar(5) collate SQL_Latin1_General_CP1251_CI_AS,
    Nom_kvrNew     varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    KraiBirth      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    RaionBirth     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    TownBirth      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    VillageBirth   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    PlaceWork      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    JobTitle       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DateReg        smalldatetime,
    DateEnd        smalldatetime,
    DateDel        varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    Nationality    varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    Citizen_id     smallint,
    sex            smallint,
    DOCTYPE_ID     varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    DOC_NO         varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    PASSSER_NO     varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    ISSUED         smalldatetime,
    DOCORG         varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    kod_pvs        varchar(7) collate SQL_Latin1_General_CP1251_CI_AS,
    OwnerParent    int,
    Comments1      varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    Comments2      varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    OrganRegUcheta varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    snils          varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    people_uid     uniqueidentifier
)
go

exec sp_addextendedproperty 'MS_Description', N'Адресные листки прибытия-убытия', 'SCHEMA', 'dbo', 'TABLE',
     'People_listok'
go

exec sp_addextendedproperty 'MS_Description', N'код листка прибытия-убытия', 'SCHEMA', 'dbo', 'TABLE', 'People_listok',
     'COLUMN', 'listok_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'People_listok', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код гражданина', 'SCHEMA', 'dbo', 'TABLE', 'People_listok', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Орган регистрационного учёта', 'SCHEMA', 'dbo', 'TABLE',
     'People_listok', 'COLUMN', 'OrganRegUcheta'
go

