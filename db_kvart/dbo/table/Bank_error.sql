create table Bank_error
(
    id         int identity
        constraint PK_BANK_ERROR
            primary key,
    data_error datetime     not null,
    error      varchar(200) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список ошибок при импорте платежей из банков', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_error'
go

exec sp_addextendedproperty 'MS_Description', N'порядковый номер', 'SCHEMA', 'dbo', 'TABLE', 'Bank_error', 'COLUMN',
     'id'
go

exec sp_addextendedproperty 'MS_Description', N'дата ошибки', 'SCHEMA', 'dbo', 'TABLE', 'Bank_error', 'COLUMN',
     'data_error'
go

exec sp_addextendedproperty 'MS_Description', N'описание', 'SCHEMA', 'dbo', 'TABLE', 'Bank_error', 'COLUMN', 'error'
go

