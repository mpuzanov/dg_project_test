create table Payings
(
    id               int identity
        constraint PK_PAYINGS
            primary key,
    pack_id          int
        constraint FK_PAYINGS_PAYDOC_PACKS
            references Paydoc_packs
            on update cascade,
    occ              int                                 not null,
    fin_id           smallint,
    service_id       varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_PAYINGS_SERVICES
            references Services
            on update cascade,
    value            decimal(9, 2)                       not null,
    checked          bit
        constraint DF_PAYINGS_checked default 0          not null,
    forwarded        bit
        constraint DF_PAYINGS_forwarded default 0        not null,
    scan             smallint
        constraint DF_PAYINGS_scan default 0             not null,
    paymaccount_peny decimal(9, 2)
        constraint DF_PAYINGS_paymaccount_peny default 0 not null,
    sup_id           int
        constraint DF_PAYINGS_sup_id default 0           not null,
    dog_int          int,
    filedbf_id       int,
    commission       decimal(9, 2)
        constraint DF_PAYINGS_commission default 0       not null,
    occ_sup          int,
    paying_vozvrat   int,
    peny_save        bit
        constraint DF_PAYINGS_peny_save default 0        not null,
    paying_manual    bit
        constraint DF_PAYINGS_paying_manual default 0    not null,
    paying_uid       uniqueidentifier,
    comment          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Платежи', 'SCHEMA', 'dbo', 'TABLE', 'Payings'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'номер пачки', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'pack_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'сумма платежа', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'проверен(сумма по пачке)', 'SCHEMA', 'dbo', 'TABLE', 'Payings',
     'COLUMN', 'checked'
go

exec sp_addextendedproperty 'MS_Description', N'признак закрытия платежа(пачки)', 'SCHEMA', 'dbo', 'TABLE', 'Payings',
     'COLUMN', 'forwarded'
go

exec sp_addextendedproperty 'MS_Description', N'с помощью чего введен', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN',
     'scan'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено пени', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN',
     'paymaccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'код договора', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'dog_int'
go

exec sp_addextendedproperty 'MS_Description', N'код файла (bank_dbf)', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN',
     'filedbf_id'
go

exec sp_addextendedproperty 'MS_Description', N'комиссия', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN', 'commission'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Payings', 'COLUMN',
     'occ_sup'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа на основе которого - возврат', 'SCHEMA', 'dbo', 'TABLE',
     'Payings', 'COLUMN', 'paying_vozvrat'
go

exec sp_addextendedproperty 'MS_Description', N'Оплату пени взять как занесено', 'SCHEMA', 'dbo', 'TABLE', 'Payings',
     'COLUMN', 'peny_save'
go

exec sp_addextendedproperty 'MS_Description', N'Ручная раскидка платежей', 'SCHEMA', 'dbo', 'TABLE', 'Payings',
     'COLUMN', 'paying_manual'
go

