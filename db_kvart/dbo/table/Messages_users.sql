create table Messages_users
(
    id           int identity
        constraint PK_MESSAGES_USERS
            primary key,
    to_login     varchar(30)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    date_msg     smalldatetime not null,
    from_login   nvarchar(30)  not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_MESSAGES_USERS_USERS
            references Users (login),
    msg_text     varchar(500)  not null collate SQL_Latin1_General_CP1251_CI_AS,
    receive      smalldatetime,
    date_timeout smalldatetime,
    to_ip        varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    from_ip      varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    file_msg     varbinary(max),
    FileName_msg varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    id_parent    int
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал сообщений пользователей', 'SCHEMA', 'dbo', 'TABLE',
     'Messages_users'
go

exec sp_addextendedproperty 'MS_Description', N'Кому сообщение', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users', 'COLUMN',
     'to_login'
go

exec sp_addextendedproperty 'MS_Description', N'Дата отправки', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users', 'COLUMN',
     'date_msg'
go

exec sp_addextendedproperty 'MS_Description', N'От кого сообщение', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users',
     'COLUMN', 'from_login'
go

exec sp_addextendedproperty 'MS_Description', N'Текст сообщения', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users', 'COLUMN',
     'msg_text'
go

exec sp_addextendedproperty 'MS_Description', N'Когда получил', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users', 'COLUMN',
     'receive'
go

exec sp_addextendedproperty 'MS_Description', N'С этой даты можно получить сообщение (для напоминаний)', 'SCHEMA',
     'dbo', 'TABLE', 'Messages_users', 'COLUMN', 'date_timeout'
go

exec sp_addextendedproperty 'MS_Description', N'Файл вложение', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users', 'COLUMN',
     'file_msg'
go

exec sp_addextendedproperty 'MS_Description', N'Имя файла вложения', 'SCHEMA', 'dbo', 'TABLE', 'Messages_users',
     'COLUMN', 'FileName_msg'
go

exec sp_addextendedproperty 'MS_Description', N'код владельца письма(на какое ответ)', 'SCHEMA', 'dbo', 'TABLE',
     'Messages_users', 'COLUMN', 'id_parent'
go

