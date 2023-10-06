create table Divisions
(
    id           smallint    not null
        constraint PK_Divisions
            primary key,
    name         varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    bank_id      smallint,
    name2        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    name3        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    bank_account int,
    town_id      smallint
)
go

exec sp_addextendedproperty 'MS_Description', N'Список районов', 'SCHEMA', 'dbo', 'TABLE', 'Divisions'
go

exec sp_addextendedproperty 'MS_Description', N'Код района', 'SCHEMA', 'dbo', 'TABLE', 'Divisions', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Divisions', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'код банка, обсуживающего район', 'SCHEMA', 'dbo', 'TABLE', 'Divisions',
     'COLUMN', 'bank_id'
go

exec sp_addextendedproperty 'MS_Description', N'код населённого пункта', 'SCHEMA', 'dbo', 'TABLE', 'Divisions',
     'COLUMN', 'town_id'
go

