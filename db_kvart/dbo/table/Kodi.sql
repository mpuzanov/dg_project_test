create table Kodi
(
    id   char(2) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_KODI
            primary key,
    name char(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды перечислений по субсидиям', 'SCHEMA', 'dbo', 'TABLE', 'Kodi'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Kodi', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Вид платежа', 'SCHEMA', 'dbo', 'TABLE', 'Kodi', 'COLUMN', 'name'
go

