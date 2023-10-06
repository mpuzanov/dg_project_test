create table Peny_metod
(
    id          smallint    not null
        constraint PK_PENY_VID
            primary key,
    name        varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    description varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Методы расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod', 'COLUMN', 'name'
go

