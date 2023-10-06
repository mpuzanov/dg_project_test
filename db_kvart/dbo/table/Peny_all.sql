create table Peny_all
(
    fin_id           smallint                             not null,
    occ              int                                  not null,
    dolg             decimal(9, 2)
        constraint DF_Peny_all_dolg default 0             not null,
    dolg_peny        decimal(9, 2)
        constraint DF_Peny_all_dolg_peny default 0        not null,
    paid_pred        decimal(9, 2)
        constraint DF_Peny_all_paid_pred default 0        not null,
    peny_old         decimal(9, 2)
        constraint DF_Peny_all_peny_old default 0         not null,
    paymaccount      decimal(9, 2)
        constraint DF_Peny_all_paymaccount default 0      not null,
    paymaccount_peny decimal(9, 2)
        constraint DF_Peny_all_paymaccount_peny default 0 not null,
    peny_old_new     decimal(9, 2)
        constraint DF_Peny_all_peny_old_new default 0     not null,
    penalty_added    decimal(9, 2)
        constraint DF_Peny_all_penalty_added default 0    not null,
    kolday           smallint
        constraint DF_Peny_all_kolday default 0,
    penalty_value    decimal(9, 2)
        constraint DF_Peny_all_penalty_value default 0    not null,
    debt_peny        as [peny_old_new] + [penalty_added] + [penalty_value],
    metod            smallint,
    data_rascheta    smalldatetime,
    occ1             int
        constraint DF_Peny_all_occ1 default 0             not null,
    sup_id           int
        constraint DF_Peny_all_sup_id default 0           not null,
    penalty_calc     bit,
    constraint PK_Peny_all
        primary key (fin_id, occ),
    constraint CK_Peny_all
        check ([paymaccount_peny] < 0 OR [paymaccount_peny] <= [peny_old] AND [peny_old] >= 0)
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица с расчётами пеней', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'здесь может быть единый или лицевой поставщика', 'SCHEMA', 'dbo',
     'TABLE', 'Peny_all', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'общий долг', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN', 'dolg'
go

exec sp_addextendedproperty 'MS_Description', N'долг пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN', 'dolg_peny'
go

exec sp_addextendedproperty 'MS_Description', N'начислено в пред.периоде', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all',
     'COLUMN', 'paid_pred'
go

exec sp_addextendedproperty 'MS_Description', N'оплата', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN', 'paymaccount'
go

exec sp_addextendedproperty 'MS_Description', N'оплата пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'paymaccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'пени предыдущего периода(изменённое с учётом оплаты)', 'SCHEMA', 'dbo',
     'TABLE', 'Peny_all', 'COLUMN', 'peny_old_new'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во дней', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN', 'kolday'
go

exec sp_addextendedproperty 'MS_Description', N'расчитанное пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'penalty_value'
go

exec sp_addextendedproperty 'MS_Description', N'метод расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'metod'
go

exec sp_addextendedproperty 'MS_Description', N'дата расчета', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'data_rascheta'
go

exec sp_addextendedproperty 'MS_Description', N'единый лицевой счет', 'SCHEMA', 'dbo', 'TABLE', 'Peny_all', 'COLUMN',
     'occ1'
go

