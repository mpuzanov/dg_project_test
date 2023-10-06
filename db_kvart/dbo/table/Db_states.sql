create table Db_states
(
    dbstate_id varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_DB_STATES
            primary key nonclustered,
    name       varchar(30)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_current bit
        constraint DF_DB_STATES_is_current default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список режимов базы (только чтение, закрыта)', 'SCHEMA', 'dbo', 'TABLE',
     'Db_states'
go

exec sp_addextendedproperty 'MS_Description', N'код статуса', 'SCHEMA', 'dbo', 'TABLE', 'Db_states', 'COLUMN',
     'dbstate_id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Db_states', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'признак текущего состояния', 'SCHEMA', 'dbo', 'TABLE', 'Db_states',
     'COLUMN', 'is_current'
go

