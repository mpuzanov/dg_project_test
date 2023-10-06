create table Reports_account
(
    ID               int identity
        constraint PK_REPORTS_ACCOUNT
            primary key,
    NAME             varchar(100)                         not null collate SQL_Latin1_General_CP1251_CI_AS,
    FileName         varchar(100)
        constraint DF_REPORTS_ACCOUNT_FileName default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    REPORT_BODY      varbinary(max),
    SIZE_REPORT_BODY decimal(9, 2),
    date_edit        smalldatetime,
    FileDateEdit     smalldatetime,
    visible          bit
        constraint DF_REPORTS_ACCOUNT_visible default 1   not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Файлы Счетов-квитанций в базе данных', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_account'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN', 'ID'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN',
     'NAME'
go

exec sp_addextendedproperty 'MS_Description', N'имя файла квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account',
     'COLUMN', 'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'сам файл', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN',
     'REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'размер файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN',
     'SIZE_REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account', 'COLUMN',
     'FileDateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'Видимость квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account',
     'COLUMN', 'visible'
go

