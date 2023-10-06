create table Global_values
(
    fin_id              smallint                                                        not null
        constraint PK_GLOBAL_VALUES
            primary key,
    start_date          smalldatetime                                                   not null,
    end_date            smalldatetime                                                   not null,
    StrMes              varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    closed              bit
        constraint DF_GLOBAL_VALUES_closed default 0,
    ExtSubsidia         bit
        constraint DF_GLOBAL_VALUES_ExtSubsidia default 1                               not null,
    ras_subsid_only     bit
        constraint DF_GLOBAL_VALUES_ras_subsid_only default 0                           not null,
    Mes_nazn            smalldatetime,
    SubNorma            bit
        constraint DF_GLOBAL_VALUES_SubNorma default 0                                  not null,
    procent             smallint
        constraint DF_GLOBAL_VALUES_procent default 12                                  not null,
    SubClosedData       smalldatetime,
    Minzpl              decimal(9, 2)
        constraint DF_GLOBAL_VALUES_Minzpl default 0                                    not null,
    Prmin               decimal(9, 2)
        constraint DF_GLOBAL_VALUES_Prmin default 0                                     not null,
    Srok                smallint
        constraint DF_GLOBAL_VALUES_Srok default 6                                      not null,
    Metod2              bit
        constraint DF_GLOBAL_VALUES_Metod2 default 1                                    not null,
    LiftFloor           smallint
        constraint DF_GLOBAL_VALUES_LiftFloor default 2                                 not null,
    LiftYear1           smallint
        constraint DF_GLOBAL_VALUES_LiftYear1 default 7                                 not null,
    LiftYear2           smallint
        constraint DF_GLOBAL_VALUES_LiftYear2 default 80                                not null,
    PenyRas             bit
        constraint DF_GLOBAL_VALUES_PenyRas default 1                                   not null,
    LastPaym            smallint
        constraint DF_GLOBAL_VALUES_LastPaym default 31                                 not null,
    PenyProc            as [StavkaCB] / 300,
    PaymClosed          bit
        constraint DF_GLOBAL_VALUES_PaymClosed default 0                                not null,
    PaymClosedData      smalldatetime,
    FinClosedData       smalldatetime,
    State               varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Region              varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Town                varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Norma1              decimal(5, 2)
        constraint DF_GLOBAL_VALUES_Sotr1 default 0                                     not null,
    Norma2              decimal(5, 2)
        constraint DF_GLOBAL_VALUES_Sotr2 default 0                                     not null,
    NormaSub            decimal(5, 2)
        constraint DF_GLOBAL_VALUES_Sotr3 default 0                                     not null,
    SumLgotaAntena      decimal(9, 2)
        constraint DF_GLOBAL_VALUES_SumLgotaAntena default 0                            not null,
    AddGvrProcent       decimal(5, 2)
        constraint DF_GLOBAL_VALUES_AddGvrProcent default 0                             not null,
    AddGvrDays          smallint
        constraint DF_GLOBAL_VALUES_AddGvrDays default 14                               not null,
    AddOtpProcent       decimal(5, 2)
        constraint DF_GLOBAL_VALUES_AddOtpProcent default 0                             not null,
    POPserver           varchar(39) collate SQL_Latin1_General_CP1251_CI_AS,
    GKAL                decimal(10, 4),
    NormaGKAL           decimal(10, 4),
    StrMes2             varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    LgotaRas            bit
        constraint DF_GLOBAL_VALUES_LgotaRas default 1                                  not null,
    msg_timeout         smallint
        constraint DF_GLOBAL_VALUES_Msg_TimeOut default 1                               not null,
    counter_block_value bit
        constraint DF_GLOBAL_VALUES_counter_block_value default 0                       not null,
    web_reports         nvarchar(100)
        constraint DF_GLOBAL_VALUES_web_reports default N'http://s2011/reports'         not null collate SQL_Latin1_General_CP1251_CI_AS,
    filenamearhiv       nvarchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    dir_new_version     nvarchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    name_org            varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    logo                varbinary(max),
    BlokedPrintAccount  bit
        constraint DF_GLOBAL_VALUES_BlokedPrintAccount default 0,
    basa_name_arxiv     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    profile_mail        varchar(20)
        constraint DF_GLOBAL_VALUES_profile_mail default 'sql_mail'                     not null collate SQL_Latin1_General_CP1251_CI_AS,
    ProgramName         varchar(50)
        constraint DF_GLOBAL_VALUES_ProgramName default 'Биллинг-РЦ' collate SQL_Latin1_General_CP1251_CI_AS,
    FTPServer           varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    FTPPort             int
        constraint DF_Global_values_FTPPort default 21                                  not null,
    FTPUser             varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    FTPPswd             varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    barcode_type        smallint,
    blocked_export      bit
        constraint DF_GLOBAL_VALUES_block_export default 0,
    KolDayFinPeriod     smallint,
    StavkaCB            decimal(10, 4)
        constraint DF_GLOBAL_VALUES_StavkaCB default 6                                  not null,
    koef_for_norma      decimal(5, 3)
        constraint DF_GLOBAL_VALUES_koef_for_norma default 1                            not null,
    CounterValue1       smallint
        constraint DF_GLOBAL_VALUES_CounterValue1 default 15                            not null,
    CounterValue2       smallint
        constraint DF_GLOBAL_VALUES_CounterValue2 default 25                            not null,
    use_koef_build      bit
        constraint DF__GLOBAL_VA__use_k__65238F17 default 0                             not null,
    procSubs12          varchar(100)
        constraint DF_GLOBAL_VALUES_procSubs12 default '6.1;10.6;11.23;5.7;1.7;6;12.13' not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_GLOBAL_VALUES_procSubs12
            check (patindex('%[^;.,0-9]%', [procSubs12]) = 0),
    settings_json       nvarchar(max) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_Global_values_settings
            check (isjson([settings_json]) = 1),
    Path_download       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    settings_developer  nvarchar(max) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_Global_values_developer
            check (isjson([settings_developer]) = 1),
    heat_summer_start   date,
    heat_summer_end     date,
    counter_last_metod  smallint
        constraint DF_Global_values_counter_last_metod default 0                        not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Глобальные значения в системе', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values'
go

exec sp_addextendedproperty 'MS_Description', N'код финансового периода', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата начала ', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'start_date'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'end_date'
go

exec sp_addextendedproperty 'MS_Description', N'название месяца', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'StrMes'
go

exec sp_addextendedproperty 'MS_Description', N'Признак закрытия', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'closed'
go

exec sp_addextendedproperty 'MS_Description', N'признак внешнего расчета субсидий', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'ExtSubsidia'
go

exec sp_addextendedproperty 'MS_Description', N'Расчет только субсидий', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'ras_subsid_only'
go

exec sp_addextendedproperty 'MS_Description', N'дата назначения субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'Mes_nazn'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчета субсидии на соц. норму', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'SubNorma'
go

exec sp_addextendedproperty 'MS_Description', N'процент от дохода для субсидии', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'procent'
go

exec sp_addextendedproperty 'MS_Description', N'Мин. зарплата', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'Minzpl'
go

exec sp_addextendedproperty 'MS_Description', N'Прожиточный минимум', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'Prmin'
go

exec sp_addextendedproperty 'MS_Description', N'Срок назначения субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'Srok'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчета по 2 методу', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'Metod2'
go

exec sp_addextendedproperty 'MS_Description', N'по этотэтаж не платят за лифт', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'LiftFloor'
go

exec sp_addextendedproperty 'MS_Description', N'начиная с этого возраста платят за лифт', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'LiftYear1'
go

exec sp_addextendedproperty 'MS_Description', N'по этот возраст платят за лифт', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'LiftYear2'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчета пени в системе', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'PenyRas'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'LastPaym'
go

exec sp_addextendedproperty 'MS_Description', N'Процент пени в день', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'PenyProc'
go

exec sp_addextendedproperty 'MS_Description', N'Признак закрытия платежного периода', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'PaymClosed'
go

exec sp_addextendedproperty 'MS_Description', N'Дата закрытия платежного периода', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'PaymClosedData'
go

exec sp_addextendedproperty 'MS_Description', N'Дата закрытия финансового периода', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'FinClosedData'
go

exec sp_addextendedproperty 'MS_Description', N'Государство', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'State'
go

exec sp_addextendedproperty 'MS_Description', N'Республика', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'Region'
go

exec sp_addextendedproperty 'MS_Description', N'Город', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN', 'Town'
go

exec sp_addextendedproperty 'MS_Description', N'Соц. норма в общежитиях 1 типа', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'Norma1'
go

exec sp_addextendedproperty 'MS_Description', N'Соц. норма в общежитиях 2 типа', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'Norma2'
go

exec sp_addextendedproperty 'MS_Description', N'Соц. норма в комунальных квартирах', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'NormaSub'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма льготы на антенну', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'SumLgotaAntena'
go

exec sp_addextendedproperty 'MS_Description', N'Процент возврата от тарифа за гор. воду', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'AddGvrProcent'
go

exec sp_addextendedproperty 'MS_Description', N'Нормативный срок отсутствия гор. воды', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'AddGvrDays'
go

exec sp_addextendedproperty 'MS_Description', N'Процент возврата от тарифа за Отопление', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'AddOtpProcent'
go

exec sp_addextendedproperty 'MS_Description', N'IP - адрес почтового сервера', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'POPserver'
go

exec sp_addextendedproperty 'MS_Description', N'Ссылка на сайт с web-отчетами', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'web_reports'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование расчётного центра', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'name_org'
go

exec sp_addextendedproperty 'MS_Description', N'логотип организации', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'logo'
go

exec sp_addextendedproperty 'MS_Description', N'Заблокировать временно печать квитанций в текущем периоде', 'SCHEMA',
     'dbo', 'TABLE', 'Global_values', 'COLUMN', 'BlokedPrintAccount'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование архивной базы', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'basa_name_arxiv'
go

exec sp_addextendedproperty 'MS_Description', N'Почтовый пофиль на SQL сервере', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'profile_mail'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование программы (для разных организаций может быть разной)',
     'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN', 'ProgramName'
go

exec sp_addextendedproperty 'MS_Description', 'IP FTP-server', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'FTPServer'
go

exec sp_addextendedproperty 'MS_Description', N'Порт FTP сервера', 'SCHEMA', 'dbo', 'TABLE', 'Global_values', 'COLUMN',
     'FTPPort'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь FTP-server', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'FTPUser'
go

exec sp_addextendedproperty 'MS_Description', N'Пароль к FTP-server', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'FTPPswd'
go

exec sp_addextendedproperty 'MS_Description', N'Тип штрих-кода по умолчанию', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'barcode_type'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка экспорта', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'blocked_export'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во дней в фин.периоде', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'KolDayFinPeriod'
go

exec sp_addextendedproperty 'MS_Description', N'Ставка рефинансирования ЦБ РФ', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'StavkaCB'
go

exec sp_addextendedproperty 'MS_Description', N'Повышающий коэффициент для нормативов', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'koef_for_norma'
go

exec sp_addextendedproperty 'MS_Description', N'Период ввода показаний с', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'CounterValue1'
go

exec sp_addextendedproperty 'MS_Description', N'Период ввода показаний по', 'SCHEMA', 'dbo', 'TABLE', 'Global_values',
     'COLUMN', 'CounterValue2'
go

exec sp_addextendedproperty 'MS_Description', N'Использовать коэффициенты для расчётов с домов', 'SCHEMA', 'dbo',
     'TABLE', 'Global_values', 'COLUMN', 'use_koef_build'
go

exec sp_addextendedproperty 'MS_Description', N'Список индексов изменения платы граждан за КУ', 'SCHEMA', 'dbo',
     'TABLE', 'Global_values', 'COLUMN', 'procSubs12'
go

exec sp_addextendedproperty 'MS_Description', N'ссылка для скачивания новых версий', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'Path_download'
go

exec sp_addextendedproperty 'MS_Description', N'Начало летного периода по отоплению', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'heat_summer_start'
go

exec sp_addextendedproperty 'MS_Description', N'Конец летного периода по отоплению', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'heat_summer_end'
go

exec sp_addextendedproperty 'MS_Description',
     N'3-использовать последнее показание рассчитанное по счетчику (иначе любое переданное)', 'SCHEMA', 'dbo', 'TABLE',
     'Global_values', 'COLUMN', 'counter_last_metod'
go

