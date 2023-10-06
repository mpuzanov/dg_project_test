create table Standart
(
    id       int identity
        constraint PK_STANDART
            primary key,
    name     varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Стандарты жилья для субсидий', 'SCHEMA', 'dbo', 'TABLE', 'Standart'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Standart', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Standart', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Standart', 'COLUMN', 'comments'
go

