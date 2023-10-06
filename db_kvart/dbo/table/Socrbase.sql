create table Socrbase
(
    SCNAME   varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_SOCRBASE
            primary key,
    SOCRNAME varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список адресных сокращений', 'SCHEMA', 'dbo', 'TABLE', 'Socrbase'
go

exec sp_addextendedproperty 'MS_Description', N'сокращение', 'SCHEMA', 'dbo', 'TABLE', 'Socrbase', 'COLUMN', 'SCNAME'
go

exec sp_addextendedproperty 'MS_Description', N'расшифровка', 'SCHEMA', 'dbo', 'TABLE', 'Socrbase', 'COLUMN', 'SOCRNAME'
go

