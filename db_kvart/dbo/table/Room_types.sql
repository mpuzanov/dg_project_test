create table Room_types
(
    id        varchar(10)                                not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_Property_types
            primary key nonclustered,
    name      varchar(30)                                not null collate SQL_Latin1_General_CP1251_CI_AS,
    name_kvit varchar(10)
        constraint DF_Room_types_name_kvit default 'кв.' not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы квартир', 'SCHEMA', 'dbo', 'TABLE', 'Room_types'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Room_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Room_types', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'обозначение помещения в адресе', 'SCHEMA', 'dbo', 'TABLE', 'Room_types',
     'COLUMN', 'name_kvit'
go

