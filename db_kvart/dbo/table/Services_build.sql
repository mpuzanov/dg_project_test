create table Services_build
(
    id                    int identity
        constraint PK_SERVICES_BUILD
            primary key,
    build_id              int                                          not null
        constraint FK_Services_build_Buildings
            references Buildings
            on delete cascade,
    service_id            varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Services_build_Services
            references Services
            on update cascade on delete cascade,
    service_name          varchar(50)                                  not null collate SQL_Latin1_General_CP1251_CI_AS,
    VSODER                bit
        constraint DF_SERVICES_BUILD_VSODER default 0                  not null,
    VYDEL                 bit
        constraint DF_SERVICES_BUILD_VYDEL default 0                   not null,
    owner_id              int,
    blocked_account_info  bit
        constraint DF_SERVICES_BUILD_blocked_account_info default 0    not null,
    is_koef_for_norma     bit
        constraint DF_SERVICES_BUILD_is_koef_for_norma default 0       not null,
    date_ras_start        smalldatetime,
    date_ras_end          smalldatetime,
    no_vozvrat            bit
        constraint DF_SERVICES_BUILD_no_vozvrat default 0              not null,
    paym_rasckidka_no     bit
        constraint DF_SERVICES_BUILD_paym_rasckidka_no default 0       not null,
    norma_kol             decimal(12, 6),
    koef                  smallmoney,
    service_name_gis      varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    is_export_pu          bit
        constraint DF_SERVICES_BUILD_is_export_pu default 1            not null,
    is_export_gis         bit
        constraint DF_SERVICES_BUILD_is_export_gis default 1           not null,
    build_total_sq        smallmoney,
    paym_blocked          bit
        constraint DF_Services_build_paym_blocked default 0            not null,
    blocked_kvit          bit
        constraint DF_Services_build_blocked_kvit default 0            not null,
    counter_metod         smallint
        constraint DF_Services_build_counter_metod default (-1)        not null
        constraint FK_Services_build_Counter_metod
            references Counter_metod,
    blocked_norma_kvit    bit
        constraint DF_Services_build_blocked_norma_kvit default 0      not null,
    comments              varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit             smalldatetime,
    user_edit             smallint,
    is_direct_contract    bit
        constraint DF_Services_build_is_direct_contract default 0      not null,
    blocked_counter_kvit  bit
        constraint DF_Services_build_blocked_counter_kvit default 0    not null,
    soi_isTotalSq_Pasport char
        constraint DF_Services_build_soi_isTotalSq_Pasport default 'D' not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Настройка услуг по дому', 'SCHEMA', 'dbo', 'TABLE', 'Services_build'
go

exec sp_addextendedproperty 'MS_Description', N'код записи', 'SCHEMA', 'dbo', 'TABLE', 'Services_build', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код дома', 'SCHEMA', 'dbo', 'TABLE', 'Services_build', 'COLUMN',
     'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Services_build', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование услуги для квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'service_name'
go

exec sp_addextendedproperty 'MS_Description', N'входит в содержание жилья', 'SCHEMA', 'dbo', 'TABLE', 'Services_build',
     'COLUMN', 'VSODER'
go

exec sp_addextendedproperty 'MS_Description', N'выделенная строка в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'VYDEL'
go

exec sp_addextendedproperty 'MS_Description', N'код владельца(из этой таблицы)', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка справочной информации в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'blocked_account_info'
go

exec sp_addextendedproperty 'MS_Description', N'Применять коэффициент повышения по умолчанию', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'is_koef_for_norma'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Services_build',
     'COLUMN', 'date_ras_start'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Services_build',
     'COLUMN', 'date_ras_end'
go

exec sp_addextendedproperty 'MS_Description', N'Не делать автовозврата(перерасчёта по ПУ)', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'no_vozvrat'
go

exec sp_addextendedproperty 'MS_Description', N'Блокируем раскидку оплаты по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'paym_rasckidka_no'
go

exec sp_addextendedproperty 'MS_Description', N'норматив в доме по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Services_build',
     'COLUMN', 'norma_kol'
go

exec sp_addextendedproperty 'MS_Description', N'Коэффициент по услуге для расчётов (например за найм)', 'SCHEMA', 'dbo',
     'TABLE', 'Services_build', 'COLUMN', 'koef'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование услуги в ГИС', 'SCHEMA', 'dbo', 'TABLE', 'Services_build',
     'COLUMN', 'service_name_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешён или нет экспорт приборов учёта', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'is_export_pu'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешён или нет выгрузка ПУ в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'is_export_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Общая площадь дома при расчете услуги', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'build_total_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчета по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Не показывать услугу в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'blocked_kvit'
go

exec sp_addextendedproperty 'MS_Description',
     N'(-1-по умолчанию; 0-не начислять,1-по норме,2-по среднему,3-по счетчику, 4-по общедомовому счётчику,5- по заданному значению kol, 6 - не использовать ППУ)',
     'SCHEMA', 'dbo', 'TABLE', 'Services_build', 'COLUMN', 'counter_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Не показывать норматив в квитанции по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'blocked_norma_kvit'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий по услуге для Картотеки', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'comments'
go

exec sp_addextendedproperty 'MS_Description', N'услуга на прямых расчетах поставщика', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'is_direct_contract'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка счетчиков в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Services_build', 'COLUMN', 'blocked_counter_kvit'
go

exec sp_addextendedproperty 'MS_Description',
     N'Признак  Y-Да, N - Нет, D - По умолчанию. Общую площадь для расчёта СОИ брать из площади дома по паспорту',
     'SCHEMA', 'dbo', 'TABLE', 'Services_build', 'COLUMN', 'soi_isTotalSq_Pasport'
go

