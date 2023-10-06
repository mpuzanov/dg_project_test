create table Subsidia12tarif
(
    fin_id     smallint                               not null,
    service_id varchar(30)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    tarif      decimal(15, 4)
        constraint DF_Subsidia12tarif_tarif default 0 not null,
    constraint PK_Subsidia12tarif
        primary key (fin_id, service_id)
)
go

