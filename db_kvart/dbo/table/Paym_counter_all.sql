create table Paym_counter_all
(
    fin_id           smallint      not null,
    occ              int           not null,
    service_id       varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    subsid_only      bit           not null,
    tarif            smallmoney    not null,
    saldo            decimal(9, 2) not null,
    value            decimal(9, 2) not null,
    discount         decimal(9, 2) not null,
    added            decimal(9, 2) not null,
    compens          decimal(9, 2) not null,
    paid             decimal(9, 2) not null,
    paymaccount      decimal(9, 2) not null,
    paymaccount_peny decimal(9, 2) not null,
    debt             as ([saldo] + [paid]) - ([paymaccount] - [paymaccount_peny]),
    kol              decimal(12, 6),
    avg_vday         decimal(12, 8),
    constraint PK_PAYM_COUNTER_ALL
        primary key (fin_id, occ, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Начисления по счётчикам по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_counter_all'
go

