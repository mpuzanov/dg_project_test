create table Op_log_mode
(
    id         int identity
        constraint PK_OP_LOG_MODE
            primary key,
    done       datetime
        constraint DF_OP_LOG_MODE_done default getdate() not null,
    build_id   int                                       not null,
    user_id    int,
    service_id varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    id_old     int,
    id_new     int,
    comments   varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    app        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    is_mode    smallint
        constraint DF_OP_LOG_MODE_is_mode default 1      not null
)
go

exec sp_addextendedproperty 'MS_Description',
     N'Журнал редактирования режимов и поставщиков по домам в Администраторе (Кодификатор)', 'SCHEMA', 'dbo', 'TABLE',
     'Op_log_mode'
go

exec sp_addextendedproperty 'MS_Description', N'дата выполнения', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'done'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN', 'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Старый режим', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'id_old'
go

exec sp_addextendedproperty 'MS_Description', N'Новый режим', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'id_new'
go

exec sp_addextendedproperty 'MS_Description', N'Комметрарий', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Приложение', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode', 'COLUMN', 'app'
go

exec sp_addextendedproperty 'MS_Description', N'1-режимы, 2-поставщики', 'SCHEMA', 'dbo', 'TABLE', 'Op_log_mode',
     'COLUMN', 'is_mode'
go

