create table Occ_not_print
(
    occ       int                                  not null,
    flag      bit
        constraint DF_OCC_NOT_print_flag default 1 not null,
    address   varchar(60) collate SQL_Latin1_General_CP1251_CI_AS,
    comments  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit smalldatetime,
    user_edit smallint,
    constraint PK_OCC_NOT_print
        primary key (occ, flag)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список лицевых по которым не печатаються квитанции', 'SCHEMA', 'dbo',
     'TABLE', 'Occ_not_print'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Occ_not_print', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Доп. параметр для печати', 'SCHEMA', 'dbo', 'TABLE', 'Occ_not_print',
     'COLUMN', 'flag'
go

