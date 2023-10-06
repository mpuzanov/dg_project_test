create table Account_org
(
    id           int identity,
    rasschet     varchar(20)                            not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_ACCOUNT_ORG_RS
            check ([RASSCHET] like
                   '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    bik          varchar(9)                             not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_ACCOUNT_ORG_BIK
            check ([BIK] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    licbank      bigint                                 not null,
    visible      bit
        constraint DF_Account_org_visible default 1     not null,
    name_str1    varchar(100)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    bank         varchar(50)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    korschet     varchar(20) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_ACCOUNT_ORG_KS
            check ([KORSCHET] like
                   '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR
                   coalesce([KORSCHET], '') = ''),
    inn          varchar(12) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_ACCOUNT_ORG_INN
            check ([INN] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR
                   [INN] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    id_barcode   varchar(50)
        constraint DF_ACCOUNT_ORG_id_barcode default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    tip          smallint                               not null,
    date_edit    smalldatetime,
    user_edit    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    name_str2    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    barcode_type smallint,
    kpp          varchar(9) collate SQL_Latin1_General_CP1251_CI_AS,
    name         as rtrim([name_str1]) + ',  ' + rtrim([bank]) + ', код орг: ' + ltrim([id_barcode]) + ', ' +
                    coalesce([comments], '') collate SQL_Latin1_General_CP1251_CI_AS,
    cbc          varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    oktmo        varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_ACCOUNT_ORG
        primary key (rasschet, bik, licbank, id_barcode)
)
go

exec sp_addextendedproperty 'MS_Description', N'Банковские счета организаций для печати квитанций', 'SCHEMA', 'dbo',
     'TABLE', 'Account_org'
go

exec sp_addextendedproperty 'MS_Description', N'Банковские счета организаций', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'расчётный счёт', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN',
     'rasschet'
go

exec sp_addextendedproperty 'MS_Description', N'проверка расч./счета 20 цифр', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'CONSTRAINT', 'CK_ACCOUNT_ORG_RS'
go

exec sp_addextendedproperty 'MS_Description', N'БИК', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN', 'bik'
go

exec sp_addextendedproperty 'MS_Description', N'проверка БИК 9 цифр', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'CONSTRAINT', 'CK_ACCOUNT_ORG_BIK'
go

exec sp_addextendedproperty 'MS_Description', N'Показывать банковский счёт в выборе', 'SCHEMA', 'dbo', 'TABLE',
     'Account_org', 'COLUMN', 'visible'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование организации (чей расч.счёт)', 'SCHEMA', 'dbo', 'TABLE',
     'Account_org', 'COLUMN', 'name_str1'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование банка', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN',
     'bank'
go

exec sp_addextendedproperty 'MS_Description', N'кор.счёт', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN', 'korschet'
go

exec sp_addextendedproperty 'MS_Description', N'проверка Кор/счета 20 цифр', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'CONSTRAINT', 'CK_ACCOUNT_ORG_KS'
go

exec sp_addextendedproperty 'MS_Description', N'ИНН', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN', 'inn'
go

exec sp_addextendedproperty 'MS_Description', N'проверка ИНН 12 цифр', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'CONSTRAINT', 'CK_ACCOUNT_ORG_INN'
go

exec sp_addextendedproperty 'MS_Description', N'код расч.счёта, где он показывается.
1 - Тип жил.фонда, 2 - Участок, 3 - Поставщик, 4 - Район, 5 - Дом, 6 - Договор, 7 - Лицевой', 'SCHEMA', 'dbo', 'TABLE',
     'Account_org', 'COLUMN', 'tip'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'адрес организации', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN',
     'name_str2'
go

exec sp_addextendedproperty 'MS_Description', N'код постановки на учёт', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'COLUMN', 'kpp'
go

exec sp_addextendedproperty 'MS_Description', N'Полное наименование р/сч.', 'SCHEMA', 'dbo', 'TABLE', 'Account_org',
     'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'КБК', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN', 'cbc'
go

exec sp_addextendedproperty 'MS_Description', N'ОКТМО', 'SCHEMA', 'dbo', 'TABLE', 'Account_org', 'COLUMN', 'oktmo'
go

