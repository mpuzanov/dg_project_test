create table Izmlic
(
    datizm  smalldatetime not null,
    jeu1    smallint      not null,
    schtl1  int           not null,
    jeu2    smallint      not null,
    schtl2  int           not null,
    user_id smallint      not null,
    id      int identity
        constraint PK_IZMLIC
            primary key
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал изменения старых лицевых счетов', 'SCHEMA', 'dbo', 'TABLE',
     'Izmlic'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN', 'datizm'
go

exec sp_addextendedproperty 'MS_Description', N'старый номер участка', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN',
     'jeu1'
go

exec sp_addextendedproperty 'MS_Description', N'старый счет', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN', 'schtl1'
go

exec sp_addextendedproperty 'MS_Description', N'новый', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN', 'jeu2'
go

exec sp_addextendedproperty 'MS_Description', N'новый', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN', 'schtl2'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Izmlic', 'COLUMN',
     'user_id'
go

