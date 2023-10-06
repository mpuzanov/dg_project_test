create table Occ_Statuses
(
    id   varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_OCC_STATUSES
            primary key,
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Статусы лицевых счетов (откр,своб,закр)', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Statuses'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Statuses', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Statuses', 'COLUMN', 'name'
go

