create table Building_debug
(
    id          int identity
        constraint PK_Building_debug
            primary key,
    build_id    int not null,
    createAt    datetime
        constraint DF_Building_debug_createAt default getdate(),
    createUser  varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    change_type varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_id      smallint,
    sector_id   smallint,
    street_id   smallint,
    nom_dom     varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    town_id     smallint
)
go

