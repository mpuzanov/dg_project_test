create table Towns
(
    ID               smallint    not null
        constraint PK_TOWNS
            primary key,
    NAME             varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    prefix           varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    oktmo            varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    okato            varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    kod_fias         varchar(36) collate SQL_Latin1_General_CP1251_CI_AS,
    region           varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    region_short     varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    full_name        varchar(60) collate SQL_Latin1_General_CP1251_CI_AS,
    full_name_region varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Населённые пункты', 'SCHEMA', 'dbo', 'TABLE', 'Towns'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'ID'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Сокращение', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'prefix'
go

exec sp_addextendedproperty 'MS_Description', N'Общероссийский классификатор территорий муниципальных образований',
     'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'oktmo'
go

exec sp_addextendedproperty 'MS_Description', N'общероссийский классификатор административно-территориальных объектов',
     'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'okato'
go

exec sp_addextendedproperty 'MS_Description', N'Код ФИАС', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'kod_fias'
go

exec sp_addextendedproperty 'MS_Description', N'Регион', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN', 'region'
go

exec sp_addextendedproperty 'MS_Description', N'Сокращение региона', 'SCHEMA', 'dbo', 'TABLE', 'Towns', 'COLUMN',
     'region_short'
go

