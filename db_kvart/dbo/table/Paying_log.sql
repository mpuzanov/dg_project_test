create table Paying_log
(
    id            int identity
        constraint PK_PAYMACCOUNT_LOG
            primary key,
    paying_id     int                                   not null,
    pack_id       int                                   not null,
    occ           int                                   not null,
    sup_id        int
        constraint DF_PAYMACCOUNT_LOG_sup_id default 0  not null,
    value         decimal(9, 2)
        constraint DF_PAYMACCOUNT_LOG_value default 0   not null,
    koef          decimal(16, 10),
    ostatok       decimal(9, 2),
    metod_name    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    metod_ostatok varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    msg_log       varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS,
    done          datetime
        constraint DF_PAYING_LOG_date default getdate() not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал редактирования пачек (АРМ Платежи)', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_log'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paying_log', 'COLUMN',
     'paying_id'
go

exec sp_addextendedproperty 'MS_Description', N'код пачки', 'SCHEMA', 'dbo', 'TABLE', 'Paying_log', 'COLUMN', 'pack_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Paying_log', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paying_log', 'COLUMN',
     'sup_id'
go

