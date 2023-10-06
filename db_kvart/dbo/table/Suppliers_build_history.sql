create table Suppliers_build_history
(
    fin_id               smallint                                            not null,
    build_id             int                                                 not null,
    sup_id               int                                                 not null,
    service_id           varchar(10)
        constraint DF_SUPPLIERS_BUILD_HISTORY_service_id default ''          not null collate SQL_Latin1_General_CP1251_CI_AS,
    paym_blocked         bit                                                 not null,
    add_blocked          bit                                                 not null,
    lastday_without_peny smallint
        constraint DF_SUPPLIERS_BUILD_HISTORY_lastday_without_peny default 0 not null,
    is_peny              char
        constraint DF_SUPPLIERS_BUILD_HISTORY_is_peny default 'D'            not null collate SQL_Latin1_General_CP1251_CI_AS,
    start_date_work      smalldatetime,
    penalty_metod        smallint,
    print_blocked        bit
        constraint DF_SUPPLIERS_BUILD_HISTORY_print_blocked default 0        not null,
    gis_blocked          bit
        constraint DF_SUPPLIERS_BUILD_HISTORY_gis_blocked default 0          not null,
    constraint PK_SUPPLIERS_BUILD_HISTORY
        primary key (fin_id, build_id, sup_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История поставщиков по домам по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_build_history'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_build_history',
     'COLUMN', 'fin_id'
go

