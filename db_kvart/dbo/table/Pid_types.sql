create table Pid_types
(
    id   int         not null
        constraint PK_PID_TYPES
            primary key,
    name varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы Претензионно-исковых документов', 'SCHEMA', 'dbo', 'TABLE',
     'Pid_types'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Pid_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Pid_types', 'COLUMN', 'name'
go

