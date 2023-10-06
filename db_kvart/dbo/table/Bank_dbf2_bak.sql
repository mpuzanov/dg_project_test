create table Bank_dbf2_bak
(
    ID         int identity
        constraint PK_BANK_DBF2
            primary key,
    filedbf_id int           not null,
    BANK_ID    char(3)       not null collate SQL_Latin1_General_CP1251_CI_AS,
    GRP        int,
    SCH_LIC    int,
    SUM_OPL    decimal(9, 2),
    PDATE      smalldatetime not null,
    P_OPL      smallint,
    OCC        int,
    SERVICE_ID char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    ADRES      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    FIO        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    PACK_ID    int,
    DATE_EDIT  smalldatetime,
    sup_id     int,
    dog_int    nchar(10) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список платежей по взаимозачетам', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_dbf2_bak'
go

