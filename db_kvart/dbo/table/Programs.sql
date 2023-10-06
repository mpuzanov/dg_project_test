create table Programs
(
    id                int                                   not null
        constraint PK_PROGRAMS
            primary key,
    name              varchar(25)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    port_msg          int,
    descriptions      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    app_name_download varchar(25)
        constraint DF_PROGRAMS_app_name_download default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    app_folder        varchar(25)
        constraint DF_PROGRAMS_app_name default ''          not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список программ в системе', 'SCHEMA', 'dbo', 'TABLE', 'Programs'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Programs', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'порт для посылки сообщений', 'SCHEMA', 'dbo', 'TABLE', 'Programs',
     'COLUMN', 'port_msg'
go

exec sp_addextendedproperty 'MS_Description', N'Описание', 'SCHEMA', 'dbo', 'TABLE', 'Programs', 'COLUMN',
     'descriptions'
go

exec sp_addextendedproperty 'MS_Description', N'Имя программы для скачивания(на англ.языке)', 'SCHEMA', 'dbo', 'TABLE',
     'Programs', 'COLUMN', 'app_name_download'
go

