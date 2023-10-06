create table Organ_spravka
(
    id         int identity
        constraint PK_ORGAN_SPRAVKA
            primary key,
    name       varchar(100)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_pasport bit
        constraint DF_ORGAN_SPRAVKA_is_pasport default 0 not null,
    kod_pvs    varchar(7) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список организация для выдачи справок', 'SCHEMA', 'dbo', 'TABLE',
     'Organ_spravka'
go

exec sp_addextendedproperty 'MS_Description', N'Код организации', 'SCHEMA', 'dbo', 'TABLE', 'Organ_spravka', 'COLUMN',
     'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Organ_spravka', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'признак паспорта', 'SCHEMA', 'dbo', 'TABLE', 'Organ_spravka', 'COLUMN',
     'is_pasport'
go

exec sp_addextendedproperty 'MS_Description', N'код ПВС', 'SCHEMA', 'dbo', 'TABLE', 'Organ_spravka', 'COLUMN', 'kod_pvs'
go

