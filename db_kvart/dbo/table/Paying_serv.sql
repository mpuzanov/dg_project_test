create table Paying_serv
(
    occ              int                                     not null,
    service_id       varchar(10)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id           int
        constraint DF_PAYING_SERV_sup_id default 0           not null,
    paying_id        int                                     not null,
    value            decimal(9, 2)                           not null,
    paymaccount_peny decimal(9, 2)
        constraint DF_PAYING_SERV_paymaccount_peny default 0 not null,
    commission       decimal(9, 2)
        constraint DF_PAYING_SERV_commission default 0       not null,
    constraint PK_Paying_serv
        primary key (occ, service_id, sup_id, paying_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Оплата по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'услуга', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN',
     'paying_id'
go

exec sp_addextendedproperty 'MS_Description', N'сумма платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN',
     'value'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено пени', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN',
     'paymaccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'комиссия', 'SCHEMA', 'dbo', 'TABLE', 'Paying_serv', 'COLUMN',
     'commission'
go

