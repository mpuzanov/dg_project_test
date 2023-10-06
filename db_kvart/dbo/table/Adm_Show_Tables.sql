create table Adm_Show_Tables
(
    sql_table_name varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_ADM_SHOW_TABLES_1
            primary key,
    description    varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Список таблиц для редактирования в Админстраторе без отдельных форм',
     'SCHEMA', 'dbo', 'TABLE', 'Adm_Show_Tables'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование таблицы в базе', 'SCHEMA', 'dbo', 'TABLE',
     'Adm_Show_Tables', 'COLUMN', 'sql_table_name'
go

exec sp_addextendedproperty 'MS_Description', N'Описание таблицы по русски', 'SCHEMA', 'dbo', 'TABLE',
     'Adm_Show_Tables', 'COLUMN', 'description'
go

