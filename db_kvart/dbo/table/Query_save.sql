create table Query_save
(
    ID     int identity
        constraint PK_QUERY_SAVE
            primary key,
    NAME   varchar(100)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    QTEXT  varchar(8000) collate SQL_Latin1_General_CP1251_CI_AS,
    MAdded bit
        constraint DF_QUERY_SAVE_MAdded default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Сохранённые запросы для периодических выборок', 'SCHEMA', 'dbo',
     'TABLE', 'Query_save'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Query_save', 'COLUMN', 'ID'
go

exec sp_addextendedproperty 'MS_Description', N'Описание запроса', 'SCHEMA', 'dbo', 'TABLE', 'Query_save', 'COLUMN',
     'NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Текст запроса', 'SCHEMA', 'dbo', 'TABLE', 'Query_save', 'COLUMN',
     'QTEXT'
go

exec sp_addextendedproperty 'MS_Description', N'Запрос по разовым (подключается своё меню)', 'SCHEMA', 'dbo', 'TABLE',
     'Query_save', 'COLUMN', 'MAdded'
go

