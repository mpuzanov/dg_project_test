create table Bank_Dbf
(
    id         int identity
        constraint PK_BANK_DBF
            primary key,
    bank_id    varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    filedbf_id int                                  not null
        constraint FK_BANK_DBF_BANK_TBL_SPISOK
            references Bank_tbl_spisok (filedbf_id),
    sum_opl    decimal(9, 2)
        constraint DF_BANK_DBF_sum_opl default 0    not null,
    pdate      smalldatetime                        not null,
    occ        int,
    sch_lic    bigint,
    p_opl      smallint,
    adres      varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    pack_id    int,
    service_id varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    grp        smallint,
    date_edit  smalldatetime,
    sup_id     int
        constraint DF_BANK_DBF_SUP_ID default 0     not null,
    commission decimal(9, 2)
        constraint DF_BANK_DBF_commission default 0 not null,
    dog_int    int,
    dbf_tip    smallint
        constraint DF_BANK_DBF_DBF_TIP default 1    not null,
    rasschet   varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    error_num  smallint,
    sysuser    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    fio        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список платежей из банков', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код банка', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'bank_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код файла (из BANK_TBL_SPISOK)', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf',
     'COLUMN', 'filedbf_id'
go

exec sp_addextendedproperty 'MS_Description', N'сумма платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'sum_opl'
go

exec sp_addextendedproperty 'MS_Description', N'дата платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'pdate'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'старый лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'sch_lic'
go

exec sp_addextendedproperty 'MS_Description', N'месяц платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'p_opl'
go

exec sp_addextendedproperty 'MS_Description', N'адрес', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'adres'
go

exec sp_addextendedproperty 'MS_Description', N'номер пачки если платеж закрыт', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf',
     'COLUMN', 'pack_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги если есть', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'номер участка', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'grp'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Комиссия платежа', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'commission'
go

exec sp_addextendedproperty 'MS_Description', N'код договора', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'dog_int'
go

exec sp_addextendedproperty 'MS_Description', N'расчётный счёт', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN',
     'rasschet'
go

exec sp_addextendedproperty 'MS_Description', N'код ошибки', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf', 'COLUMN', 'error_num'
go

