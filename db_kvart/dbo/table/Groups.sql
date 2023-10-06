create table Groups
(
    id   smallint    not null
        constraint PK_GROUPS
            primary key,
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список произвольных групп', 'SCHEMA', 'dbo', 'TABLE', 'Groups'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Groups', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Groups', 'COLUMN', 'name'
go

