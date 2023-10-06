create table Users_sup
(
    SYSUSER     nvarchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    ONLY_SUP_ID int          not null,
    constraint PK_USERS_SUP
        primary key (SYSUSER, ONLY_SUP_ID)
)
go

exec sp_addextendedproperty 'MS_Description', N'Доступ пользователя только к конкретному поставщику', 'SCHEMA', 'dbo',
     'TABLE', 'Users_sup'
go

exec sp_addextendedproperty 'MS_Description', N'Логин пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users_sup', 'COLUMN',
     'SYSUSER'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешённый код поставщика ', 'SCHEMA', 'dbo', 'TABLE', 'Users_sup',
     'COLUMN', 'ONLY_SUP_ID'
go

