create table Service_units_counter
(
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id    varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_SERVICE_UNITS_COUNTER
        primary key (service_id, unit_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Еденицы измерения по счетчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Service_units_counter'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Service_units_counter',
     'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код еденицы измерения', 'SCHEMA', 'dbo', 'TABLE',
     'Service_units_counter', 'COLUMN', 'unit_id'
go

