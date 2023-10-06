create table Account_email
(
    id         int identity
        constraint PK_Account_email
            primary key,
    fin_id     smallint                                  not null,
    occ        int                                       not null,
    fileName   varchar(50)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    account_id int
        constraint DF_ACCOUNT_EMAIL_account_id default 0 not null,
    dateCreate datetime,
    email_out  bit
        constraint DF_ACCOUNT_EMAIL_email_out default 0,
    dateOut    datetime,
    email      varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    email_log  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    SumPaym    decimal(9, 2),
    sysuser    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    dir        varchar(200) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Квитанции для отправки гражданам', 'SCHEMA', 'dbo', 'TABLE',
     'Account_email'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Account_email', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Account_email', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Имя сформированного файла с квитанцией', 'SCHEMA', 'dbo', 'TABLE',
     'Account_email', 'COLUMN', 'fileName'
go

exec sp_addextendedproperty 'MS_Description', N'Код используемой квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Account_email',
     'COLUMN', 'account_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата формирования файла', 'SCHEMA', 'dbo', 'TABLE', 'Account_email',
     'COLUMN', 'dateCreate'
go

exec sp_addextendedproperty 'MS_Description', N'признак отправки по почте', 'SCHEMA', 'dbo', 'TABLE', 'Account_email',
     'COLUMN', 'email_out'
go

exec sp_addextendedproperty 'MS_Description', N'дата отправки по почте', 'SCHEMA', 'dbo', 'TABLE', 'Account_email',
     'COLUMN', 'dateOut'
go

exec sp_addextendedproperty 'MS_Description', N'Код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Account_email', 'COLUMN',
     'sysuser'
go

