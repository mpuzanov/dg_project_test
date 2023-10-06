create table Bank
(
    id         int                           not null
        constraint PK_BANK
            primary key,
    short_name varchar(30)                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_bank    bit
        constraint DF_BANK_is_bank default 0 not null,
    bank_uid   uniqueidentifier,
    name       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    bank       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    rasscht    varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    korscht    varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    bik        varchar(9) collate SQL_Latin1_General_CP1251_CI_AS,
    inn        varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    comments   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    data_edit  smalldatetime,
    user_id    smallint,
    visible    bit
        constraint DF_Bank_visible default 1 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список банков и организация для ввода платежей', 'SCHEMA', 'dbo',
     'TABLE', 'Bank'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'кор. название', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'short_name'
go

exec sp_addextendedproperty 'MS_Description', N'признак банка', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'is_bank'
go

exec sp_addextendedproperty 'MS_Description', N'строка 1 в квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'название банка', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'bank'
go

exec sp_addextendedproperty 'MS_Description', N'расч. счет', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'rasscht'
go

exec sp_addextendedproperty 'MS_Description', N'кор. счет', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'korscht'
go

exec sp_addextendedproperty 'MS_Description', N'БИК', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'bik'
go

exec sp_addextendedproperty 'MS_Description', N'ИНН', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'inn'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN',
     'data_edit'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Bank', 'COLUMN', 'user_id'
go

