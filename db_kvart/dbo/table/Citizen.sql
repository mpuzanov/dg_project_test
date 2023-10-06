create table Citizen
(
    id   int         not null
        constraint PK_CITIZEN
            primary key,
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Гражданство', 'SCHEMA', 'dbo', 'TABLE', 'Citizen'
go

exec sp_addextendedproperty 'MS_Description', N'Код гражданства', 'SCHEMA', 'dbo', 'TABLE', 'Citizen', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Citizen', 'COLUMN', 'name'
go

