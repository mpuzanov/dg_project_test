create table Services
(
    id                   varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_SERVICES
            primary key,
    name                 varchar(100)                         not null collate SQL_Latin1_General_CP1251_CI_AS,
    short_name           varchar(20)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    service_no           smallint                             not null,
    service_type         smallint
        constraint DF_SERVICES_service_type default 1         not null,
    is_koef              bit
        constraint DF_SERVICES_is_koef default 0              not null,
    is_subsid            bit
        constraint DF_SERVICES_is_subsid default 0            not null,
    is_norma             bit
        constraint DF_SERVICES_is_norma default 0             not null,
    num_colon            smallint
        constraint DF_SERVICES_num_colon default 1            not null,
    is_counter           bit
        constraint DF_SERVICES_is_counter default 0           not null,
    service_kod          smallint
        constraint DF_SERVICES_counter_no default 0           not null
        constraint CK_SERVICES
            check ([service_kod] >= 0 AND [service_kod] <= 9),
    var_subsid_only      bit
        constraint DF_SERVICES_var_subsid_only default 0      not null,
    sort_no              smallint
        constraint DF_SERVICES_sort_no default 0              not null,
    is_paym              bit
        constraint DF_SERVICES_is_paym default 1              not null,
    is_peny              bit
        constraint DF_SERVICES_is_peny default 1              not null,
    serv_from            varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    is_build             bit
        constraint DF_SERVICES_is_build default 0             not null,
    is_build_serv        varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    sort_paym            smallint
        constraint DF_SERVICES_sort_paym default 0            not null,
    serv_vid             varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    is_koef_up           bit
        constraint DF_SERVICES_is_koef_up default 0           not null,
    no_export_volume_gis bit
        constraint DF_SERVICES_no_export_volume_gis default 0 not null,
    unit_id_default      varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit            smalldatetime
)
go

exec sp_addextendedproperty 'MS_Description', N'Услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services'
go

exec sp_addextendedproperty 'MS_Description', N'Код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Короткое название', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'short_name'
go

exec sp_addextendedproperty 'MS_Description', N'Номер услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'service_no'
go

exec sp_addextendedproperty 'MS_Description', N'Тип услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'service_type'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета с коэф-том', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_koef'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_subsid'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета нормы', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'is_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Номер колонки в квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'num_colon'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта по счётчикам', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_counter'
go

exec sp_addextendedproperty 'MS_Description', N'Признак возможного расчёта только субсидии', 'SCHEMA', 'dbo', 'TABLE',
     'Services', 'COLUMN', 'var_subsid_only'
go

exec sp_addextendedproperty 'MS_Description', N'Поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'sort_no'
go

exec sp_addextendedproperty 'MS_Description', N'Признак начисления услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Текущая услуга зависит от этих услуг', 'SCHEMA', 'dbo', 'TABLE',
     'Services', 'COLUMN', 'serv_from'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовые нужды', 'SCHEMA', 'dbo', 'TABLE', 'Services', 'COLUMN',
     'is_build'
go

exec sp_addextendedproperty 'MS_Description', N'Текущая общедомовая услуга зависит от этой услуги', 'SCHEMA', 'dbo',
     'TABLE', 'Services', 'COLUMN', 'is_build_serv'
go

exec sp_addextendedproperty 'MS_Description', N'Сортировка для расчёта (для расчёта от зависимых услуг)', 'SCHEMA',
     'dbo', 'TABLE', 'Services', 'COLUMN', 'sort_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Вид коммунального ресурса', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'serv_vid'
go

exec sp_addextendedproperty 'MS_Description', N'Признак повышающего коэффициента', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'is_koef_up'
go

exec sp_addextendedproperty 'MS_Description', N'Не экпортировать объём(площадь) по услуге в ГИС ЖКХ', 'SCHEMA', 'dbo',
     'TABLE', 'Services', 'COLUMN', 'no_export_volume_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Единица измерения по умолчанию', 'SCHEMA', 'dbo', 'TABLE', 'Services',
     'COLUMN', 'unit_id_default'
go

