create table Op_Log
(
    id       int identity
        constraint PK_OP_LOG
            primary key,
    op_id    varchar(10)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    done     smalldatetime
        constraint DF_Op_Log_done default getdate() not null,
    occ      int                                    not null
        constraint FK_Op_Log_Occupations
            references Occupations
            on update cascade on delete cascade,
    user_id  smallint,
    comments varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    comp     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал редактирования в базе пользователями', 'SCHEMA', 'dbo', 'TABLE',
     'Op_Log'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN', 'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата выполнения', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN', 'done'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN', 'comments'
go

exec sp_addextendedproperty 'MS_Description', N'имя компьютера', 'SCHEMA', 'dbo', 'TABLE', 'Op_Log', 'COLUMN', 'comp'
go

