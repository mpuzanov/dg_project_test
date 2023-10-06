create table Suppliers_all
(
    id                  int identity (0, 1)
        constraint PK_SUPPLIERS_ALL
            primary key,
    name                varchar(50)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    adres               varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    telefon             varchar(70) collate SQL_Latin1_General_CP1251_CI_AS,
    fio                 varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    bank_account        int
        constraint FK_SUPPLIERS_ALL_ACCOUNT_ORG
            references Account_org (id),
    id_accounts         int
        constraint FK_SUPPLIERS_ALL_REPORTS_ACCOUNT
            references Reports_account,
    account_one         bit
        constraint DF_SUPPLIERS_ALL_account_one default 0,
    first_occ           smallint,
    penalty_calc        bit,
    LastPaym            smallint,
    synonym_name        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    inn                 varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    type_sum_intprint   smallint
        constraint DF_SUPPLIERS_ALL_type_sum_intprint default 1 not null,
    ogrn                varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    kpp                 varchar(9) collate SQL_Latin1_General_CP1251_CI_AS,
    email               varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_org_for_account varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    str_account1        varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    web_site            varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    adres_fact          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    rezhim_work         varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    penalty_metod       smallint,
    LastStrAccount      varchar(300) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_occ             smallint
        constraint DF_SUPPLIERS_ALL_tip_sup default 2           not null,
    account_rich        varchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    sup_uid             uniqueidentifier
)
go

exec sp_addextendedproperty 'MS_Description', N'Уникальные поставщики', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Адрес', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN', 'adres'
go

exec sp_addextendedproperty 'MS_Description', N'Телефон', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN', 'telefon'
go

exec sp_addextendedproperty 'MS_Description', N'Ф.И.О. директора', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'fio'
go

exec sp_addextendedproperty 'MS_Description', N'Код банковского счёта', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'Код файла квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'id_accounts'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта по отдельной квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'account_one'
go

exec sp_addextendedproperty 'MS_Description', N'Значение первых 3-х цифр лицевого счета', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'first_occ'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени по поставщику', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'penalty_calc'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день без пени', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'LastPaym'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование для документов', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'synonym_name'
go

exec sp_addextendedproperty 'MS_Description', N'ИНН', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN', 'inn'
go

exec sp_addextendedproperty 'MS_Description', N'Тип суммы для подсчёта итогов в квитанциях Сбербанка', 'SCHEMA', 'dbo',
     'TABLE', 'Suppliers_all', 'COLUMN', 'type_sum_intprint'
go

exec sp_addextendedproperty 'MS_Description', N'ОГРН', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN', 'ogrn'
go

exec sp_addextendedproperty 'MS_Description', N'КПП', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN', 'kpp'
go

exec sp_addextendedproperty 'MS_Description', N'электронный адрес', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'email'
go

exec sp_addextendedproperty 'MS_Description', N'Тип организации для квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'tip_org_for_account'
go

exec sp_addextendedproperty 'MS_Description', N'строка для печати в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'str_account1'
go

exec sp_addextendedproperty 'MS_Description', N'веб-сайт', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'web_site'
go

exec sp_addextendedproperty 'MS_Description', N'фактический адрес', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all', 'COLUMN',
     'adres_fact'
go

exec sp_addextendedproperty 'MS_Description', N'Режим работы организации', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'rezhim_work'
go

exec sp_addextendedproperty 'MS_Description', N'Метод расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers_all',
     'COLUMN', 'penalty_metod'
go

exec sp_addextendedproperty 'MS_Description', N'Последняя строка в квитанции поставщика', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'LastStrAccount'
go

exec sp_addextendedproperty 'MS_Description', N'Тип лиц.счетов: 1-ЛС УО, 2-ЛС РСО, 3-ЛС КР', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers_all', 'COLUMN', 'tip_occ'
go

