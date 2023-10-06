create table Errors_occ
(
    id              int identity
        constraint PK_ERRORS_OCC
            primary key,
    data            smalldatetime not null,
    occ             int           not null,
    summa           decimal(9, 2),
    summa2          decimal(9, 2),
    comments        varchar(200) collate SQL_Latin1_General_CP1251_CI_AS,
    fin_id          smallint,
    tip_id          smallint,
    kol_error       int,
    kol_error_itogo int
)
go

exec sp_addextendedproperty 'MS_Description', N'Ошибки по лицевым при ночной проверке расчётов', 'SCHEMA', 'dbo',
     'TABLE', 'Errors_occ'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во ошибок одного вида по типу фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Errors_occ', 'COLUMN', 'kol_error'
go

exec sp_addextendedproperty 'MS_Description', N'Всего ошибок', 'SCHEMA', 'dbo', 'TABLE', 'Errors_occ', 'COLUMN',
     'kol_error_itogo'
go

