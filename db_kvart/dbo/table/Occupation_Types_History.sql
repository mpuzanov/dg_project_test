create table Occupation_Types_History
(
    fin_id               smallint    not null,
    id                   smallint    not null,
    name                 varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    payms_value          bit         not null,
    id_accounts          int         not null,
    adres                varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    fio                  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    telefon              varchar(70) collate SQL_Latin1_General_CP1251_CI_AS,
    id_barcode           smallint    not null,
    bank_account         int,
    laststr1             varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    penalty_calc_tip     bit         not null,
    counter_metod        smallint,
    counter_votv_ras     bit,
    laststr2             varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS,
    penalty_metod        smallint,
    PaymClosedData       smalldatetime,
    FinClosedData        smalldatetime,
    start_date           smalldatetime,
    LastPaymDay          smalldatetime,
    is_counter_cur_tarif bit,
    account_rich         varchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_OCCUPATIONS_TYPES_HISTORY
        primary key (fin_id, id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История значение по типам фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types_History'
go

exec sp_addextendedproperty 'MS_Description', N'Последний закрытый платёжный день для квитанций', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types_History', 'COLUMN', 'LastPaymDay'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительный текст или таблица в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Occupation_Types_History', 'COLUMN', 'account_rich'
go

