create table Operations
(
    op_id varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_OPERATIONS
            primary key,
    name  varchar(30)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    op_no smallint
        constraint DF_OPERATIONS_op_no default 100 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды операций в базе по которым ведется ограничение доступа', 'SCHEMA',
     'dbo', 'TABLE', 'Operations'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Operations', 'COLUMN', 'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Operations', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Operations', 'COLUMN',
     'op_no'
go

