create table Paym_occ_balance
(
    fin_id      smallint                                     not null,
    occ         int                                          not null,
    service_id  varchar(10)                                  not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id      int
        constraint DF_PAYM_OCC_BALANCE_sup_id default 0      not null,
    kol_balance decimal(12, 6)
        constraint DF_PAYM_OCC_BALANCE_kol_balance default 0 not null,
    constraint PK_PAYM_OCC_BALANCE_1
        primary key (fin_id, occ, service_id, sup_id)
)
go

