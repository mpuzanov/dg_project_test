create table Bank_tbl_spisok2
(
    DataFile    smalldatetime not null,
    FileNameDbf varchar(30)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    bank_id     varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    DataVvoda   smalldatetime not null,
    forwarded   bit           not null,
    kol         int,
    summa       decimal(15, 2),
    filedbf_id  int identity,
    filedbf_id2 int,
    constraint PK_BANK_TBL_SPISOK2_1
        primary key (DataFile, FileNameDbf)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список файлов по взаимозачетам для ввода платежей', 'SCHEMA', 'dbo',
     'TABLE', 'Bank_tbl_spisok2'
go

