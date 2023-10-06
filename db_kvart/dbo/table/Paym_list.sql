create table Paym_list
(
    fin_id           smallint                              not null,
    occ              int                                   not null
        constraint FK_PAYM_LIST_OCCUPATIONS
            references Occupations
            on update cascade on delete cascade,
    service_id       varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Paym_list_Services
            references Services
            on update cascade,
    sup_id           int
        constraint DF_PAYM_LIST_sup_id default 0           not null,
    subsid_only      bit
        constraint DF_PAYM_LIST_subsid_only default 0      not null,
    tarif            smallmoney
        constraint DF_Paym_list_tarif default 0            not null,
    saldo            decimal(15, 4)
        constraint DF_Paym_list_saldo default 0            not null,
    value            decimal(15, 4)
        constraint DF_PAYM_LIST_value default 0            not null,
    added            decimal(15, 4)
        constraint DF_PAYM_LIST_added default 0            not null,
    paid             decimal(15, 4)
        constraint DF_PAYM_LIST_paid default 0             not null,
    paymaccount      decimal(15, 4)
        constraint DF_PAYM_LIST_paymaccount default 0      not null,
    paymaccount_peny decimal(15, 4)
        constraint DF_PAYM_LIST_paymaccount_peny default 0 not null,
    account_one      bit
        constraint DF_Paym_list_account_one default 0      not null,
    unit_id          varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    kol              decimal(12, 6),
    koef             smallmoney,
    metod            smallint,
    is_counter       smallint,
    kol_norma        decimal(12, 6),
    metod_old        smallint,
    build_id         int,
    penalty_serv     decimal(15, 4)
        constraint DF_Paym_list_penalty_serv default 0     not null,
    penalty_old      decimal(15, 4)
        constraint DF_Paym_list_penalty_old default 0      not null,
    debt             as ([saldo] + [value] + [added]) - ([paymaccount] - [paymaccount_peny]),
    kol_norma_single decimal(12, 6),
    source_id        int,
    mode_id          int,
    occ_sup_paym     int,
    date_start       date,
    date_end         date,
    kol_added        decimal(12, 6),
    koef_day         decimal(9, 4),
    penalty_prev     decimal(15, 4)
        constraint DF_Paym_list_penalty_prev default 0     not null,
    constraint PK_PAYM_LIST
        primary key (fin_id, occ, service_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Результаты расчета квартплаты', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list'
go

exec sp_addextendedproperty 'MS_Description', N'Ед. лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'услуга', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак внешней услуги', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list',
     'COLUMN', 'subsid_only'
go

exec sp_addextendedproperty 'MS_Description', N'тариф', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'tarif'
go

exec sp_addextendedproperty 'MS_Description', N'вх. сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'saldo'
go

exec sp_addextendedproperty 'MS_Description', N'Начислено по тарифу', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'value'
go

exec sp_addextendedproperty 'MS_Description', N'Разовые', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'added'
go

exec sp_addextendedproperty 'MS_Description', N'Пост. начисление', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'paid'
go

exec sp_addextendedproperty 'MS_Description', N'Оплачено', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'paymaccount'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено пени', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'paymaccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'признак отдельного расчёта поставщика', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_list', 'COLUMN', 'account_one'
go

exec sp_addextendedproperty 'MS_Description', N'еденица измерения', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'unit_id'
go

exec sp_addextendedproperty 'MS_Description', N'объём услуги', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'коэффициент', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'koef'
go

exec sp_addextendedproperty 'MS_Description', N'метод расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'metod'
go

exec sp_addextendedproperty 'MS_Description',
     N' 0 - нет счетчика; 1 - отдельная квитанция по счетчикам; 2 - начисляем в единую квитанцю', 'SCHEMA', 'dbo',
     'TABLE', 'Paym_list', 'COLUMN', 'is_counter'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во по норме', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'kol_norma'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN', 'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'Пени по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'penalty_serv'
go

exec sp_addextendedproperty 'MS_Description', N'конечное пени пред.месяца', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list',
     'COLUMN', 'penalty_old'
go

exec sp_addextendedproperty 'MS_Description', N'конечное сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'debt'
go

exec sp_addextendedproperty 'MS_Description', N'норма на одного', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'kol_norma_single'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'occ_sup_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Объем разовых', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list', 'COLUMN',
     'kol_added'
go

exec sp_addextendedproperty 'MS_Description', N'Пени с предыдущего месяца', 'SCHEMA', 'dbo', 'TABLE', 'Paym_list',
     'COLUMN', 'penalty_prev'
go

