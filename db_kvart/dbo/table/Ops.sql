create table Ops
(
    id       int                             not null
        constraint PK_OPS
            primary key,
    address  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    telephon int,
    name     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    print_id bit
        constraint DF_OPS_print_id default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список ОПС', 'SCHEMA', 'dbo', 'TABLE', 'Ops'
go

exec sp_addextendedproperty 'MS_Description', N'адрес', 'SCHEMA', 'dbo', 'TABLE', 'Ops', 'COLUMN', 'address'
go

exec sp_addextendedproperty 'MS_Description', N'телефон', 'SCHEMA', 'dbo', 'TABLE', 'Ops', 'COLUMN', 'telephon'
go

exec sp_addextendedproperty 'MS_Description', N'наименование отделения почтовой службы', 'SCHEMA', 'dbo', 'TABLE',
     'Ops', 'COLUMN', 'name'
go

