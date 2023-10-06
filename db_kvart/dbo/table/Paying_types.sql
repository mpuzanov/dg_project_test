create table Paying_types
(
    id        varchar(10)                            not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_PAYING_TYPES
            primary key nonclustered,
    name      varchar(50)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    peny_no   bit
        constraint DF_PAYING_TYPES_peny_no default 0 not null,
    is_storno bit default 0                          not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы платежей', 'SCHEMA', 'dbo', 'TABLE', 'Paying_types'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Paying_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Paying_types', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'не использовать в оплате пени', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_types', 'COLUMN', 'peny_no'
go

