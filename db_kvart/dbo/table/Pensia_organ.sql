create table Pensia_organ
(
    id   smallint not null
        constraint PK_PENSIA_ORGAN
            primary key,
    name varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список организаций по социальной работе', 'SCHEMA', 'dbo', 'TABLE',
     'Pensia_organ'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Pensia_organ', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название организации', 'SCHEMA', 'dbo', 'TABLE', 'Pensia_organ',
     'COLUMN', 'name'
go

