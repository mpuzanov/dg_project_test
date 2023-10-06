create table Occupation_Types
(
    id                              smallint                                                            not null
        constraint PK_OCCUPATIONS_TYPES
            primary key,
    name                            varchar(50)                                                         not null collate SQL_Latin1_General_CP1251_CI_AS,
    payms_value                     bit
        constraint DF_OCCUPATION_TYPES_payms_value default 1                                            not null,
    fin_id                          smallint
        constraint DF_OCCUPATION_TYPES_fin_current default 0                                            not null,
    state_id                        char(4)
        constraint DF_OCCUPATION_TYPES_state_id default 'норм'                                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    id_accounts                     int
        constraint DF_OCCUPATION_TYPES_id_accounts default 1                                            not null
        constraint FK_Occupation_Types_Reports_account
            references Reports_account,
    id_barcode                      smallint
        constraint DF_OCCUPATION_TYPES_id_barcode default 0                                             not null,
    penalty_calc_tip                bit
        constraint DF_OCCUPATION_TYPES_penalty_calc default 1                                           not null,
    penalty_metod                   smallint
        constraint DF_OCCUPATION_TYPES_penalty_metod default 1                                          not null,
    fincloseddata                   smalldatetime,
    PaymClosedData                  smalldatetime,
    PaymClosed                      bit
        constraint DF_OCCUPATION_TYPES_PaymClosed default 0                                             not null,
    start_date                      smalldatetime,
    LastPaymDay                     smalldatetime,
    adres                           varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    fio                             varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    telefon                         varchar(70) collate SQL_Latin1_General_CP1251_CI_AS,
    bank_account                    int,
    laststr1                        varchar(70) collate SQL_Latin1_General_CP1251_CI_AS,
    counter_metod                   smallint,
    counter_votv_ras                bit
        constraint DF_OCCUPATION_TYPES_counter_votv_ras default 1,
    laststr2                        varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS,
    occ_min                         int,
    occ_max                         int,
    occ_prefix_tip                  varchar(3)
        constraint DF_OCCUPATION_TYPES_occ_add default ''                                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    paym_order                      nvarchar(100)
        constraint DF_OCCUPATION_TYPES_paym_order default N'Пред.Начисл;Задолженность;Пени;Тек.Начисл.' not null collate SQL_Latin1_General_CP1251_CI_AS,
    paym_order_metod                varchar(10)
        constraint DF_OCCUPATION_TYPES_paym_order_metod_1 default 'пени2' collate SQL_Latin1_General_CP1251_CI_AS,
    lastpaym                        smallint
        constraint DF_OCCUPATION_TYPES_LastPaym default 31,
    namesoderhousing                varchar(30)
        constraint DF_OCCUPATION_TYPES_NameSoderHousing default 'С.жилья в т.ч:' collate SQL_Latin1_General_CP1251_CI_AS,
    logo                            varbinary(max),
    SaldoEditTrue                   bit
        constraint DF_OCCUPATION_TYPES_SaldoEditTrue default 1                                          not null,
    email                           varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    paymaccount_minus               bit
        constraint DF_OCCUPATION_TYPES_paymaccount_minus default 0                                      not null,
    saldo_rascidka                  bit
        constraint DF_OCCUPATION_TYPES_saldo_rascidka default 0                                         not null,
    counter_add_ras_norma           bit
        constraint DF_OCCUPATION_TYPES_counter_add_ras_norma default 1                                  not null,
    synonym_name                    varchar(150) collate SQL_Latin1_General_CP1251_CI_AS,
    inn                             varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    people0_counter_norma           bit
        constraint DF_OCCUPATION_TYPES_people0_counter_norma default 0                                  not null,
    PaymRaskidkaAlways              bit
        constraint DF_OCCUPATION_TYPES_PaymRaskidkaAlways default 0                                     not null,
    ogrn                            varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    comments                        varchar(200) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_org_for_account             varchar(50)
        constraint DF_OCCUPATION_TYPES_tip_org_for_account default 'Управляющая организация' collate SQL_Latin1_General_CP1251_CI_AS,
    tip_paym_blocked                bit,
    tip_details                     varchar(800) collate SQL_Latin1_General_CP1251_CI_AS,
    counter_votv_norma              bit
        constraint DF_OCCUPATION_TYPES_counter_votv_norma default 0,
    ras_paym_fin_new                bit
        constraint DF_OCCUPATION_TYPES_ras_paym_fin_new default 0,
    people_reg_blocked              bit
        constraint DF_OCCUPATION_TYPES_people_reg_blocked default 0,
    kpp                             varchar(9) collate SQL_Latin1_General_CP1251_CI_AS,
    is_PrintFioPrivat               bit
        constraint DF_OCCUPATION_TYPES_is_PrintFioPrivat default 0                                      not null,
    is_ValueBuildMinus              bit
        constraint DF_OCCUPATION_TYPES_is_ValueBuildMinus default 0                                     not null,
    is_2D_Code                      bit
        constraint DF_OCCUPATION_TYPES_is_2D_Code default 1                                             not null,
    raschet_no                      bit
        constraint DF_OCCUPATION_TYPES_raschet_no default 0                                             not null,
    raschet_agri                    bit
        constraint DF_OCCUPATION_TYPES_raschet_agri default 0                                           not null,
    is_counter_cur_tarif            bit
        constraint DF_OCCUPATION_TYPES_is_counter_cur_tarif default 0                                   not null,
    is_paying_saldo_no_paid         bit
        constraint DF_OCCUPATION_TYPES_is_paying_saldo_no_paid default 0                                not null,
    is_not_allocate_economy         bit
        constraint DF_OCCUPATION_TYPES_is_not_allocate_economy default 0                                not null,
    telefon_pasp                    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    barcode_charset                 char
        constraint DF_OCCUPATION_TYPES_barcode_charset default 2                                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    ras_no_counter_poverka          bit
        constraint DF_OCCUPATION_TYPES_counter_poverka_no_ras default 0                                 not null,
    only_pasport                    bit
        constraint DF_OCCUPATION_TYPES_only_pasport default 0                                           not null,
    only_value                      bit
        constraint DF_OCCUPATION_TYPES_only_value default 0                                             not null,
    account_rich                    varchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    is_counter_add_balance          bit
        constraint DF_OCCUPATION_TYPES_is_counter_add_balance default 0                                 not null,
    web_site                        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    adres_fact                      varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    rezhim_work                     varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    email_subscribe                 varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    PenyBeginDolg                   decimal(9, 2)
        constraint DF_OCCUPATION_TYPES_BeginDolgPeny default 0                                          not null,
    tip_occ                         smallint
        constraint DF_OCCUPATION_TYPES_tip_occ default 1                                                not null,
    blocked_counter_add_ras_norma   bit
        constraint DF_OCCUPATION_TYPES_blocked_counter_add_ras_norma default 0,
    export_gis                      bit
        constraint DF_OCCUPATION_TYPES_export_gis default 1                                             not null,
    export_gis_occ_prefix           bit
        constraint DF_Occupation_Types_export_gis_occ_prefix default 1                                  not null,
    bank_format_out                 smallint
        constraint FK_OCCUPATION_TYPES_BANK_FORMAT_OUT
            references Bank_format_out,
    bank_file_out                   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    watermark_text                  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    watermark_dolg_mes              smallint,
    is_only_quarter                 bit,
    is_calc_subs12                  bit,
    tip_nalog                       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    is_cash_serv                    bit
        constraint DF_OCCUPATION_TYPES_is_cash_serv default 0                                           not null,
    peny_paym_blocked               bit
        constraint DF_OCCUPATION_TYPES_tip_paym_peny_blocked default 0                                  not null,
    tip_uid                         uniqueidentifier,
    soi_metod_calc                  varchar(10)
        constraint DF_Occupation_Types_metod_calc_soi default 'CALC_TARIF'                              not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_Occupation_Types
            check ([soi_metod_calc] = 'CALC_KOL' OR [soi_metod_calc] = 'CALC_TARIF'),
    soi_isTotalSq_Pasport           bit
        constraint DF_Occupation_Types_soi_isTotalSq_Pasport default 0                                  not null,
    odn_big_norma                   bit,
    soi_votv_fact                   bit
        constraint DF_Occupation_Types_soi_votv_fact default 0                                          not null,
    ppu_value_allow_negativ         bit
        constraint DF_Occupation_Types_ppu_value_allow_negativ default 0                                not null,
    is_peny_blocked_total_sq_empty  bit
        constraint DF_Occupation_Types_peny_blocked_total_sq_empty default 0                            not null,
    is_peny_current_stavka_cb       bit
        constraint DF_Occupation_Types_is_peny_current_stavka_cb default 1                              not null,
    count_month_avg_counter         smallint
        constraint DF_Occupation_Types_count_month_avg_counter default 36                               not null,
    is_peny_serv                    bit
        constraint DF_Occupation_Types_is_peny_serv default 0                                           not null,
    peny_service_id                 varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    decimal_round                   int
        constraint DF_Occupation_Types_decimal_round default 2                                          not null,
    commission_bank_code            varchar(10) default ''                                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    soi_is_transfer_economy         bit
        constraint DF_Occupation_Types_soi_is_transfer_economy default 0                                not null,
    is_vozvrat_votv_sum             bit
        constraint DF_Occupation_Types_is_vozvrat_votv_sum default 0                                    not null,
    soi_boiler_only_hvs             bit
        constraint DF_Occupation_Types_soi_boiler_without_gvs default 0                                 not null,
    is_export_gis_without_paid      bit
        constraint DF_Occupation_Types_is_unload_paid_minus default 0                                   not null,
    set_start_day_period_dolg       bit
        constraint DF_Occupation_Types_set_start_day_period_dolg default 0                              not null,
    is_recom_for_payment            bit
        constraint DF_Occupation_Types_is_recom_for_payment default 0                                   not null,
    last_paym_day_count_payments    smallint
        constraint DF_Occupation_Types_LastPaymDayCountPayments default 1                               not null,
    is_epd_saldo                    bit
        constraint DF_Occupation_Types_is_epd_saldo default 0                                           not null,
    count_min_month_for_avg_counter smallint
        constraint DF_Occupation_Types_count_min_month_for_avg_value default 0                          not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Признак начисления', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'payms_value'
go

exec sp_addextendedproperty 'MS_Description', N'Текущий финансовый период', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'режим работы по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'state_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'penalty_calc_tip'
go

exec sp_addextendedproperty 'MS_Description', N'метод расчета пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'penalty_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Дата закрытия фин. периода', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'fincloseddata'
go

exec sp_addextendedproperty 'MS_Description', N'Дата закрытия платёжного периода', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'PaymClosedData'
go

exec sp_addextendedproperty 'MS_Description', N'Признак закрытия платёжного периода', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'PaymClosed'
go

exec sp_addextendedproperty 'MS_Description', N'Последний закрытый платёжный день для квитанций', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'LastPaymDay'
go

exec sp_addextendedproperty 'MS_Description', N'адрес организации', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'adres'
go

exec sp_addextendedproperty 'MS_Description', N'телефон организации', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'telefon'
go

exec sp_addextendedproperty 'MS_Description', N'код банковского счёта', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'метод расчета по ПУ (по умолчанию)', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'counter_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Добавление числа к лицевому счёту', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'occ_prefix_tip'
go

exec sp_addextendedproperty 'MS_Description',
     N' Метод погашения оплаты пени(пени1-Погашение пени, затем услуг; пени2-оплата услуг, затем пени)', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'paym_order_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Логотип управляющей компании', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'logo'
go

exec sp_addextendedproperty 'MS_Description', N'Формировать отрицательные оплаты пре переплате', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'paymaccount_minus'
go

exec sp_addextendedproperty 'MS_Description', N'признак возможности раскидки сальдо', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'saldo_rascidka'
go

exec sp_addextendedproperty 'MS_Description', N'Автоматический перерасчёт по счётчикам по норме', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'counter_add_ras_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование для документов', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'synonym_name'
go

exec sp_addextendedproperty 'MS_Description', N'Если нет людей использовать нормативы по счётчикам', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'people0_counter_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Всегда раскидывать (заново) платежи по услугам', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'PaymRaskidkaAlways'
go

exec sp_addextendedproperty 'MS_Description', N'тип организации в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'tip_org_for_account'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка оплаты по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'tip_paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительные реквизиты организации для печати в квитанции', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'tip_details'
go

exec sp_addextendedproperty 'MS_Description', N'Расчёт Водоотведения по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'counter_votv_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Распределять платежи после закрытия платёжного периода в новом',
     'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'ras_paym_fin_new'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать регистрацию граждан', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'people_reg_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'код постановки на учёт', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'kpp'
go

exec sp_addextendedproperty 'MS_Description', N'Печать собственников в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_PrintFioPrivat'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешить расчёт общедомовых услуг с минусом', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_ValueBuildMinus'
go

exec sp_addextendedproperty 'MS_Description', N'Возможно создание двух-мерных штрих-кодов', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_2D_Code'
go

exec sp_addextendedproperty 'MS_Description', N'Признак отмены ночного(группового) перерасчёта', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'raschet_no'
go

exec sp_addextendedproperty 'MS_Description', N'Расчитывать ХВС по сельхоз. животным', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'raschet_agri'
go

exec sp_addextendedproperty 'MS_Description', N'Брать текущий тариф для расчёту по счётчикам, а не усредненный',
     'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'is_counter_cur_tarif'
go

exec sp_addextendedproperty 'MS_Description', N'Не учитывать тек.начисление при оплате', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_paying_saldo_no_paid'
go

exec sp_addextendedproperty 'MS_Description', N'Не распределять экономию по ОДН', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_not_allocate_economy'
go

exec sp_addextendedproperty 'MS_Description', N'Телефон у паспортистов', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'telefon_pasp'
go

exec sp_addextendedproperty 'MS_Description', N'Кодировка данных в штрих-коде', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'barcode_charset'
go

exec sp_addextendedproperty 'MS_Description', N'Запрет расчёта по счётчикам с истёкшим сроком поверки', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'ras_no_counter_poverka'
go

exec sp_addextendedproperty 'MS_Description', N'ведение только паспортного стола', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'only_pasport'
go

exec sp_addextendedproperty 'MS_Description', N'ведение только расчётов', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'only_value'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительный текст или таблица в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'account_rich'
go

exec sp_addextendedproperty 'MS_Description', N'Расчёт остатков по счётчикам и по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_counter_add_balance'
go

exec sp_addextendedproperty 'MS_Description', N'веб-сайт', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN',
     'web_site'
go

exec sp_addextendedproperty 'MS_Description', N'фактический адрес', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'adres_fact'
go

exec sp_addextendedproperty 'MS_Description', N'режим работы организации(для квитанции)', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'rezhim_work'
go

exec sp_addextendedproperty 'MS_Description', N'Email организации для рассылок', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'email_subscribe'
go

exec sp_addextendedproperty 'MS_Description', N'Начальный долг для расчёта пени', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'PenyBeginDolg'
go

exec sp_addextendedproperty 'MS_Description', N'Тип лиц.счетов: 1-ЛС УО, 2-ЛС РСО, 3-ЛС КР', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'tip_occ'
go

exec sp_addextendedproperty 'MS_Description',
     N'Автоматический перерасчет по внутр. счётчикам. Всё что уже расчитано оставить и более не считать', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'blocked_counter_add_ras_norma'
go

exec sp_addextendedproperty 'MS_Description', N'признак разрешения выгрузки в ГИС', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'export_gis'
go

exec sp_addextendedproperty 'MS_Description',
     N'признаки выгрузки в ГИС ЖКХ лицевых с префиксом (подставных для квитанции)', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'export_gis_occ_prefix'
go

exec sp_addextendedproperty 'MS_Description', N'код формата с файлом задолженности в банк по умолчанию', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'bank_format_out'
go

exec sp_addextendedproperty 'MS_Description', N'формат наименования файла с  задолженностью', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'bank_file_out'
go

exec sp_addextendedproperty 'MS_Description', N'Текст водяного знака в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'watermark_text'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во мес. долга для печати водяного знака в квитанции', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'watermark_dolg_mes'
go

exec sp_addextendedproperty 'MS_Description', N'Только по квартальный расчет квартплаты (март,июнь,сентябрь,декабрь)',
     'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'is_only_quarter'
go

exec sp_addextendedproperty 'MS_Description', N'Признак возможности расчёта субсидии12', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_calc_subs12'
go

exec sp_addextendedproperty 'MS_Description', N'система налогообложения', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'COLUMN', 'tip_nalog'
go

exec sp_addextendedproperty 'MS_Description', N'Режим фискализации чеков по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_cash_serv'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка оплаты пени по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'peny_paym_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Метод расчета СОИ (CALC_TARIF или CALC_KOL)', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'soi_metod_calc'
go

exec sp_addextendedproperty 'MS_Description', N'Выбор метода расчёта СОИ', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types',
     'CONSTRAINT', 'CK_Occupation_Types'
go

exec sp_addextendedproperty 'MS_Description',
     N'Общую площадь для расчёта СОИ брать из площади дома по паспорту (иначе жилые + нежилые)', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'soi_isTotalSq_Pasport'
go

exec sp_addextendedproperty 'MS_Description', N'Признак возможности распределения ОДН больше нормы', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'odn_big_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Расчет водоотведения СОИ по факту', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'soi_votv_fact'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешить отрицательные начисления по показания ПУ', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'ppu_value_allow_negativ'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать расчет пени на лицевых без площади', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'is_peny_blocked_total_sq_empty'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета пени по текущей ставке ЦБ', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_peny_current_stavka_cb'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во месяцев для подсчета средних значений по счетчикам', 'SCHEMA',
     'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'count_month_avg_counter'
go

exec sp_addextendedproperty 'MS_Description', N'использовать отдельную услугу для пени', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_peny_serv'
go

exec sp_addextendedproperty 'MS_Description', N'Распределять пени только на заданную услугу', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'peny_service_id'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во знаков для округления начислений', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'decimal_round'
go

exec sp_addextendedproperty 'MS_Description', N'пара кодов 01,02.
Нечетная кодировка (01, 03 ….) комиссия взимается с потребителя, четная кодировка (02,04…..) комиссия с потребителя не взимается (внутрення за счет УК)',
     'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'commission_bank_code'
go

exec sp_addextendedproperty 'MS_Description', N'Перенос экономии по СОИ на следующий месяц', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'soi_is_transfer_economy'
go

exec sp_addextendedproperty 'MS_Description', N'Авто возврат Водоотведения = возвраты ХВС + ГВС', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'is_vozvrat_votv_sum'
go

exec sp_addextendedproperty 'MS_Description', N'Только расчет ХВС сои(без гвс сои) где есть бойлеры', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'soi_boiler_only_hvs'
go

exec sp_addextendedproperty 'MS_Description', N'Выгружать в ГИС ЖКХ услуги без начислений', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_export_gis_without_paid'
go

exec sp_addextendedproperty 'MS_Description', N'устанавливать первый день месяца - как ДЕНЬ ДОЛГА', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types', 'COLUMN', 'set_start_day_period_dolg'
go

exec sp_addextendedproperty 'MS_Description', N'Использовать методические рекомендации по распределению оплаты',
     'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types', 'COLUMN', 'is_recom_for_payment'
go

exec sp_addextendedproperty 'MS_Description',
     N'Кол-во оплат в день, для того чтобы считать его последним закрытым днём для квитанций', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'last_paym_day_count_payments'
go

exec sp_addextendedproperty 'MS_Description', N'отдельный учет сальдо по услугам для ЕПД', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types', 'COLUMN', 'is_epd_saldo'
go

