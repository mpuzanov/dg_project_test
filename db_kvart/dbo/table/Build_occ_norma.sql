create table Build_occ_norma
(
    occ        int         not null
        constraint FK_Build_occ_norma_Occupations
            references Occupations
            on delete cascade,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Build_occ_norma_Services
            references Services
            on update cascade on delete cascade,
    build_id   int         not null
        constraint FK_Build_occ_norma_Buildings
            references Buildings
            on update cascade on delete cascade,
    kol_norma  decimal(12, 6)
        constraint DF_Table_1_norma default 0,
    kol        decimal(12, 6)
        constraint DF_Build_occ_norma_kol default 0,
    tarif      smallmoney
        constraint DF_Build_occ_norma_tarif default 0,
    constraint PK_Build_occ_norma
        primary key (occ, service_id, build_id)
)
go

