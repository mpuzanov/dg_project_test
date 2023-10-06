create table Progress_proces
(
    id           int identity
        constraint PK_PROGRESS_PROCES
            primary key,
    comp         varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Descriptions varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    datetime     datetime
        constraint DF_PROGRESS_PROCES_datetime default getdate() not null,
    is_read      bit
        constraint DF_PROGRESS_PROCES_is_read default 0          not null,
    user_fio     varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица прогресса процесса (при закрытии фин.периода)', 'SCHEMA', 'dbo',
     'TABLE', 'Progress_proces'
go

