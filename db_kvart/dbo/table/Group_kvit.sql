create table Group_kvit
(
    id      int identity
        constraint PK_Group_kvit
            primary key,
    name    varchar(100)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    sort_id smallint
        constraint DF_Group_kvit_sort_id default 10 not null,
    tip_id  smallint
)
go

