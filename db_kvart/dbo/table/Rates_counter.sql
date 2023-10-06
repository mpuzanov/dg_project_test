create table Rates_counter
(
    id         int identity
        constraint PK_RATES_COUNTER
            primary key,
    fin_id     smallint                                 not null,
    tipe_id    smallint                                 not null,
    service_id varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id    varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_RATES_COUNTER_UNITS
            references Units
            on update cascade,
    mode_id    int
        constraint DF_RATES_COUNTER_mode_id default 0   not null,
    source_id  int
        constraint DF_RATES_COUNTER_source_id default 0 not null,
    tarif      decimal(10, 4)                           not null,
    user_edit  smallint,
    date_edit  smalldatetime,
    extr_tarif decimal(9, 2),
    full_tarif decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Тарифы по счетчикам', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'тип жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'tipe_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'еденицы измерения', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'unit_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'Тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN', 'tarif'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Сверх нормативный тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter',
     'COLUMN', 'extr_tarif'
go

exec sp_addextendedproperty 'MS_Description', N'Полный тариф', 'SCHEMA', 'dbo', 'TABLE', 'Rates_counter', 'COLUMN',
     'full_tarif'
go

