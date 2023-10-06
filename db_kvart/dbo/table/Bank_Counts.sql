create table Bank_Counts
(
    id         int identity
        constraint PK_BankCounts
            primary key,
    owner_id   int                                    not null,
    active     bit
        constraint DF_BANK_COUNTS_active_id default 1 not null,
    bank_id    int                                    not null,
    name       varchar(30)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    number     varchar(20)                            not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_BANK_COUNTS
            check (len([number]) = 20),
    number2    varchar(2) collate SQL_Latin1_General_CP1251_CI_AS,
    data_open  smalldatetime,
    data_close smalldatetime,
    user_edit  int,
    date_edit  smalldatetime,
    otd        char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    fil        char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    kodi       char(2) collate SQL_Latin1_General_CP1251_CI_AS,
    tnomer     char(7) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Банковские счета получателей субсидий', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_Counts'
go

exec sp_addextendedproperty 'MS_Description', N'счёт', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Counts', 'COLUMN', 'number'
go

exec sp_addextendedproperty 'MS_Description', N'вид вклада', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Counts', 'COLUMN',
     'number2'
go

exec sp_addextendedproperty 'MS_Description', N'Номер отделения Сбербанка России', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_Counts', 'COLUMN', 'otd'
go

exec sp_addextendedproperty 'MS_Description', N'Номер стрктурного подразделения Сбербанка', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_Counts', 'COLUMN', 'fil'
go

exec sp_addextendedproperty 'MS_Description', N'Код платеж', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Counts', 'COLUMN', 'kodi'
go

exec sp_addextendedproperty 'MS_Description', N'служебная информация', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Counts',
     'COLUMN', 'tnomer'
go

