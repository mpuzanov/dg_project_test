create table Rates
(
    id          int identity
        constraint PK_RATES
            primary key,
    finperiod   smallint
        constraint DF_RATES_finperiod default 1      not null,
    tipe_id     smallint
        constraint DF_RATES_tipe_id default 1        not null
        constraint FK_RATES_OCCUPATION_TYPES
            references Occupation_Types
            on update cascade on delete cascade,
    service_id  varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    mode_id     int                                  not null,
    source_id   int                                  not null
        constraint FK_RATES_SUPPLIERS
            references Suppliers (id)
            on update cascade,
    status_id   varchar(10)
        constraint DF_RATES_status_id default 'откр' not null collate SQL_Latin1_General_CP1251_CI_AS,
    proptype_id varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    value       decimal(10, 4)
        constraint DF_Rates_value default 0          not null,
    full_value  decimal(10, 4)
        constraint DF_Rates_full_value default 0     not null,
    extr_value  decimal(10, 4)
        constraint DF_Rates_extr_value default 0     not null,
    user_edit   smallint,
    date_edit   smalldatetime
)
go

exec sp_addextendedproperty 'MS_Description', N'Тарифы', 'SCHEMA', 'dbo', 'TABLE', 'Rates'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'finperiod'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN', 'tipe_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'режим потребления', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'режим поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'статус лицевого счета', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'status_id'
go

exec sp_addextendedproperty 'MS_Description', N'статус квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'proptype_id'
go

exec sp_addextendedproperty 'MS_Description', N'Базовый тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'Полный тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN', 'full_value'
go

exec sp_addextendedproperty 'MS_Description', N'Сверх нормативный тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'extr_value'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Rates', 'COLUMN',
     'date_edit'
go

