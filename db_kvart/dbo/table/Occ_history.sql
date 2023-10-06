create table Occ_history
(
    fin_id              smallint                             not null,
    occ                 int                                  not null
        constraint FK_OCC_HISTORY_OCCUPATIONS
            references Occupations
            on update cascade,
    tip_id              smallint                             not null
        constraint FK_OCC_HISTORY_OCCUPATION_TYPES
            references Occupation_Types,
    flat_id             int                                  not null,
    roomtype_id         varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    proptype_id         varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    status_id           varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    living_sq           smallmoney                           not null,
    total_sq            smallmoney                           not null,
    teplo_sq            smallmoney
        constraint DF_OCC_HISTORY_teplo_sq default 0         not null,
    norma_sq            smallmoney
        constraint DF_OCC_HISTORY_norma_sq default 0         not null,
    socnaim             bit
        constraint DF_OCC_HISTORY_socnaim default 0          not null,
    saldo               decimal(15, 4)                       not null,
    saldo_serv          decimal(15, 4)
        constraint DF_OCC_HISTORY_saldo_serv default 0       not null,
    value               decimal(15, 4)
        constraint DF_OCC_HISTORY_Value default 0            not null,
    discount            decimal(15, 4)
        constraint DF_OCC_HISTORY_Discount default 0         not null,
    compens             decimal(15, 4)
        constraint DF_OCC_HISTORY_Compens default 0          not null,
    added               decimal(15, 4)
        constraint DF_OCC_HISTORY_Added default 0            not null,
    paymaccount         decimal(9, 2)                        not null,
    paymaccount_peny    decimal(9, 2)
        constraint DF_OCC_HISTORY_PaymAccount_peny default 0 not null,
    paid                decimal(15, 4)
        constraint DF_OCC_HISTORY_Paid default 0             not null,
    paid_minus          decimal(15, 4)
        constraint DF_OCC_HISTORY_Paid_minus default 0       not null,
    paid_old            decimal(15, 4)
        constraint DF_OCC_HISTORY_Paid_old default 0         not null,
    penalty_calc        bit
        constraint DF_OCC_HISTORY_Penalty_debt default 1     not null,
    penalty_old         decimal(9, 2)
        constraint DF_OCC_HISTORY_Penalty_old default 0      not null,
    penalty_old_new     decimal(9, 2)
        constraint DF_OCC_HISTORY_Penalty_old_new default 0  not null,
    penalty_added       decimal(9, 2)
        constraint DF_Occ_history_Penalty_added default 0    not null,
    penalty_value       decimal(9, 2)
        constraint DF_OCC_HISTORY_Penalty_last default 0     not null,
    jeu                 smallint,
    saldo_edit          smallint,
    penalty_old_edit    smallint,
    comments            varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    comments2           varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_people          smallint,
    saldoAll            decimal(15, 4),
    paymaccount_servAll decimal(15, 4),
    paidAll             decimal(15, 4),
    addedAll            decimal(15, 4),
    debt                as ([saldo] + ([value] - [discount]) + [added]) - ([paymaccount] - [paymaccount_peny]),
    id_jku_gis          varchar(13) collate SQL_Latin1_General_CP1251_CI_AS,
    kolMesDolg          smallint
        constraint DF_OCC_HISTORY_KolMesDolg default 0,
    comments_print      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_people_reg      smallint,
    kol_people_all      smallint,
    id_els_gis          varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_people_owner    smallint,
    data_rascheta       smalldatetime,
    date_start          smalldatetime,
    date_end            smalldatetime,
    constraint PK_OCC_HISTORY
        primary key (fin_id, occ)
)
go

exec sp_addextendedproperty 'MS_Description', N'История лицевых счетов', 'SCHEMA', 'dbo', 'TABLE', 'Occ_history'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во месяцев долга', 'SCHEMA', 'dbo', 'TABLE', 'Occ_history',
     'COLUMN', 'kolMesDolg'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий для печати в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_history', 'COLUMN', 'comments_print'
go

exec sp_addextendedproperty 'MS_Description', N' ЕЛС по ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Occ_history', 'COLUMN',
     'id_els_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во собственников', 'SCHEMA', 'dbo', 'TABLE', 'Occ_history',
     'COLUMN', 'kol_people_owner'
go

