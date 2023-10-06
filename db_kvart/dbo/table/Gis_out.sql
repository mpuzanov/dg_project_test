create table Gis_out
(
    shablon_id varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    versia     varchar(20) not null collate SQL_Latin1_General_CP1251_CI_AS,
    num_list   smallint    not null,
    num_col    smallint    not null,
    field_name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_GIS_OUT_1
        primary key (shablon_id, versia, num_list, num_col, field_name)
)
go

exec sp_addextendedproperty 'MS_Description', N'Параметры выгрузки из шаблонов в Excel', 'SCHEMA', 'dbo', 'TABLE',
     'Gis_out'
go

exec sp_addextendedproperty 'MS_Description', N'Код шаблона', 'SCHEMA', 'dbo', 'TABLE', 'Gis_out', 'COLUMN',
     'shablon_id'
go

exec sp_addextendedproperty 'MS_Description', N'Версия', 'SCHEMA', 'dbo', 'TABLE', 'Gis_out', 'COLUMN', 'versia'
go

exec sp_addextendedproperty 'MS_Description', N'Номер листа Excel', 'SCHEMA', 'dbo', 'TABLE', 'Gis_out', 'COLUMN',
     'num_list'
go

exec sp_addextendedproperty 'MS_Description', N'Номер колонки Excel', 'SCHEMA', 'dbo', 'TABLE', 'Gis_out', 'COLUMN',
     'num_col'
go

exec sp_addextendedproperty 'MS_Description', N'Имя поля', 'SCHEMA', 'dbo', 'TABLE', 'Gis_out', 'COLUMN', 'field_name'
go

