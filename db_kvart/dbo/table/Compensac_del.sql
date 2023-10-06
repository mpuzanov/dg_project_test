create table Compensac_del
(
    id            int           not null
        constraint PK_COMPENSAC_DEL
            primary key,
    occ           int           not null,
    dateRaschet   smalldatetime not null,
    dateNazn      smalldatetime not null,
    dateEnd       smalldatetime not null,
    sumkomp       decimal(9, 2) not null,
    sumkomp_noext decimal(9, 2) not null,
    sumkvart      decimal(9, 2) not null,
    sumnorm       decimal(9, 2) not null,
    doxod         decimal(9, 2) not null,
    metod         smallint      not null,
    kol_people    smallint      not null,
    realy_people  smallint      not null,
    koef          real          not null,
    avto          bit           not null,
    finperiod     smallint      not null,
    dateDelete    smalldatetime not null,
    transfer_bank bit,
    comments      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    owner_id      int
)
go

exec sp_addextendedproperty 'MS_Description', N'Удаленная субсидия', 'SCHEMA', 'dbo', 'TABLE', 'Compensac_del'
go

