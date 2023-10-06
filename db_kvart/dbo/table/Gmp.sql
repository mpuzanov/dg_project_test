create table Gmp
(
    N_EL_NUM        varchar(50)                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_TYPE_STR      varchar(50)
        constraint DF_GMP_N_TYPE_STR default ''   not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_STATUS_STR    varchar(50)
        constraint DF_GMP_N_STATUS_STR default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_SUMMA         smallmoney
        constraint DF_GMP_N_SUMMA default 0       not null,
    ADDRESS         varchar(100)
        constraint DF_GMP_ADDRESS default '' collate SQL_Latin1_General_CP1251_CI_AS,
    N_PLAT_NAME     varchar(50)
        constraint DF_GMP_N_PLAT_NAME default ''  not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_SUMMA_DOLG    smallmoney
        constraint DF_GMP_N_SUMMA_DOLG default 0  not null,
    N_UIN           varchar(25)
        constraint DF_GMP_N_UIN default ''        not null collate SQL_Latin1_General_CP1251_CI_AS,
    FILE_NAME       varchar(50)
        constraint DF_GMP_FILE_NAME default ''    not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_CUID          varchar(25)
        constraint DF_GMP_N_CUID default ''       not null collate SQL_Latin1_General_CP1251_CI_AS,
    N_DATE_PROVODKA smalldatetime,
    N_DATE_PERIOD   smalldatetime,
    N_RDATE         smalldatetime,
    N_DATE_VVOD     smalldatetime,
    date_edit       smalldatetime,
    user_edit       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    occ             int,
    constraint PK_GMP
        primary key (N_EL_NUM, N_TYPE_STR, N_STATUS_STR)
)
go

exec sp_addextendedproperty 'MS_Description', N'Для обмена данными с ГИС ГМП (по найму)', 'SCHEMA', 'dbo', 'TABLE',
     'Gmp'
go

exec sp_addextendedproperty 'MS_Description', N'Электронный номер начисления', 'SCHEMA', 'dbo', 'TABLE', 'Gmp',
     'COLUMN', 'N_EL_NUM'
go

exec sp_addextendedproperty 'MS_Description', N'Тип начисления: Сальдо, Начислено', 'SCHEMA', 'dbo', 'TABLE', 'Gmp',
     'COLUMN', 'N_TYPE_STR'
go

exec sp_addextendedproperty 'MS_Description', N'Статус начисления: Корректировка, Новый', 'SCHEMA', 'dbo', 'TABLE',
     'Gmp', 'COLUMN', 'N_STATUS_STR'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'N_SUMMA'
go

exec sp_addextendedproperty 'MS_Description', N'Адрес плательщика', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'ADDRESS'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование плательщика', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN',
     'N_PLAT_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Задолженность', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN',
     'N_SUMMA_DOLG'
go

exec sp_addextendedproperty 'MS_Description', N'УИН', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'N_UIN'
go

exec sp_addextendedproperty 'MS_Description', N'Входящий файл', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'FILE_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Уникальный код', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'N_CUID'
go

exec sp_addextendedproperty 'MS_Description', N'Расчётная дата', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN', 'N_RDATE'
go

exec sp_addextendedproperty 'MS_Description', N'Дата ввода документа', 'SCHEMA', 'dbo', 'TABLE', 'Gmp', 'COLUMN',
     'N_DATE_VVOD'
go

