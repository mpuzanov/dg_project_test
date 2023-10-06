create table Property_types
(
    id   varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_Room_types
            primary key nonclustered,
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Статусы квартир', 'SCHEMA', 'dbo', 'TABLE', 'Property_types'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Property_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Property_types', 'COLUMN', 'name'
go

