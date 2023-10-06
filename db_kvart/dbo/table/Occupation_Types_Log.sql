create table Occupation_Types_Log
(
    id           int identity
        constraint PK_OCCUPATION_TYPES_LOG
            primary key,
    tip_id       smallint not null,
    day_time     datetime not null,
    log_state_id char(4) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал редактирования таблицы OCCUPATION_TYPES', 'SCHEMA', 'dbo',
     'TABLE', 'Occupation_Types_Log'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Occupation_Types_Log',
     'COLUMN', 'tip_id'
go

