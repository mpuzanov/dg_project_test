create table Services_type_counters
(
    tip_id                     smallint                                           not null
        constraint FK_SERVICES_TYPE_COUNTERS_OCCUPATION_TYPES
            references Occupation_Types,
    service_id                 varchar(10)                                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    counter_metod              smallint
        constraint DF_Services_type_counters_counter_metod default (-1)           not null
        constraint FK_Services_type_counters_Counter_metod
            references Counter_metod,
    kol                        decimal(9, 4)
        constraint DF_SERVICES_TYPE_COUNTERS_kol default 0                        not null,
    service_kol                varchar(10)
        constraint DF_SERVICES_TYPE_COUNTERS_service_kol default ''               not null collate SQL_Latin1_General_CP1251_CI_AS,
    no_counter_raschet         bit
        constraint DF_SERVICES_TYPE_COUNTERS_no_counter_raschet default 0         not null,
    no_vozvrat                 bit
        constraint DF_SERVICES_TYPE_COUNTERS_no_vozvrat default 0                 not null,
    no_export                  bit
        constraint DF_SERVICES_TYPE_COUNTERS_no_export default 0                  not null,
    no_export_gis              bit
        constraint DF_SERVICES_TYPE_COUNTERS_no_export_gis default 0              not null,
    pkoef_rasch_dpoverka       smallint
        constraint CK_SERVICES_TYPE_COUNTERS
            check ([pkoef_rasch_dpoverka] IS NULL OR [pkoef_rasch_dpoverka] < 0),
    koef                       decimal(9, 4)
        constraint DF_Services_type_counters_koef default 1                       not null,
    is_counter_add_balance     bit
        constraint DF_Services_type_counters_is_counter_add_balance default 0     not null,
    is_blocked_ppu_periodcheck bit
        constraint DF_Services_type_counters_is_blocked_ppu_periodcheck default 0 not null,
    constraint PK_SERVICE_TYPE_COUNTERS
        primary key (tip_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Методы расчета по счётчикам без показаний по услугам по типу фонда',
     'SCHEMA', 'dbo', 'TABLE', 'Services_type_counters'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Services_type_counters',
     'COLUMN', 'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services_type_counters',
     'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description',
     N'(-1-по умолчанию; 0-не начислять,1-по норме,2-по среднему,3-по счетчику, 4-по общедомовому счётчику,5- по заданному значению kol, 6 - не использовать ППУ)',
     'SCHEMA', 'dbo', 'TABLE', 'Services_type_counters', 'COLUMN', 'counter_metod'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во (объём) по услуге ПУ', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'зависит от услуги (её код)', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'service_kol'
go

exec sp_addextendedproperty 'MS_Description', N'Не расчитывать по показаниям счётчиков если есть', 'SCHEMA', 'dbo',
     'TABLE', 'Services_type_counters', 'COLUMN', 'no_counter_raschet'
go

exec sp_addextendedproperty 'MS_Description', N'не делать автовозврат по нормативу', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'no_vozvrat'
go

exec sp_addextendedproperty 'MS_Description', N'Не выгружать ПУ по услуге и типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'no_export'
go

exec sp_addextendedproperty 'MS_Description', N'Не делать экспорт в ГИС', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'no_export_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Начислять ПовКоэф. если дата поверки истекла более X мес', 'SCHEMA',
     'dbo', 'TABLE', 'Services_type_counters', 'COLUMN', 'pkoef_rasch_dpoverka'
go

exec sp_addextendedproperty 'MS_Description', N'Коэффициент по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'koef'
go

exec sp_addextendedproperty 'MS_Description', N'Вычисление остатков по счётчикам и по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Services_type_counters', 'COLUMN', 'is_counter_add_balance'
go

exec sp_addextendedproperty 'MS_Description', N'блокировать ввод показаний у истекших ипу (по периоду поверки)',
     'SCHEMA', 'dbo', 'TABLE', 'Services_type_counters', 'COLUMN', 'is_blocked_ppu_periodcheck'
go

