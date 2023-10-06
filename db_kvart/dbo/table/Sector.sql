create table Sector
(
    id             smallint    not null
        constraint PK_SUBDIVISIONS
            primary key,
    name           varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    tip            smallint,
    id_account_org int,
    id_barcode     smallint,
    bank_account   int,
    adres_sec      varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    fio_sec        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    telefon_sec    varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Участки', 'SCHEMA', 'dbo', 'TABLE', 'Sector'
go

exec sp_addextendedproperty 'MS_Description', N'Код участка', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Код типа жил. фонда', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN',
     'tip'
go

exec sp_addextendedproperty 'MS_Description', N'код банковского счёта', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN',
     'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'адрес организации', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN',
     'adres_sec'
go

exec sp_addextendedproperty 'MS_Description', N'Ф.И.О. руководителя', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN',
     'fio_sec'
go

exec sp_addextendedproperty 'MS_Description', N'телефон', 'SCHEMA', 'dbo', 'TABLE', 'Sector', 'COLUMN', 'telefon_sec'
go

