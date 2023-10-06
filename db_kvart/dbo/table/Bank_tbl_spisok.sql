create table Bank_tbl_spisok
(
    datafile     smalldatetime                               not null,
    filenamedbf  varchar(100)                                not null collate SQL_Latin1_General_CP1251_CI_AS,
    bank_id      varchar(10)                                 not null collate SQL_Latin1_General_CP1251_CI_AS,
    datavvoda    smalldatetime                               not null,
    forwarded    bit                                         not null,
    kol          int
        constraint DF_BANK_TBL_SPISOK_kol default 0          not null,
    summa        decimal(15, 2)
        constraint DF_BANK_TBL_SPISOK_summa default 0        not null,
    filedbf_id   int identity,
    commission   decimal(9, 2)
        constraint DF_BANK_TBL_SPISOK_commission default 0   not null,
    dbf_tip      tinyint
        constraint DF_BANK_TBL_SPISOK_DBF_TIP default 1      not null,
    sysuser      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    block_import bit
        constraint DF_BANK_TBL_SPISOK_block_import default 0 not null,
    rasschet     varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    data_edit    smalldatetime,
    format_name  varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_BANK_TBL_SPISOK
        primary key (datafile, filenamedbf)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список файлов из банков для ввода платежей', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_tbl_spisok'
go

exec sp_addextendedproperty 'MS_Description', N'дата файла', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'datafile'
go

exec sp_addextendedproperty 'MS_Description', N'название файла', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'filenamedbf'
go

exec sp_addextendedproperty 'MS_Description', N'код банка', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'bank_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата ввода', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'datavvoda'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во документов', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok',
     'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'сумма платежей по файлу', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok',
     'COLUMN', 'summa'
go

exec sp_addextendedproperty 'MS_Description', N'код файла', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'filedbf_id'
go

exec sp_addextendedproperty 'MS_Description', N'комиссия', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'commission'
go

exec sp_addextendedproperty 'MS_Description', N'логин пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok',
     'COLUMN', 'sysuser'
go

exec sp_addextendedproperty 'MS_Description', N'признак блокировки для формирования пачек', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_tbl_spisok', 'COLUMN', 'block_import'
go

exec sp_addextendedproperty 'MS_Description', N'расчётный счёт', 'SCHEMA', 'dbo', 'TABLE', 'Bank_tbl_spisok', 'COLUMN',
     'rasschet'
go

exec sp_addextendedproperty 'MS_Description', N'имя формата загрузки файла', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_tbl_spisok', 'COLUMN', 'format_name'
go

