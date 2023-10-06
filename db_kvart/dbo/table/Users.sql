create table Users
(
    id                  smallint identity
        constraint PK_USERS
            primary key
        constraint FK_USERS_USERS
            references Users,
    last_name           varchar(30)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    first_name          varchar(30)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    second_name         varchar(30)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    login               nvarchar(30)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    pswd                varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    pswd_encrypt        varbinary(128),
    comments            varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    email               varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    foto                varbinary(max),
    blocked             bit
        constraint DF_USERS_blocked default 0             not null,
    blocked_personal    bit
        constraint DF_USERS_blocked_personal default 0    not null,
    Initials            as rtrim([Last_name]) + case
                                                    when rtrim([First_name]) <> ''
                                                        then ' ' + substring(rtrim([First_name]), 1, 1) + '.'
                                                    else '' end + case
                                                                      when rtrim([Second_name]) <> ''
                                                                          then substring(rtrim([Second_name]), 1, 1) + '.'
                                                                      else '' end collate SQL_Latin1_General_CP1251_CI_AS,
    SuperAdmin          bit
        constraint DF_USERS_SuperAdm default 0            not null,
    Only_sup            int,
    blocked_export      bit
        constraint DF_USERS_blocked_export default 0      not null,
    blocked_print       bit
        constraint DF_USERS_blocked_print default 0       not null,
    last_connect        smalldatetime,
    date_edit           smalldatetime,
    user_edit           varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    is_developer        bit
        constraint DF_Users_is_developer default 0        not null,
    is_get_mail_service bit
        constraint DF_Users_is_get_mail_service default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Пользователи системы', 'SCHEMA', 'dbo', 'TABLE', 'Users'
go

exec sp_addextendedproperty 'MS_Description', N'Код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Фамилия', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'last_name'
go

exec sp_addextendedproperty 'MS_Description', N'Имя', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'first_name'
go

exec sp_addextendedproperty 'MS_Description', N'Отчество', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'second_name'
go

exec sp_addextendedproperty 'MS_Description', N'имя входа', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'login'
go

exec sp_addextendedproperty 'MS_Description', N'пароль', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'pswd'
go

exec sp_addextendedproperty 'MS_Description', N'Зашифрованный пароль', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'pswd_encrypt'
go

exec sp_addextendedproperty 'MS_Description', N'коментарий', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Почтовый адрес', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'email'
go

exec sp_addextendedproperty 'MS_Description', N'Фотография', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'foto'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка доступа в базу', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'blocked'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировка доступа к персональным данным', 'SCHEMA', 'dbo', 'TABLE',
     'Users', 'COLUMN', 'blocked_personal'
go

exec sp_addextendedproperty 'MS_Description', N'Ф.И.О. пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'Initials'
go

exec sp_addextendedproperty 'MS_Description', N'Признак суперадмина', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'SuperAdmin'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика (Доступ только к данному поставщику)', 'SCHEMA', 'dbo',
     'TABLE', 'Users', 'COLUMN', 'Only_sup'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать экспорт отчётов пользователю', 'SCHEMA', 'dbo', 'TABLE',
     'Users', 'COLUMN', 'blocked_export'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать печать отчётов пользователю', 'SCHEMA', 'dbo', 'TABLE',
     'Users', 'COLUMN', 'blocked_print'
go

exec sp_addextendedproperty 'MS_Description', N'Последнее подключение пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users',
     'COLUMN', 'last_connect'
go

exec sp_addextendedproperty 'MS_Description', N'Дата последнего изменения', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Последний кто редактировал', 'SCHEMA', 'dbo', 'TABLE', 'Users',
     'COLUMN', 'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Признак разработчика', 'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN',
     'is_developer'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешено получать сервисные сообщения от сервера', 'SCHEMA', 'dbo',
     'TABLE', 'Users', 'COLUMN', 'is_get_mail_service'
go

