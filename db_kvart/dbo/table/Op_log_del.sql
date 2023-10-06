create table Op_log_del
(
    id      int identity
        constraint PK_OP_LOG_DEL
            primary key,
    user_id int      not null,
    op_id   char(4)  not null collate SQL_Latin1_General_CP1251_CI_AS,
    done    datetime not null,
    occ     int      not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал удаленных лицевых счетов', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_del'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_del', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_del', 'COLUMN', 'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата выполнения операции', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_del',
     'COLUMN', 'done'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_del', 'COLUMN', 'occ'
go

