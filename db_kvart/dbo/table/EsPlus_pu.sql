create table EsPlus_pu
(
    id_lic       varchar(10)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    id_lic_old   varchar(10)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    serv_name    varchar(30)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    town_name    varchar(20)
        constraint DF_EsPlus_town_name default 'Ижевск'    not null collate SQL_Latin1_General_CP1251_CI_AS,
    street_name  varchar(50)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    nom_dom      varchar(12)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    korp         varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    nom_kvr      varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_object   varchar(20)
        constraint DF_EsPlus_tip_object default 'Квартира' not null collate SQL_Latin1_General_CP1251_CI_AS,
    serial_num   varchar(20)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    date_prev    smalldatetime,
    val_prev     decimal(12, 6),
    date_current smalldatetime,
    val_current  decimal(12, 6),
    counter_id   int,
    service_id   varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'Ms_description', N'Приборы учета из ЭнергоСбыта', 'SCHEMA', 'dbo', 'TABLE', 'EsPlus_pu'
go

