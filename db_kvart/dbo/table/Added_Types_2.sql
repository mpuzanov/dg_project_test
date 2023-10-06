create table Added_Types_2
(
    id   smallint not null
        constraint PK_ADDED_TYPES_2
            primary key,
    name varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'типы некачественого предоставления', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Types_2'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types_2', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types_2', 'COLUMN',
     'name'
go

