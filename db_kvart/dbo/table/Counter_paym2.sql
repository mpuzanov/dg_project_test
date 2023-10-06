create table Counter_paym2
(
    fin_id        int                                     not null,
    occ           int                                     not null,
    service_id    varchar(10)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    tip_value     smallint
        constraint DF_COUNTER_PAYM2_tip_value default 0   not null,
    tarif         decimal(9, 4)
        constraint DF_COUNTER_PAYM2_tarif default 0       not null,
    saldo         decimal(9, 2)
        constraint DF_COUNTER_PAYM2_saldo default 0       not null,
    value         decimal(9, 2)
        constraint DF_COUNTER_PAYM2_value default 0       not null,
    discount      decimal(9, 2)
        constraint DF_COUNTER_PAYM2_discount default 0    not null,
    added         decimal(9, 2)
        constraint DF_COUNTER_PAYM2_added default 0       not null,
    paymaccount   decimal(9, 2)
        constraint DF_COUNTER_PAYM2_paymaccount default 0 not null,
    paid          decimal(9, 2)
        constraint DF_COUNTER_PAYM2_paid default 0        not null,
    debt          as ([saldo] + [paid]) - [paymaccount],
    kol           decimal(9, 4),
    fin_paym      smallint,
    kol_counter   smallint,
    kol_inspector smallint,
    metod_rasch   smallint,
    constraint PK_Counter_paym2_1
        primary key (fin_id, occ, service_id, tip_value, tarif)
)
go

exec sp_addextendedproperty 'MS_Description', N'Начисления по лицевому по счетчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_paym2'
go

exec sp_addextendedproperty 'MS_Description', N'0-по показателям инспектора,1-по показателям квартиросьемщика',
     'SCHEMA', 'dbo', 'TABLE', 'Counter_paym2', 'COLUMN', 'tip_value'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во ИПУ', 'SCHEMA', 'dbo', 'TABLE', 'Counter_paym2', 'COLUMN',
     'kol_counter'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во показаний инспектора', 'SCHEMA', 'dbo', 'TABLE', 'Counter_paym2',
     'COLUMN', 'kol_inspector'
go

