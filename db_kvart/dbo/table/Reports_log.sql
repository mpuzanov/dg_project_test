create table Reports_log
(
    id         int identity
        constraint PK_REPORTS_LOG
            primary key,
    ReportName varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    date       smalldatetime,
    UserName   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    KolSec     int,
    query      varchar(4000) collate SQL_Latin1_General_CP1251_CI_AS,
    params     varchar(1000) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Статистика использования отчётов', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_log'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование отчёта', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log', 'COLUMN',
     'ReportName'
go

exec sp_addextendedproperty 'MS_Description', N'дата выполнения отчёта', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log',
     'COLUMN', 'date'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь (Ф.И.О.)', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log',
     'COLUMN', 'UserName'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во секунд', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log', 'COLUMN',
     'KolSec'
go

exec sp_addextendedproperty 'MS_Description', N'запрос в отчёте', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log', 'COLUMN',
     'query'
go

exec sp_addextendedproperty 'MS_Description', N'параметры запроса в отчёте', 'SCHEMA', 'dbo', 'TABLE', 'Reports_log',
     'COLUMN', 'params'
go

