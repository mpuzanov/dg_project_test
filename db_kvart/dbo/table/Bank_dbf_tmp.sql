create table Bank_dbf_tmp
(
    ID          int identity
        constraint PK_BANK_DBF_TMP
            primary key,
    FILENAMEDBF varchar(100)  not null collate SQL_Latin1_General_CP1251_CI_AS,
    DATA_PAYM   smalldatetime not null,
    BANK_ID     varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    SUM_OPL     decimal(9, 2) not null,
    PDATE       smalldatetime not null,
    GRP         smallint,
    OCC         int,
    SERVICE_ID  varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    SCH_LIC     bigint,
    PACK_ID     int,
    P_OPL       smallint,
    ADRES       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    FIO         varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    SUP_ID      int
        constraint DF_BANK_DBF_TMP_SUP_ID default 0,
    COMMISSION  decimal(9, 2),
    DOG_INT     int,
    rasschet    varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    data_edit   smalldatetime,
    sysuser     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Временный файл для импорта платежей из банков', 'SCHEMA', 'dbo',
     'TABLE', 'Bank_dbf_tmp'
go

