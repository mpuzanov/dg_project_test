create table Bank_dbf2_tmp
(
    ID          int identity
        constraint PK_BANK_DBF2_TMP
            primary key,
    FILENAMEDBF varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DATA_PAYM   smalldatetime,
    BANK_ID     varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    GRP         int,
    SCH_LIC     int,
    SUM_OPL     money,
    PDATE       smalldatetime,
    P_OPL       smallint,
    OCC         int,
    SERVICE_ID  varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    ADRES       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    FIO         varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    PACK_ID     int,
    DATE_EDIT   smalldatetime,
    sup_id      int,
    dog_int     int,
    COMMISSION  decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Временный файл для импорта платежей по взаимозачетам', 'SCHEMA', 'dbo',
     'TABLE', 'Bank_dbf2_tmp'
go

