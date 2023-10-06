create table Cons_modes
(
    id         int         not null
        constraint PK_Cons_modes
            primary key,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    name       varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id    varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список возможных Режимов потребления', 'SCHEMA', 'dbo', 'TABLE',
     'Cons_modes'
go

exec sp_addextendedproperty 'MS_Description', N'код режима', 'SCHEMA', 'dbo', 'TABLE', 'Cons_modes', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Cons_modes', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'название режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Cons_modes',
     'COLUMN', 'name'
go

