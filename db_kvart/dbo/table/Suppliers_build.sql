create table Suppliers_build
(
    id                   int identity
        constraint PK_SUPPLIERS_BUILD
            primary key,
    build_id             int                                         not null
        constraint FK_SUPPLIERS_BUILD_BUILDINGS
            references Buildings,
    sup_id               int                                         not null,
    service_id           varchar(10)
        constraint DF_SUPPLIERS_BUILD_service_id default ''          not null collate SQL_Latin1_General_CP1251_CI_AS,
    paym_blocked         bit                                         not null,
    add_blocked          bit                                         not null,
    lastday_without_peny smallint
        constraint DF_SUPPLIERS_BUILD_lastday_without_peny default 0 not null,
    is_peny              char
        constraint DF_SUPPLIERS_BUILD_is_peny default 'D'            not null collate SQL_Latin1_General_CP1251_CI_AS,
    start_date_work      smalldatetime,
    penalty_metod        smallint,
    print_blocked        bit
        constraint DF_SUPPLIERS_BUILD_print_blocked default 0        not null,
    gis_blocked          bit
        constraint DF_SUPPLIERS_BUILD_gis_blocked default 0          not null,
    constraint CK_SUPPLIERS_BUILD_PENY
        check ([is_peny] = 'Y' AND [penalty_metod] IS NOT NULL OR [is_peny] = 'N' OR [is_peny] = 'D')
)
go

exec sp_addextendedproperty 'MS_Description', N'Поставщики по домам по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build',
     'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build', 'COLUMN',
     'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать начисление', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build',
     'COLUMN', 'paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать расчёт разовых', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build', 'COLUMN', 'add_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты пени', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build', 'COLUMN', 'lastday_without_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени Y-Да, N - Нет, D - По умолчанию', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_build', 'COLUMN', 'is_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Дата начала обслуживания дома', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build', 'COLUMN', 'start_date_work'
go

exec sp_addextendedproperty 'MS_Description', N'Метод расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build',
     'COLUMN', 'penalty_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка печати квитанций', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build', 'COLUMN', 'print_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка выгрузки в ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build',
     'COLUMN', 'gis_blocked'
go

