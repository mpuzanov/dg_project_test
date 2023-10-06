create table Services_types
(
    id                   int identity
        constraint PK_SERVICES_TYPES
            primary key,
    tip_id               smallint                                   not null
        constraint FK_Services_types_Occupation_Types
            references Occupation_Types,
    service_id           varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Services_types_Services
            references Services
            on update cascade,
    service_name         varchar(50)                                not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_load_value        bit
        constraint DF_SERVICES_TYPES_is_load_value default 0        not null,
    VSODER               bit
        constraint DF_SERVICES_TYPES_VSODER default 0               not null,
    VYDEL                bit
        constraint DF_SERVICES_TYPES_VYDEL default 0                not null,
    owner_id             int,
    paym_rasckidka_no    bit
        constraint DF_SERVICES_TYPES_paym_rsckidka_no default 0     not null,
    paym_blocked         bit
        constraint DF_SERVICES_TYPES_paym_blocked default 0         not null,
    overpayment_blocked  bit
        constraint DF_SERVICES_TYPES_overpayment_blocked default 0  not null,
    short_id             varchar(4) collate SQL_Latin1_General_CP1251_CI_AS,
    overpayment_only     bit
        constraint DF_SERVICES_TYPES_overpayment_only default 0     not null,
    blocked_account_info bit
        constraint DF_SERVICES_TYPES_blocked_account_info default 0 not null,
    sup_id               int,
    service_name_gis     varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    date_paying_start    smalldatetime,
    check_blocked        bit
        constraint DF_SERVICES_TYPES_check_blocked default 0        not null,
    date_ras_start       smalldatetime,
    date_ras_end         smalldatetime,
    service_name_full    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    group_kvit_id        int
        constraint FK_Services_types_Group_kvit
            references Group_kvit,
    sort_no              smallint,
    blocked_kvit         bit
        constraint DF_Services_types_blocked_kvit default 0         not null,
    blocked_norma_kvit   bit
        constraint DF_Services_types_blocked_norma_kvit default 0   not null,
    comments             varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit            smalldatetime,
    user_edit            smallint
)
go

exec sp_addextendedproperty 'MS_Description', N'Настройка услуг по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование услуги для квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'service_name'
go

exec sp_addextendedproperty 'MS_Description', N'если 1 - то по этой услуге разрешена загрузка начислений(без расчёта)',
     'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN', 'is_load_value'
go

exec sp_addextendedproperty 'MS_Description', N'входит в содержание жилья', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'VSODER'
go

exec sp_addextendedproperty 'MS_Description', N'выделенная строка в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'VYDEL'
go

exec sp_addextendedproperty 'MS_Description', N'id владельца услуги (для группировки)', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокируем раскидку оплаты по услуге по типу фонда', 'SCHEMA', 'dbo',
     'TABLE', 'Services_types', 'COLUMN', 'paym_rasckidka_no'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчёта по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка переплаты(переплаты не должно быть)', 'SCHEMA', 'dbo',
     'TABLE', 'Services_types', 'COLUMN', 'overpayment_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Кор. название для квитанций', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'short_id'
go

exec sp_addextendedproperty 'MS_Description', N'Переплату сюда', 'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN',
     'overpayment_only'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка справочной информации в квитанции по услуге', 'SCHEMA',
     'dbo', 'TABLE', 'Services_types', 'COLUMN', 'blocked_account_info'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Services_types', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование услуги в ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'service_name_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Дата начала оплаты услуги по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'date_paying_start'
go

exec sp_addextendedproperty 'MS_Description', N'Запрет выгрузки услуги для чеков', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'check_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'date_ras_start'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'date_ras_end'
go

exec sp_addextendedproperty 'MS_Description', N'Полное наименование услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'service_name_full'
go

exec sp_addextendedproperty 'MS_Description', N'код группы в квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'group_kvit_id'
go

exec sp_addextendedproperty 'MS_Description', N'поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Services_types',
     'COLUMN', 'sort_no'
go

exec sp_addextendedproperty 'MS_Description', N'Не показывать услугу в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'blocked_kvit'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка показа норматива в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'blocked_norma_kvit'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий по услуги для Картотеки', 'SCHEMA', 'dbo', 'TABLE',
     'Services_types', 'COLUMN', 'comments'
go

