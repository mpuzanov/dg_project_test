create table Bank_format
(
    ID               int identity
        constraint PK_BANK_FORMAT
            primary key,
    NAME             varchar(50)                                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    VISIBLE          bit
        constraint DF_BANK_FORMAT_VISIBLE default 1                     not null,
    EXT              char(3)                                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    CODE_PAGE        varchar(5) collate SQL_Latin1_General_CP1251_CI_AS,
    EXT_BANK         varchar(10)
        constraint DF_BANK_FORMAT_EXT_BANK default 0 collate SQL_Latin1_General_CP1251_CI_AS,
    CHAR_ZAG         char collate SQL_Latin1_General_CP1251_CI_AS,
    CHAR_RAZD        char collate SQL_Latin1_General_CP1251_CI_AS,
    LIC_NO           smallint,
    LIC_SIZE         smallint,
    LIC_NAME         varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    DATA_PLAT_NO     smallint,
    DATA_PLAT_Format varchar(30)
        constraint DF_Bank_format_DATA_PLAT_Format default 'dd.mm.yyyy' not null collate SQL_Latin1_General_CP1251_CI_AS,
    DATA_PLAT_SIZE   smallint,
    DATESEPARATOR    char
        constraint DF_BANK_FORMAT_DATESEPARATOR default '/' collate SQL_Latin1_General_CP1251_CI_AS,
    DECIMALSEPARATOR char
        constraint DF_BANK_FORMAT_DECIMALSEPARATOR default '.' collate SQL_Latin1_General_CP1251_CI_AS,
    SUMMA_NO         smallint,
    SUMMA_SIZE       smallint,
    ADRES_NO         smallint,
    ADRES_SIZE       smallint,
    ADRES_NAME       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    ADRES_MERGE_COL  smallint,
    FILENAME_FILTER  varchar(100)
        constraint DF_BANK_FORMAT_FILENAME_FILTER default '*.*' collate SQL_Latin1_General_CP1251_CI_AS,
    COMMIS_NO        smallint,
    RASCH_NAME       varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    RASCH_NO         smallint,
    SERVICE_NO       smallint,
    date_edit        smalldatetime,
    FIO_NO           smallint,
    format_json      nvarchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    min_len_str      smallint
        constraint DF_Bank_format_max_len_str default 40                not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Форматы файлов с платежами для импорта', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format'
go

exec sp_addextendedproperty 'MS_Description', N'Описание формата', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Видимость формата', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'VISIBLE'
go

exec sp_addextendedproperty 'MS_Description', N'Расширение файла', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'EXT'
go

exec sp_addextendedproperty 'MS_Description', N'кодировка файла ASCII, DOS', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'CODE_PAGE'
go

exec sp_addextendedproperty 'MS_Description', N'код вида платежа банка (S90,S96,853)', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format', 'COLUMN', 'EXT_BANK'
go

exec sp_addextendedproperty 'MS_Description', N'первый символ заголовка файла', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'CHAR_ZAG'
go

exec sp_addextendedproperty 'MS_Description', N'символ разделитель строки', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'CHAR_RAZD'
go

exec sp_addextendedproperty 'MS_Description', N'номер колонки с лицевым счётом', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format', 'COLUMN', 'LIC_NO'
go

exec sp_addextendedproperty 'MS_Description', N'размер лицевого счёта', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'LIC_SIZE'
go

exec sp_addextendedproperty 'MS_Description', N'Список наименований лиц.счетов в файле через запятую', 'SCHEMA', 'dbo',
     'TABLE', 'Bank_format', 'COLUMN', 'LIC_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'номер колонки с датой платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'DATA_PLAT_NO'
go

exec sp_addextendedproperty 'MS_Description', N'размер даты платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'DATA_PLAT_SIZE'
go

exec sp_addextendedproperty 'MS_Description', N'символ разделитель в дате', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'DATESEPARATOR'
go

exec sp_addextendedproperty 'MS_Description', N'символ разделитель в сумме оплаты', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format', 'COLUMN', 'DECIMALSEPARATOR'
go

exec sp_addextendedproperty 'MS_Description', N'позиция с суммой', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'SUMMA_NO'
go

exec sp_addextendedproperty 'MS_Description', N'номер колонки с адресом', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'ADRES_NO'
go

exec sp_addextendedproperty 'MS_Description', N'Размер строки с адресом', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'ADRES_SIZE'
go

exec sp_addextendedproperty 'MS_Description', N'слово перед адресом', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'ADRES_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во колонок, для объеденения в адресе', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format', 'COLUMN', 'ADRES_MERGE_COL'
go

exec sp_addextendedproperty 'MS_Description', N'Шаблон для выбора файлов', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'FILENAME_FILTER'
go

exec sp_addextendedproperty 'MS_Description', N'номер колонки с коммиссией', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'COMMIS_NO'
go

exec sp_addextendedproperty 'MS_Description', N'слово перед расчётным счётом', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'RASCH_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Позиция с расчётным счётом', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'RASCH_NO'
go

exec sp_addextendedproperty 'MS_Description', N'номер колонки с услугой', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format',
     'COLUMN', 'SERVICE_NO'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'позиция с ФИО', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format', 'COLUMN',
     'FIO_NO'
go

exec sp_addextendedproperty 'MS_Description', N'Минимальная длина строки реестра для обработки', 'SCHEMA', 'dbo',
     'TABLE', 'Bank_format', 'COLUMN', 'min_len_str'
go

