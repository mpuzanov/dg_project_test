create table Services_groups
(
    id          int identity
        constraint PK_SERVICES_GROUPS
            primary key,
    name        varchar(50)  not null collate SQL_Latin1_General_CP1251_CI_AS,
    service_str varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Группы услуг (используются в выборках например в перерасчётах)',
     'SCHEMA', 'dbo', 'TABLE', 'Services_groups'
go

exec sp_addextendedproperty 'MS_Description', N'Код группы', 'SCHEMA', 'dbo', 'TABLE', 'Services_groups', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Services_groups', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Список кодов услуг через запятую', 'SCHEMA', 'dbo', 'TABLE',
     'Services_groups', 'COLUMN', 'service_str'
go

