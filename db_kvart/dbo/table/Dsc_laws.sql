create table Dsc_laws
(
    id   int         not null
        constraint PK_DSC_LAWS
            primary key,
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список законов по льготам', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_laws'
go

exec sp_addextendedproperty 'MS_Description', N'код закона', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_laws', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_laws', 'COLUMN', 'name'
go

