create type myTypeTableOccAll as table
(
    occ            int not null,
    service_id     char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    fin_id         smallint,
    tip_id         smallint,
    flat_id        int,
    build_id       int,
    summa1         decimal(9, 2),
    summa2         decimal(9, 2),
    summa3         decimal(9, 2),
    PROPTYPE_ID    char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    ROOMTYPE_ID    char(4) collate SQL_Latin1_General_CP1251_CI_AS,
    TOTAL_SQ       decimal(6, 2),
    address        varchar(60) collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id         int,
    dog_int        int,
    occ_sup        int,
    kol_people     smallint,
    kol_people_reg smallint,
    primary key (
                 occ)
)
go

