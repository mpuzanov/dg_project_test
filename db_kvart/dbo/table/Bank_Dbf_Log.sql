create table Bank_Dbf_Log
(
    id        int identity
        constraint PK_BANK_DBF_LOG
            primary key,
    user_id   int           not null,
    dateEdit  smalldatetime not null,
    kod_paym  int           not null,
    occ1      varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    adres1    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    occ2      varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    adres2    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    comments  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    pdate1    smalldatetime,
    pdate2    smalldatetime,
    rasschet1 varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    rasschet2 varchar(20) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Редактирование платежей из банков', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_Dbf_Log'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log',
     'COLUMN', 'dateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа из BANK_DBF', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log',
     'COLUMN', 'kod_paym'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой перед изменением', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log',
     'COLUMN', 'occ1'
go

exec sp_addextendedproperty 'MS_Description', N'адрес перед изменением', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log',
     'COLUMN', 'adres1'
go

exec sp_addextendedproperty 'MS_Description', N'новое значение', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log', 'COLUMN',
     'occ2'
go

exec sp_addextendedproperty 'MS_Description', 'Qdoc', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log', 'COLUMN', 'adres2'
go

exec sp_addextendedproperty 'MS_Description', N'причина изменения', 'SCHEMA', 'dbo', 'TABLE', 'Bank_Dbf_Log', 'COLUMN',
     'comments'
go

