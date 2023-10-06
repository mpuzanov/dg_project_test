create table Suppliers_types_history
(
    fin_id        smallint                                            not null,
    tip_id        smallint                                            not null,
    sup_id        int                                                 not null,
    paym_blocked  bit                                                 not null,
    service_id    varchar(10)
        constraint DF_SUPPLIERS_TYPES_HISTORY_service_id default ''   not null collate SQL_Latin1_General_CP1251_CI_AS,
    add_blocked   bit                                                 not null,
    LastPaymDay   smalldatetime,
    print_blocked bit
        constraint DF_SUPPLIERS_TYPES_HISTORY_print_blocked default 0 not null,
    constraint PK_SUPPLIERS_TYPES_HISTORY
        primary key (fin_id, tip_id, sup_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Настройка начислений по поставщикам в истории', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_types_history'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types_history',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types_history',
     'COLUMN', 'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types_history',
     'COLUMN', 'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчётов ЖКУ', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types_history', 'COLUMN', 'paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types_history',
     'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчёта разовых', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types_history', 'COLUMN', 'add_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты поставщику по типу фонда', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_types_history', 'COLUMN', 'LastPaymDay'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка печати', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types_history',
     'COLUMN', 'print_blocked'
go

