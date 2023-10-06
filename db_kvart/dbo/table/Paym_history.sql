create table Paym_history
(
    fin_id           smallint                                 not null,
    occ              int                                      not null,
    service_id       varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id           int
        constraint DF_PAYM_HISTORY_sup_id default 0           not null,
    subsid_only      bit
        constraint DF_PAYM_HISTORY_subsid_only default 0      not null,
    tarif            smallmoney                               not null,
    saldo            decimal(15, 4)                           not null,
    value            decimal(15, 4)                           not null,
    discount         decimal(15, 4)                           not null,
    added            decimal(15, 4)                           not null,
    compens          decimal(15, 4)                           not null,
    paid             decimal(15, 4)                           not null,
    paymaccount      decimal(15, 4)                           not null,
    paymaccount_peny decimal(15, 4)
        constraint DF_PAYM_HISTORY_paymaccount_peny default 0 not null,
    account_one      bit,
    kol              decimal(12, 6),
    unit_id          varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    metod            smallint,
    is_counter       smallint,
    kol_norma        decimal(12, 6),
    metod_old        smallint,
    build_id         int,
    penalty_serv     decimal(15, 4)
        constraint DF_Paym_history_penalty_serv default 0     not null,
    penalty_old      decimal(15, 4)
        constraint DF_Paym_history_penalty_old default 0      not null,
    debt             as ([saldo] + (([value] - [discount]) + [added])) - ([paymaccount] - [paymaccount_peny]),
    kol_norma_single decimal(12, 6),
    source_id        int,
    mode_id          int,
    koef             smallmoney,
    occ_sup_paym     int,
    date_start       date,
    date_end         date,
    kol_added        decimal(12, 6),
    koef_day         decimal(9, 4),
    penalty_prev     decimal(15, 4)
        constraint DF_Paym_history_penalty_prev default 0     not null,
    constraint PK_PAYM_HISTORY_1
        primary key (fin_id, occ, service_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История начислений по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Paym_history'
go

exec sp_addextendedproperty 'MS_Description', N'Пени по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Paym_history', 'COLUMN',
     'penalty_serv'
go

exec sp_addextendedproperty 'MS_Description', N'Конечное пени предыдущего месяца', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_history', 'COLUMN', 'penalty_old'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paym_history', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paym_history', 'COLUMN',
     'occ_sup_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Пени с предыдущего месяца', 'SCHEMA', 'dbo', 'TABLE', 'Paym_history',
     'COLUMN', 'penalty_prev'
go

