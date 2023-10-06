create table Compensac_tmp
(
    occ           int                                       not null
        constraint PK_COMPENSAC_TMP
            primary key,
    dateRaschet   smalldatetime                             not null,
    dateNazn      smalldatetime                             not null,
    dateEnd       smalldatetime                             not null,
    sumkomp       decimal(9, 2)                             not null,
    sumkomp_noext decimal(9, 2)                             not null,
    sumkvart      decimal(9, 2)                             not null,
    sumnorm       decimal(9, 2)                             not null,
    doxod         decimal(9, 2)                             not null,
    metod         smallint                                  not null,
    kol_people    smallint                                  not null,
    realy_people  smallint                                  not null,
    koef          real                                      not null,
    avto          bit                                       not null,
    finperiod     smallint                                  not null,
    transfer_bank bit
        constraint DF_COMPENSAC_TMP_transfer_bank default 0 not null,
    comments      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    owner_id      int,
    sum_pm        decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Временный расчет субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Compensac_tmp'
go

