create table Koef
(
    id         int                             not null
        constraint PK_KOEF
            primary key nonclustered,
    is_build   bit
        constraint DF_KOEF_is_build default 0  not null,
    service_id varchar(10)                     not null collate SQL_Latin1_General_CP1251_CI_AS,
    level1     int                             not null,
    level2     int                             not null,
    name       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    value      smallmoney,
    id_parent  int
        constraint DF_KOEF_id_parent default 0 not null,
    is_use     bit
        constraint DF_KOEF_is_use default 1    not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды коэффициентов по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Koef'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Коэф. используется для дома', 'SCHEMA', 'dbo', 'TABLE', 'Koef',
     'COLUMN', 'is_build'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'уровень 1', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'level1'
go

exec sp_addextendedproperty 'MS_Description', N'уровень 2', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'level2'
go

exec sp_addextendedproperty 'MS_Description', N'Описание', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'значение коэф.', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'код родителя', 'SCHEMA', 'dbo', 'TABLE', 'Koef', 'COLUMN', 'id_parent'
go

exec sp_addextendedproperty 'MS_Description', N'Коэф. используется в расчётах', 'SCHEMA', 'dbo', 'TABLE', 'Koef',
     'COLUMN', 'is_use'
go

