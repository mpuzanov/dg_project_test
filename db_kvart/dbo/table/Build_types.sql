create table Build_types
(
    id   smallint    not null
        constraint PK_BUILD_TYPES
            primary key,
    name varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы жилых домов', 'SCHEMA', 'dbo', 'TABLE', 'Build_types'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Build_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Build_types', 'COLUMN', 'name'
go

