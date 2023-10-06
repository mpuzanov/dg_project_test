create table Units
(
    id        varchar(10)                        not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_UNITS
            primary key nonclustered,
    name      varchar(30)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    short_id  varchar(6)                         not null collate SQL_Latin1_General_CP1251_CI_AS,
    precision smallint
        constraint DF_UNITS_precision default 0  not null,
    short_id2 varchar(6)
        constraint DF_UNITS_short_id2 default '' not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Единицы измерения', 'SCHEMA', 'dbo', 'TABLE', 'Units'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Units', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Units', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Кор. название для квитанций (например: м2)', 'SCHEMA', 'dbo', 'TABLE',
     'Units', 'COLUMN', 'short_id'
go

exec sp_addextendedproperty 'MS_Description', N'Точность (количество знаков после запятой)', 'SCHEMA', 'dbo', 'TABLE',
     'Units', 'COLUMN', 'precision'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительное короткое наименование (например: кв.м.)', 'SCHEMA',
     'dbo', 'TABLE', 'Units', 'COLUMN', 'short_id2'
go

