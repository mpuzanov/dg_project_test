create table Limit_values
(
    TABLE_NAME    varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    POLE_NAME     varchar(15) not null collate SQL_Latin1_General_CP1251_CI_AS,
    MIN_VALUE     decimal(15, 2),
    MAX_VALUE     decimal(15, 2),
    DESCRIPTION   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DOP_CONDITION varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_LIMIT_VALUES
        primary key (TABLE_NAME, POLE_NAME)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список проверок пороговых значений', 'SCHEMA', 'dbo', 'TABLE',
     'Limit_values'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование таблицы', 'SCHEMA', 'dbo', 'TABLE', 'Limit_values',
     'COLUMN', 'TABLE_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование поля', 'SCHEMA', 'dbo', 'TABLE', 'Limit_values', 'COLUMN',
     'POLE_NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Минимальное значение', 'SCHEMA', 'dbo', 'TABLE', 'Limit_values',
     'COLUMN', 'MIN_VALUE'
go

exec sp_addextendedproperty 'MS_Description', N'Максимальное значение', 'SCHEMA', 'dbo', 'TABLE', 'Limit_values',
     'COLUMN', 'MAX_VALUE'
go

exec sp_addextendedproperty 'MS_Description', N'Описание', 'SCHEMA', 'dbo', 'TABLE', 'Limit_values', 'COLUMN',
     'DESCRIPTION'
go

exec sp_addextendedproperty 'MS_Description', N'Дополнительные условия выборки', 'SCHEMA', 'dbo', 'TABLE',
     'Limit_values', 'COLUMN', 'DOP_CONDITION'
go

