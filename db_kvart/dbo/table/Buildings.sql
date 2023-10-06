create table Buildings
(
    id                      int identity
        constraint PK_BUILDINGS_1
            primary key,
    street_id               int                                  not null
        constraint FK_BUILDINGS_STREETS
            references Streets,
    nom_dom                 varchar(12)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    sector_id               smallint
        constraint DF_BUILDINGS_sector_id default 0              not null,
    div_id                  smallint                             not null,
    tip_id                  smallint                             not null
        constraint FK_BUILDINGS_OCCUPATION_TYPES
            references Occupation_Types
            on update cascade,
    index_id                int
        constraint DF_BUILDINGS_index_id_1 default 1             not null
        constraint FK_BUILDINGS_OPS
            references Ops
            on update cascade,
    old                     bit
        constraint DF_BUILDINGS_old default 0                    not null,
    fin_current             smallint                             not null,
    is_paym_build           bit
        constraint DF_BUILDINGS_is_paym_value default 1          not null,
    dog_bit                 bit
        constraint DF_BUILDINGS_dog_bit default 0                not null,
    penalty_calc_build      bit
        constraint DF_BUILDINGS_Penalty_calc_build default 1     not null,
    blocked_house           bit
        constraint DF_BUILDINGS_blocked_house default 0          not null,
    town_id                 smallint                             not null
        constraint FK_BUILDINGS_TOWNS
            references Towns,
    standart_id             int,
    levels                  smallint,
    balans_cost             decimal(15, 2),
    material_wall           int,
    comments                varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kolpodezd               smallint,
    seria                   varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    godp                    smallint,
    tip_name_out            varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    date_out                smalldatetime,
    index_postal            int,
    id_accounts             int,
    bank_account            int
        constraint FK_Buildings_Account_org
            references Account_org (id),
    norma_gkal              decimal(9, 6)
        constraint CK_BUILDINGS_norma_gkal
            check ([norma_gkal] < 1),
    LastPaym                smallint,
    court_id                smallint,
    collector_id            smallint,
    dog_num                 varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    dog_date                smalldatetime,
    date_create             smalldatetime,
    date_start              smalldatetime,
    date_end                smalldatetime,
    is_boiler               bit,
    dog_date_sobr           smalldatetime,
    dog_date_protocol       smalldatetime,
    dog_num_protocol        varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    dog_id_gis              varchar(36) collate SQL_Latin1_General_CP1251_CI_AS,
    arenda_sq               decimal(10, 4)
        constraint DF_Buildings_arenda_sq default 0,
    opu_sq                  decimal(10, 4)
        constraint DF_Buildings_opu_sq default 0,
    opu_sq_elek             decimal(10, 4)
        constraint DF_Buildings_opu_sq_elek default 0,
    opu_sq_otop             decimal(10, 4)
        constraint DF_Buildings_opu_sq_otop default 0,
    build_total_area        decimal(10, 4)
        constraint [DF_Buildings_total_ area] default 0,
    build_total_sq          decimal(10, 4)
        constraint DF_Buildings_build_total_sq default 0,
    is_lift                 bit,
    vid_blag                smallint
        constraint FK_BUILDINGS_VID_BLAG
            references Vid_blag,
    odn_big_norma           bit,
    penalty_paym_no         bit,
    info_account_no         bit,
    build_type              smallint
        constraint DF_BUILDINGS_build_type default 1             not null
        constraint FK_BUILDINGS_BUILD_TYPES
            references Build_types,
    norma_gkal_gvs          decimal(9, 6),
    blocked_counter_add     bit
        constraint DF_BUILDINGS_blocked_counter_add default 0    not null,
    comments_add_fin        bit,
    norma_gaz_gvs           decimal(9, 6),
    norma_gaz_otop          decimal(9, 6),
    kol_lift                smallint,
    levels_min              smallint,
    kol_sekcia              smallint,
    srok_sluzhba            smallint,
    iznos                   smallint,
    kol_musor               smallint,
    people_reg_blocked      bit,
    ras_no_counter_poverka  bit
        constraint DF_BUILDINGS_ras_no_counter_poverka default 0 not null,
    kod_fias                varchar(36) collate SQL_Latin1_General_CP1251_CI_AS,
    is_counter_add_balance  bit
        constraint DF_BUILDINGS_is_counter_add_balance default 0 not null,
    only_pasport            bit
        constraint DF_BUILDINGS_only_pasport default 0           not null,
    CadastralNumber         varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kultura                 bit,
    levels_underground      smallint,
    kod_gis                 varchar(36) collate SQL_Latin1_General_CP1251_CI_AS,
    nom_dom_sort            varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    id_nom_dom_gis          varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    blocked_counter_out     bit
        constraint DF_BUILDINGS_blocked_counter_out default 0    not null,
    opu_tepl_kol            smallint
        constraint DF__BUILDINGS__opu_t__04122A8B default 0      not null,
    build_uid               uniqueidentifier,
    soi_votv_fact           bit
        constraint DF_Buildings_soi_votv_fact default 0          not null,
    account_rich            varchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    is_commission_uk        bit
        constraint DF__Buildings__is_co__7D901585 default 0      not null,
    is_value_build_minus    bit
        constraint DF__Buildings__is_va__1A2C5433 default 0      not null,
    is_not_allocate_economy bit
        constraint DF__Buildings__is_no__1B20786C default 0      not null,
    oktmo                   varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    soi_metod_calc          varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    decimal_round           int,
    peny_service_id         varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    counter_votv_norma      bit,
    soi_is_transfer_economy bit,
    is_finperiod_owner      bit
        constraint DF_Buildings_is_finperiod_owner default 0     not null,
    latitude                decimal(15, 6),
    longitude               decimal(15, 6),
    constraint IX_BUILDINGS
        unique (street_id, nom_dom, tip_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings'
go

exec sp_addextendedproperty 'MS_Description', N'Код дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код улицы', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'street_id'
go

exec sp_addextendedproperty 'MS_Description', N'Номер дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'nom_dom'
go

exec sp_addextendedproperty 'MS_Description', N'Код участка', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'sector_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код района', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'div_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код типа жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'Почтовый индекс', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'index_id'
go

exec sp_addextendedproperty 'MS_Description', N'Ветхий', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'old'
go

exec sp_addextendedproperty 'MS_Description', N'Код текущего фин. периода в доме', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'fin_current'
go

exec sp_addextendedproperty 'MS_Description', N'Признак начисления по дому', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'is_paym_build'
go

exec sp_addextendedproperty 'MS_Description', N'Договор управления', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'dog_bit'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени по дому', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'penalty_calc_build'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка дома (печати квитанций)', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'blocked_house'
go

exec sp_addextendedproperty 'MS_Description', N'Код города', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'town_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код стандарта жилья', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'standart_id'
go

exec sp_addextendedproperty 'MS_Description', N'Кол. этажей', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'levels'
go

exec sp_addextendedproperty 'MS_Description', N'Балансовая стоимость', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'balans_cost'
go

exec sp_addextendedproperty 'MS_Description', N'Код материалла', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'material_wall'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Количество подъездов', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'kolpodezd'
go

exec sp_addextendedproperty 'MS_Description', N'Серия дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'seria'
go

exec sp_addextendedproperty 'MS_Description', N'Год постройки', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'godp'
go

exec sp_addextendedproperty 'MS_Description', N'Куда передан дом', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'tip_name_out'
go

exec sp_addextendedproperty 'MS_Description', N'Дата передачи дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'date_out'
go

exec sp_addextendedproperty 'MS_Description', N'Почтовый индекс', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'index_postal'
go

exec sp_addextendedproperty 'MS_Description', N'Код квитанции для дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'id_accounts'
go

exec sp_addextendedproperty 'MS_Description', N'Код банковсого счёта дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'Норматив Гкал/кв.м в доме по отоплению', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'norma_gkal'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты без расчёта пени', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'LastPaym'
go

exec sp_addextendedproperty 'MS_Description', N'Код судебного участка', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'court_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код коллектора', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'collector_id'
go

exec sp_addextendedproperty 'MS_Description', N'№ договора', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'dog_num'
go

exec sp_addextendedproperty 'MS_Description', N'Дата договора', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'dog_date'
go

exec sp_addextendedproperty 'MS_Description', N'Дата создания дома (добавления записи)', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'date_create'
go

exec sp_addextendedproperty 'MS_Description', N'Дата передачи дома в данную УК (Дата начала расчёта по дому)', 'SCHEMA',
     'dbo', 'TABLE', 'Buildings', 'COLUMN', 'date_start'
go

exec sp_addextendedproperty 'MS_Description', N'Дата окончания расчёта по дому', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'date_end'
go

exec sp_addextendedproperty 'MS_Description', N'Признак бойлера в доме для нагрева ГВС из ХВС', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'is_boiler'
go

exec sp_addextendedproperty 'MS_Description', N'Дата собрания по выбору УК', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'dog_date_sobr'
go

exec sp_addextendedproperty 'MS_Description', N'Дата протокола собрания по выбору УК', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'dog_date_protocol'
go

exec sp_addextendedproperty 'MS_Description', N'Номер протокола собрания по выбору УК', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'dog_num_protocol'
go

exec sp_addextendedproperty 'MS_Description', N'Идентификатор договора управления ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'dog_id_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Площадь нежилых помещений', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'arenda_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовая площадь по воде', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'opu_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовая площадь по электроэнергии', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'opu_sq_elek'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовая площадь по отоплению', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'opu_sq_otop'
go

exec sp_addextendedproperty 'MS_Description', N'Общая площадь дома по паспорту', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'build_total_area'
go

exec sp_addextendedproperty 'MS_Description', N'Площадь дома (жилых помещений)', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'build_total_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Признак наличия лифта в доме', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'is_lift'
go

exec sp_addextendedproperty 'MS_Description', N'Код категории благоустройства жил.фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'vid_blag'
go

exec sp_addextendedproperty 'MS_Description', N'Признак возможности распределения ОДН больше нормы', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'odn_big_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Не оплачивать пени по дому', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'penalty_paym_no'
go

exec sp_addextendedproperty 'MS_Description', N'Не выводить таблицу со справочной информацией в квитанции по ОПУ',
     'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'info_account_no'
go

exec sp_addextendedproperty 'MS_Description', N'Тип жилого дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'build_type'
go

exec sp_addextendedproperty 'MS_Description', N'Норматив Гкал/м3 в месяц в доме на ГВС', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'norma_gkal_gvs'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка расчёта разовых по счётчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'blocked_counter_add'
go

exec sp_addextendedproperty 'MS_Description', N'Автоматичкски добавлять комментарий на след.месяц если есть в текущем',
     'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'comments_add_fin'
go

exec sp_addextendedproperty 'MS_Description', N'Норматив газа тыс.м3/м3 в месяц в доме на ГВС', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'norma_gaz_gvs'
go

exec sp_addextendedproperty 'MS_Description', N'Норматив газа тыс.м3/м3 в месяц в доме на Отопление', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'norma_gaz_otop'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во лифтов', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'kol_lift'
go

exec sp_addextendedproperty 'MS_Description', N'Минимальный этаж', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'levels_min'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во секций', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'kol_sekcia'
go

exec sp_addextendedproperty 'MS_Description', N'Срок службы дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'srok_sluzhba'
go

exec sp_addextendedproperty 'MS_Description', N'% износа', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'iznos'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во мусоропроводов', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'kol_musor'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка регистрации граждан', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'people_reg_blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Запрет расчёта по счётчикам с истёкшим сроком поверки', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'ras_no_counter_poverka'
go

exec sp_addextendedproperty 'MS_Description', N'Глобальный уникальный идентификатор дома по ФИАС', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'kod_fias'
go

exec sp_addextendedproperty 'MS_Description', N'Ведение только паспортного стола', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'only_pasport'
go

exec sp_addextendedproperty 'MS_Description', N'Кадастровый номер', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'CadastralNumber'
go

exec sp_addextendedproperty 'MS_Description', N'Наличие статуса культурного наследия', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'kultura'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во подземных гаражей', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'levels_underground'
go

exec sp_addextendedproperty 'MS_Description', N'Идентификационный код дома в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'kod_gis'
go

exec sp_addextendedproperty 'MS_Description', N'№ дома для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN',
     'nom_dom_sort'
go

exec sp_addextendedproperty 'MS_Description', N'Уникальный номер дома в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'id_nom_dom_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка экспорта ПУ в другие системы', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'blocked_counter_out'
go

exec sp_addextendedproperty 'MS_Description', N'Количество узлов учёта теплоэнергии', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'opu_tepl_kol'
go

exec sp_addextendedproperty 'MS_Description', N'Расчет водоотведения СОИ по факту (хвс сои + гвс сои)', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'soi_votv_fact'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительный текст или таблица в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'account_rich'
go

exec sp_addextendedproperty 'MS_Description', N'Признак оплаты банковской комиссии УК(ТСЖ)', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'is_commission_uk'
go

exec sp_addextendedproperty 'MS_Description', N'разрешить ОДН с минусом', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'is_value_build_minus'
go

exec sp_addextendedproperty 'MS_Description', N'не распределять экономию, оставлять по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'is_not_allocate_economy'
go

exec sp_addextendedproperty 'MS_Description',
     N'Метод расчета СОИ (CALC_TARIF или CALC_KOL) если NULL то берется из типа фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'soi_metod_calc'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во знаков для округления начислений', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'decimal_round'
go

exec sp_addextendedproperty 'MS_Description', N'Распределять пени только на заданную услугу', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'peny_service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Расчёт Водоотведения по норме', 'SCHEMA', 'dbo', 'TABLE', 'Buildings',
     'COLUMN', 'counter_votv_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Перенос экономии СОИ на следующий период', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings', 'COLUMN', 'soi_is_transfer_economy'
go

exec sp_addextendedproperty 'MS_Description', N'признак отдельного учета по фин.периоду с типом фонда', 'SCHEMA', 'dbo',
     'TABLE', 'Buildings', 'COLUMN', 'is_finperiod_owner'
go

exec sp_addextendedproperty 'MS_Description', N'Широта', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'latitude'
go

exec sp_addextendedproperty 'MS_Description', N'Долгота', 'SCHEMA', 'dbo', 'TABLE', 'Buildings', 'COLUMN', 'longitude'
go

