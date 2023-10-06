create table Suppliers_types
(
    id                   int identity
        constraint PK_SUPPLIERS_TYPES
            primary key,
    tip_id               smallint                             not null
        constraint FK_SUPPLIERS_TYPES_OCCUPATION_TYPES
            references Occupation_Types,
    sup_id               int                                  not null
        constraint FK_SUPPLIERS_TYPES_SUPPLIERS_ALL
            references Suppliers_all,
    paym_blocked         bit
        constraint DF_SUPPLIERS_TYPES_paym_blocked default 0  not null,
    service_id           varchar(10)
        constraint DF_SUPPLIERS_TYPES_service_id default ''   not null collate SQL_Latin1_General_CP1251_CI_AS,
    add_blocked          bit
        constraint DF_SUPPLIERS_TYPES_add_blocked default 0   not null,
    lastday_without_peny smallint
        constraint DF_SUPPLIERS_TYPES_peny_last_day default 0 not null,
    is_peny              char
        constraint DF_SUPPLIERS_TYPES_is_peny2 default 'D'    not null collate SQL_Latin1_General_CP1251_CI_AS,
    penalty_metod        smallint,
    PenyBeginDolg        decimal(9, 2)
        constraint DF_SUPPLIERS_TYPES_BeginDolgPeny default 0 not null,
    LastPaymDay          smalldatetime,
    export_gis           bit
        constraint DF_SUPPLIERS_TYPES_export_gis default 1    not null,
    print_blocked        bit
        constraint DF_SUPPLIERS_TYPES_print_blocked default 0 not null,
    sub12_blocked        bit
        constraint DF_SUPPLIERS_TYPES_sub12_blocked default 0 not null,
    constraint CK_SUPPLIERS_TYPES
        check ([is_peny] = 'Y' AND [penalty_metod] IS NOT NULL OR [is_peny] = 'N' OR [is_peny] = 'D')
)
go

exec sp_addextendedproperty 'MS_Description', N'Настройка начислений по поставщикам услуг', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка начислений', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types',
     'COLUMN', 'paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчёта разовых', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types', 'COLUMN', 'add_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты до расчёта пени', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types', 'COLUMN', 'lastday_without_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени Y-Да, N - Нет, D - По умолчанию', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_types', 'COLUMN', 'is_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Метод расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types',
     'COLUMN', 'penalty_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Начальный долг для расчёта пени', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types', 'COLUMN', 'PenyBeginDolg'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты поставщику по типу фонда', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_types', 'COLUMN', 'LastPaymDay'
go

exec sp_addextendedproperty 'MS_Description', N'Нет экспорту в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_types',
     'COLUMN', 'export_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать печать квитанций', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types', 'COLUMN', 'print_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать расчёт субсидии 12%', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_types', 'COLUMN', 'sub12_blocked'
go

