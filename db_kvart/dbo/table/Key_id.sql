create table Key_id
(
    id          int not null
        constraint PK_KEY_ID
            primary key,
    key_max     int not null,
    decriptions varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Хранит MAX значения ключей в некоторых таблицах', 'SCHEMA', 'dbo',
     'TABLE', 'Key_id'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Key_id', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'MAX ключ', 'SCHEMA', 'dbo', 'TABLE', 'Key_id', 'COLUMN', 'key_max'
go

exec sp_addextendedproperty 'MS_Description', N'описание (в какой таблице)', 'SCHEMA', 'dbo', 'TABLE', 'Key_id',
     'COLUMN', 'decriptions'
go

