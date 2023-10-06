create table FileFTP
(
    id         int identity
        constraint PK_FileFTP
            primary key,
    occ        int          not null,
    FileName   varchar(250) not null collate SQL_Latin1_General_CP1251_CI_AS,
    Comments   varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    date_load  smalldatetime,
    user_load  varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    FileSizeKb smallint,
    file_edit  smalldatetime
)
go

exec sp_addextendedproperty 'MS_Description', N'Список файлов на ftp-сервере по лицевому', 'SCHEMA', 'dbo', 'TABLE',
     'FileFTP'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой', 'SCHEMA', 'dbo', 'TABLE', 'FileFTP', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'имя файла', 'SCHEMA', 'dbo', 'TABLE', 'FileFTP', 'COLUMN', 'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'дата загрузки', 'SCHEMA', 'dbo', 'TABLE', 'FileFTP', 'COLUMN',
     'date_load'
go

exec sp_addextendedproperty 'MS_Description', N'пользователь', 'SCHEMA', 'dbo', 'TABLE', 'FileFTP', 'COLUMN',
     'user_load'
go

exec sp_addextendedproperty 'MS_Description', N'размер', 'SCHEMA', 'dbo', 'TABLE', 'FileFTP', 'COLUMN', 'FileSizeKb'
go

