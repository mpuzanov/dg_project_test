create table Occupations
(
    Occ                    int                               not null
        constraint PK_OCCUPATIONS
            primary key,
    jeu                    smallint
        constraint DF_Occupations_jeu default 0              not null,
    schtl                  int,
    flat_id                int                               not null
        constraint FK_OCCUPATIONS_FLATS
            references Flats
            on update cascade,
    tip_id                 smallint                          not null
        constraint FK_OCCUPATIONS_OCCUPATION_TYPES
            references Occupation_Types
            on update cascade,
    roomtype_id            varchar(10)                       not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_OCCUPATIONS_ROOM_TYPES
            references Room_types,
    proptype_id            varchar(10)                       not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_OCCUPATIONS_PROPERTY_TYPES
            references Property_types,
    status_id              varchar(10)                       not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_OCCUPATIONS_OCC_STATUSES
            references Occ_Statuses,
    living_sq              smallmoney
        constraint DF_OCCUPATIONS_LIVING_SQ default 0        not null,
    total_sq               smallmoney
        constraint DF_OCCUPATIONS_TOTAL_SQ default 0         not null,
    teplo_sq               smallmoney
        constraint DF_OCCUPATIONS_TEPLO_SQ default 0         not null,
    norma_sq               smallmoney
        constraint DF_OCCUPATIONS_NORMA_SQ default 0         not null,
    fin_id                 smallint                          not null,
    socnaim                bit
        constraint DF_OCCUPATIONS_SOCNAIM default 0          not null,
    SALDO                  decimal(15, 4)
        constraint DF_OCCUPATIONS_SALDO_1 default 0          not null,
    saldo_serv             decimal(15, 4)
        constraint DF_OCCUPATIONS_SALDO default 0            not null,
    saldo_edit             smallint
        constraint DF_OCCUPATIONS_saldo_edit default 0       not null,
    Value                  decimal(15, 4)
        constraint DF_OCCUPATIONS_Value default 0            not null,
    Discount               decimal(15, 4)
        constraint DF_OCCUPATIONS_Discount default 0         not null,
    Compens                decimal(15, 4)
        constraint DF_OCCUPATIONS_Compens default 0          not null,
    Added                  decimal(15, 4)
        constraint DF_OCCUPATIONS_Added default 0            not null,
    Added_ext              decimal(15, 4)
        constraint DF_OCCUPATIONS_Added_ext default 0        not null,
    PaymAccount            decimal(9, 2)
        constraint DF_OCCUPATIONS_PaymAccount default 0      not null,
    PaymAccount_peny       decimal(9, 2)
        constraint DF_OCCUPATIONS_PaymAccount_peny default 0 not null,
    Paid                   decimal(15, 4)
        constraint DF_OCCUPATIONS_Paid default 0             not null,
    Paid_minus             decimal(15, 4)
        constraint DF_OCCUPATIONS_Paid_minus default 0       not null,
    Paid_old               decimal(15, 4)
        constraint DF_OCCUPATIONS_Paid_old default 0         not null,
    Penalty_calc           bit
        constraint DF_OCCUPATIONS_Penalty_debt default 1     not null,
    Penalty_old_edit       smallint
        constraint DF_OCCUPATIONS_Penalty_old_edit default 0 not null,
    Penalty_old            decimal(9, 2)
        constraint DF_OCCUPATIONS_Penalty_old default 0      not null,
    Penalty_old_new        decimal(9, 2)
        constraint DF_OCCUPATIONS_Penalty_old_new default 0  not null,
    Penalty_added          decimal(9, 2)
        constraint DF_Occupations_Penalty_added default 0    not null,
    Penalty_value          decimal(9, 2)
        constraint DF_OCCUPATIONS_Penalty_last default 0     not null,
    address                varchar(60) collate SQL_Latin1_General_CP1251_CI_AS,
    Data_rascheta          smalldatetime,
    rooms                  smallint,
    kol_people             smallint,
    peny_calc_date_begin   smalldatetime,
    peny_calc_date_end     smalldatetime,
    telephon               bigint,
    date_create            smalldatetime,
    date_start             smalldatetime,
    date_end               smalldatetime,
    prefix                 varchar(7) collate SQL_Latin1_General_CP1251_CI_AS,
    SaldoAll               decimal(15, 4),
    Paymaccount_ServAll    decimal(15, 4),
    PaidAll                decimal(15, 4),
    Compens_ext            decimal(15, 4),
    AddedAll               decimal(15, 4),
    email                  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    auto_email             bit,
    occ_sync               int,
    Debt                   as ([saldo] + ([value] - [discount]) + [added]) - ([paymaccount] - [paymaccount_peny]),
    CadastralNumber        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    id_jku_gis             varchar(13) collate SQL_Latin1_General_CP1251_CI_AS,
    id_els_gis             varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    id_nom_gis             varchar(14) collate SQL_Latin1_General_CP1251_CI_AS,
    dogovor_num            varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    dogovor_date           smalldatetime,
    room_id                int,
    doc_order_kvr          varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    comments               varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    comments2              varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    KolMesDolg             smallint,
    comments_print         varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_people_reg         smallint,
    kol_people_all         smallint,
    occ_uid                uniqueidentifier,
    kol_people_owner       smallint,
    schtl_old              varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    bank_account           int,
    peny_nocalc_date_begin date,
    peny_nocalc_date_end   date
)
go

exec sp_addextendedproperty 'MS_Description', N'Лицевые счета квартиросъемщиков', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations'
go

exec sp_addextendedproperty 'MS_Description', N'единый лицевой счет', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'Occ'
go

exec sp_addextendedproperty 'MS_Description', N'участок', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'jeu'
go

exec sp_addextendedproperty 'MS_Description', N'Старый лиц. счет или Внешний лицевой', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'schtl'
go

exec sp_addextendedproperty 'MS_Description', N'код квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'flat_id'
go

exec sp_addextendedproperty 'MS_Description', N'тип жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'Тип помещения', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'roomtype_id'
go

exec sp_addextendedproperty 'MS_Description', N'Статус помещения', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'proptype_id'
go

exec sp_addextendedproperty 'MS_Description', N'Статус лицевого', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'status_id'
go

exec sp_addextendedproperty 'MS_Description', N'жилая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'living_sq'
go

exec sp_addextendedproperty 'MS_Description', N'общая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'total_sq'
go

exec sp_addextendedproperty 'MS_Description', N'отапливаемая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'teplo_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Площадь по норме', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'norma_sq'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Признак договора соц. найма', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'socnaim'
go

exec sp_addextendedproperty 'MS_Description', N'вх. сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'SALDO'
go

exec sp_addextendedproperty 'MS_Description', N'вх. сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'saldo_serv'
go

exec sp_addextendedproperty 'MS_Description', N'признак корректировки сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'saldo_edit'
go

exec sp_addextendedproperty 'MS_Description', N'начислено', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'Value'
go

exec sp_addextendedproperty 'MS_Description', N'льготы', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'Discount'
go

exec sp_addextendedproperty 'MS_Description', N'субсидия', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'Compens'
go

exec sp_addextendedproperty 'MS_Description', N'разовые', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'Added'
go

exec sp_addextendedproperty 'MS_Description', N'разовые по внешним услугам', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'Added_ext'
go

exec sp_addextendedproperty 'MS_Description', N'Оплатил', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'PaymAccount'
go

exec sp_addextendedproperty 'MS_Description', N'Оплатил пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'PaymAccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'пост. начисление', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'Paid'
go

exec sp_addextendedproperty 'MS_Description', N'Пост. начисление при переплате', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'Paid_minus'
go

exec sp_addextendedproperty 'MS_Description', N'пост. начисление предыдущего месяца', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'Paid_old'
go

exec sp_addextendedproperty 'MS_Description', N'признак начисления пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'Penalty_calc'
go

exec sp_addextendedproperty 'MS_Description', N'признак изменения пени в ручную', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'Penalty_old_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Пени предыдущих периодов', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'Penalty_old'
go

exec sp_addextendedproperty 'MS_Description', N'Измененное пени пред. периодов ', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'Penalty_old_new'
go

exec sp_addextendedproperty 'MS_Description', N'Расчитанное пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'Penalty_value'
go

exec sp_addextendedproperty 'MS_Description', N'Адрес', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'address'
go

exec sp_addextendedproperty 'MS_Description', N'Дата расчета', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'Data_rascheta'
go

exec sp_addextendedproperty 'MS_Description', N'кол. комнат', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'rooms'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во проживающих граждан', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'kol_people'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'peny_calc_date_begin'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания расчета пени', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'peny_calc_date_end'
go

exec sp_addextendedproperty 'MS_Description', N'телефон', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'telephon'
go

exec sp_addextendedproperty 'MS_Description', N'дата создания', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'date_create'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала расчётов', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'date_start'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания расчётов', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'date_end'
go

exec sp_addextendedproperty 'MS_Description', N'Дописывает знаки к квартире или вместо(со знаком &)', 'SCHEMA', 'dbo',
     'TABLE', 'Occupations', 'COLUMN', 'prefix'
go

exec sp_addextendedproperty 'MS_Description', N'Общее сальдо с учётом поставщиков', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'SaldoAll'
go

exec sp_addextendedproperty 'MS_Description', N'Общая оплата с учётом поставщиков без пени', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'Paymaccount_ServAll'
go

exec sp_addextendedproperty 'MS_Description', N'Общее начисление с учётом поставщиков', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'PaidAll'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма разовых по всем услугам', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'AddedAll'
go

exec sp_addextendedproperty 'MS_Description', N'почтовый адрес', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'email'
go

exec sp_addextendedproperty 'MS_Description', N'Автоматическая рассылка квитанций', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'auto_email'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой для синхронизации', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'occ_sync'
go

exec sp_addextendedproperty 'MS_Description', N'конечное сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'Debt'
go

exec sp_addextendedproperty 'MS_Description', N'Кадастровый номер', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'CadastralNumber'
go

exec sp_addextendedproperty 'MS_Description',
     N'Уникальный идентификатор жилищно-коммунальной услуги, созданный ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'id_jku_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Единый ЛС ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'id_els_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Уникальный номер помещения', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'id_nom_gis'
go

exec sp_addextendedproperty 'MS_Description', N'номер договора', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'dogovor_num'
go

exec sp_addextendedproperty 'MS_Description', N'дата договора', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'dogovor_date'
go

exec sp_addextendedproperty 'MS_Description', N'код комнаты (если привязан)', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'room_id'
go

exec sp_addextendedproperty 'MS_Description', N'Документ ордер на квартиру', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'doc_order_kvr'
go

exec sp_addextendedproperty 'MS_Description', N'Договор', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN', 'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'comments2'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во месяцев долга', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'KolMesDolg'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий для печати в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'comments_print'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во зарегистрированных граждан', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'kol_people_reg'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во всех граждан', 'SCHEMA', 'dbo', 'TABLE', 'Occupations', 'COLUMN',
     'kol_people_all'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во собственников', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'kol_people_owner'
go

exec sp_addextendedproperty 'MS_Description', N'старый лицевой счет (из других систем)', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'schtl_old'
go

exec sp_addextendedproperty 'MS_Description', N'Расчетный счет по лицевому', 'SCHEMA', 'dbo', 'TABLE', 'Occupations',
     'COLUMN', 'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала прерывания расчета пени', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'peny_nocalc_date_begin'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания прерывания расчета пени', 'SCHEMA', 'dbo', 'TABLE',
     'Occupations', 'COLUMN', 'peny_nocalc_date_end'
go

