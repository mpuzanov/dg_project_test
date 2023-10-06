create table Reason_extract
(
    id   smallint    not null
        constraint PK_REASON_EXTRACT
            primary key nonclustered,
    name varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Причины выписки', 'SCHEMA', 'dbo', 'TABLE', 'Reason_extract'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Reason_extract', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Описание', 'SCHEMA', 'dbo', 'TABLE', 'Reason_extract', 'COLUMN', 'name'
go

