create table Paym_add
(
    id             bigint identity
        constraint PK_PAYM_ADD
            primary key,
    occ            int                                             not null,
    service_id     varchar(10)                                     not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id         int
        constraint DF_PAYM_ADD_sup_idOnPAYM_ADD_old default 0      not null,
    subsid_only    bit
        constraint DF_PAYM_ADD_subsid_onlyOnPAYM_ADD_old default 0 not null,
    tarif          smallmoney
        constraint DF_PAYM_ADD_tarif default 0                     not null,
    koef           smallmoney,
    saldo          decimal(9, 2)
        constraint DF_PAYM_ADD_saldo default 0                     not null,
    socvalue       decimal(9, 2)
        constraint DF_PAYM_ADD_socvalue default 0                  not null,
    value          decimal(9, 2)
        constraint DF_PAYM_ADD_value default 0                     not null,
    discount       decimal(9, 2)
        constraint DF_PAYM_ADD_discount default 0                  not null,
    added          decimal(9, 2)
        constraint DF_PAYM_ADD_added default 0                     not null,
    paymaccount    decimal(9, 2)
        constraint DF_PAYM_ADD_paymaccount default 0               not null,
    paid           decimal(9, 2)
        constraint DF_PAYM_ADD_paid default 0                      not null,
    kol            decimal(12, 6),
    date_ras_start smalldatetime,
    date_ras_end   smalldatetime,
    unit_id        varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    koef_day       decimal(9, 4),
    fin_id_paym    smallint,
    kol_norma      decimal(12, 6)
)
go

exec sp_addextendedproperty 'MS_Description', N'Результаты расчетов разовых, субсидий', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_add'
go

