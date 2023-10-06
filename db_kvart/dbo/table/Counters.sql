create table Counters
(
    id                 int identity
        constraint PK_COUNTERS
            primary key,
    service_id         varchar(10)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    serial_number      varchar(20)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    type               varchar(30)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    build_id           int                              not null
        constraint FK_COUNTERS_BUILDINGS
            references Buildings
            on update cascade on delete cascade,
    flat_id            int,
    max_value          int                              not null
        constraint CK_COUNTERS
            check ([max_value] <= 999999999),
    koef               decimal(9, 4)                    not null,
    unit_id            varchar(10)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    count_value        decimal(14, 6)
        constraint DF_COUNTERS_count_value default 0    not null,
    date_create        smalldatetime                    not null,
    CountValue_del     decimal(14, 6)
        constraint DF_COUNTERS_CountValue_del default 0 not null,
    date_del           smalldatetime,
    PeriodCheck        smalldatetime,
    user_edit          smallint,
    date_edit          smalldatetime,
    comments           varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    internal           bit
        constraint DF_COUNTERS_internal default 0       not null,
    is_build           bit
        constraint DF_COUNTERS_is_build default 0       not null,
    checked_fin_id     smallint,
    mode_id            int
        constraint DF_COUNTERS_mode_id default 0        not null,
    PeriodCheckOld     smalldatetime,
    PeriodCheckEdit    smalldatetime,
    id_pu_gis          varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    PeriodLastCheck    smalldatetime,
    PeriodInterval     smallint,
    is_sensor_temp     bit,
    is_sensor_press    bit,
    is_remot_reading   bit,
    ReasonDel          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    room_id            int,
    date_load_gis      smalldatetime,
    counter_uid        uniqueidentifier,
    count_tarif        smallint
        constraint DF_Counters_count_tarif default 1    not null
        constraint CK_Counters_count_tarif
            check ([count_tarif] = 3 OR [count_tarif] = 2 OR [count_tarif] = 1),
    value_serv_many_pu bit,
    external_id        varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    blocker_read_value bit
)
go

exec sp_addextendedproperty 'MS_Description', N'Список счетчиков', 'SCHEMA', 'dbo', 'TABLE', 'Counters'
go

exec sp_addextendedproperty 'MS_Description', N'Код счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Серийный номер счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'serial_number'
go

exec sp_addextendedproperty 'MS_Description', N'Тип счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'type'
go

exec sp_addextendedproperty 'MS_Description', N'Код дома', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'flat_id'
go

exec sp_addextendedproperty 'MS_Description', N'Максимальное значение счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'max_value'
go

exec sp_addextendedproperty 'MS_Description', N'Коэффициент', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'koef'
go

exec sp_addextendedproperty 'MS_Description', N'Еденицы измерения счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'unit_id'
go

exec sp_addextendedproperty 'MS_Description', N'Начальное значение счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'count_value'
go

exec sp_addextendedproperty 'MS_Description', N'Дата принятия счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'date_create'
go

exec sp_addextendedproperty 'MS_Description', N'значение при закрытии', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'CountValue_del'
go

exec sp_addextendedproperty 'MS_Description', N'дата закрытия', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'date_del'
go

exec sp_addextendedproperty 'MS_Description', N'Срок поверки счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'PeriodCheck'
go

exec sp_addextendedproperty 'MS_Description', N'Последний редактировал', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN', 'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета по единой квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'internal'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовой счетчик', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'is_build'
go

exec sp_addextendedproperty 'MS_Description', N'Режим(для тариф) по умолчанию при загрузке показаний', 'SCHEMA', 'dbo',
     'TABLE', 'Counters', 'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код ПУ в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'id_pu_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Дата последней поверки', 'SCHEMA', 'dbo', 'TABLE', 'Counters', 'COLUMN',
     'PeriodLastCheck'
go

exec sp_addextendedproperty 'MS_Description', N'Межповерочный интервал (1-20 лет)', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'PeriodInterval'
go

exec sp_addextendedproperty 'MS_Description', N'Наличие датчика температуры', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'is_sensor_temp'
go

exec sp_addextendedproperty 'MS_Description', N'Наличие датчиков давления', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'is_sensor_press'
go

exec sp_addextendedproperty 'MS_Description', N'Возможность дистанционного снятия показаний', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'is_remot_reading'
go

exec sp_addextendedproperty 'MS_Description', N'Причина закрытия(архивации) ПУ', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'ReasonDel'
go

exec sp_addextendedproperty 'MS_Description', N'Код комнаты (если есть)', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'room_id'
go

exec sp_addextendedproperty 'MS_Description', N'Дата обновления информации из ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'date_load_gis'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во тарифов (вид ПУ по кол-ву тарифов)', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'count_tarif'
go

exec sp_addextendedproperty 'MS_Description', N'объем ресурса определяется с помощью нескольких ПУ', 'SCHEMA', 'dbo',
     'TABLE', 'Counters', 'COLUMN', 'value_serv_many_pu'
go

exec sp_addextendedproperty 'MS_Description', N'код ПУ для внешних расч.систем', 'SCHEMA', 'dbo', 'TABLE', 'Counters',
     'COLUMN', 'external_id'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать приём показаний по ПУ', 'SCHEMA', 'dbo', 'TABLE',
     'Counters', 'COLUMN', 'blocker_read_value'
go

