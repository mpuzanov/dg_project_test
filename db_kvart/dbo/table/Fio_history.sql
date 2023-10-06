create table Fio_history
(
    id          int identity
        constraint PK_Fio_history_1
            primary key,
    owner_id    int           not null,
    date_change smalldatetime not null,
    Last_name   varchar(50)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    First_name  varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    Second_name varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    sysuser     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'История изменений ФИО жителей', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history'
go

exec sp_addextendedproperty 'MS_Description', N'код гражданина', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history', 'COLUMN',
     'date_change'
go

exec sp_addextendedproperty 'MS_Description', N'Фамилия', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history', 'COLUMN', 'Last_name'
go

exec sp_addextendedproperty 'MS_Description', N'Имя', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history', 'COLUMN', 'First_name'
go

exec sp_addextendedproperty 'MS_Description', N'Отчество', 'SCHEMA', 'dbo', 'TABLE', 'Fio_history', 'COLUMN',
     'Second_name'
go

exec sp_addextendedproperty 'MS_Description', N'Изменявший Ф.И.О. пользователь', 'SCHEMA', 'dbo', 'TABLE',
     'Fio_history', 'COLUMN', 'sysuser'
go

