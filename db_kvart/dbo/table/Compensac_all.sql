create table Compensac_all
(
    fin_id        smallint      not null,
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
    transfer_bank bit,
    owner_id      int,
    comments      int,
    sum_pm        decimal(9, 2),
    constraint PK_COMPENSAC_ALL
        primary key (fin_id, occ)
)
go

exec sp_addextendedproperty 'MS_Description', N'Компенсации(субсидии) по лицевым счетам', 'SCHEMA', 'dbo', 'TABLE',
     'Compensac_all'
go

