create table Op_log_adm
(
    id       int identity
        constraint PK_OP_LOG_ADM
            primary key,
    done     smalldatetime not null,
    user_id  smallint      not null,
    op_id    char(4)       not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments varchar(200) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал изменений по работе в Администраторе', 'SCHEMA', 'dbo', 'TABLE',
     'Op_log_adm'
go

exec sp_addextendedproperty 'MS_Description', N'дата выполнения операции', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_adm',
     'COLUMN', 'done'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_adm', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_adm', 'COLUMN', 'op_id'
go

