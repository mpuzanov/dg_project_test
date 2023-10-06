create table Counter_log
(
    id         int identity
        constraint PK_COUNTER_LOG
            primary key,
    user_id    smallint,
    op_id      varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit  smalldatetime not null,
    counter_id int           not null,
    comments   varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'История изменения счетчиков', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log'
go

exec sp_addextendedproperty 'MS_Description', N'Код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код операции', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log', 'COLUMN',
     'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата измененния', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'код счетчика', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log', 'COLUMN',
     'counter_id'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Counter_log', 'COLUMN',
     'comments'
go

