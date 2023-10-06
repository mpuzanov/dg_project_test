create table Users_pay_orgs
(
    SYSUSER       nvarchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_USERS_PAY_ORGS_USERS
            references Users (login),
    ONLY_PAY_ORGS char(3)      not null collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_USERS_PAY_ORGS_1
        primary key (SYSUSER, ONLY_PAY_ORGS)
)
go

exec sp_addextendedproperty 'MS_Description', N'Доступ пользователей по типам платежей', 'SCHEMA', 'dbo', 'TABLE',
     'Users_pay_orgs'
go

exec sp_addextendedproperty 'MS_Description', N'Логин пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users_pay_orgs',
     'COLUMN', 'SYSUSER'
go

exec sp_addextendedproperty 'MS_Description', N'Код вида платежа (ext)', 'SCHEMA', 'dbo', 'TABLE', 'Users_pay_orgs',
     'COLUMN', 'ONLY_PAY_ORGS'
go

