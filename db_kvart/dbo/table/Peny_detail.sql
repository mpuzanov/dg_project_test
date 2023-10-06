create table Peny_detail
(
    fin_id           smallint                                not null,
    occ              int                                     not null,
    paying_id        int                                     not null,
    dat1             smalldatetime                           not null,
    data1            smalldatetime                           not null,
    kol_day_dolg     smallint
        constraint DF_PENY_DETAIL_kol_day_dolg default 0     not null,
    paying_id2       int
        constraint DF_PENY_DETAIL_paying_id2 default 0       not null,
    kol_day          smallint
        constraint DF_PENY_DETAIL_kol_day default 0          not null,
    dolg_peny        decimal(9, 2)
        constraint DF_PENY_DETAIL_dolg_peny default 0        not null,
    paid_pred        decimal(9, 2)
        constraint DF_PENY_DETAIL_paid_pred default 0        not null,
    paymaccount_serv decimal(9, 2)
        constraint DF_PENY_DETAIL_paymaccount_serv default 0 not null,
    paymaccount_peny decimal(9, 2)
        constraint DF_PENY_DETAIL_paymaccount_peny default 0 not null,
    Peny_old         decimal(9, 2)
        constraint DF_PENY_DETAIL_Peny_old default 0         not null,
    Peny_old_new     decimal(9, 2)
        constraint DF_PENY_DETAIL_Peny_old_new default 0     not null,
    Peny             decimal(9, 2)
        constraint DF_PENY_DETAIL_Peny default 0             not null,
    dolg             decimal(9, 2)
        constraint DF_PENY_DETAIL_dolg default 0             not null,
    description      varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS,
    proc_peny_day    decimal(9, 4),
    fin_dolg         smallint,
    StavkaCB         smallmoney,
    peny_tmp         as CONVERT([decimal](9, 2), [dolg_peny] * 0.01 * coalesce([proc_peny_day], 0) * [kol_day]),
    constraint PK_PENY_DETAIL_1
        primary key (fin_id, occ, paying_id, dat1, data1, kol_day_dolg, paying_id2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Пени по платежам', 'SCHEMA', 'dbo', 'TABLE', 'Peny_detail'
go

exec sp_addextendedproperty 'MS_Description', N'здесь может быть единый или лицевой поставщика', 'SCHEMA', 'dbo',
     'TABLE', 'Peny_detail', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Код платежа или 0', 'SCHEMA', 'dbo', 'TABLE', 'Peny_detail', 'COLUMN',
     'paying_id2'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин.периода долга', 'SCHEMA', 'dbo', 'TABLE', 'Peny_detail',
     'COLUMN', 'fin_dolg'
go

exec sp_addextendedproperty 'MS_Description', N'Используемая ставка центробанка', 'SCHEMA', 'dbo', 'TABLE',
     'Peny_detail', 'COLUMN', 'StavkaCB'
go

