create table Status
(
    id      smallint                           not null
        constraint PK_STATUS
            primary key,
    name    varchar(30)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_work bit
        constraint DF_STATUS_is_work default 1 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Социальный статус человека', 'SCHEMA', 'dbo', 'TABLE', 'Status'
go

exec sp_addextendedproperty 'MS_Description', N'Код соц. статуса', 'SCHEMA', 'dbo', 'TABLE', 'Status', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Status', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Признак трудоспособности', 'SCHEMA', 'dbo', 'TABLE', 'Status', 'COLUMN',
     'is_work'
go

