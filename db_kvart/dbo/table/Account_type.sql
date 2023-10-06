create table Account_type
(
    id       smallint    not null
        constraint PK_ACCOUNT_TYPE
            primary key,
    name     varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    filename varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы квитанций', 'SCHEMA', 'dbo', 'TABLE', 'Account_type'
go

