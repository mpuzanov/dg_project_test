create table Reason_close_occ
(
    id   smallint     not null
        constraint PK_REASON_CLOSE_OCC
            primary key,
    name varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Причины закрытия лицевых счетов', 'SCHEMA', 'dbo', 'TABLE',
     'Reason_close_occ'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reason_close_occ', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reason_close_occ', 'COLUMN',
     'name'
go

