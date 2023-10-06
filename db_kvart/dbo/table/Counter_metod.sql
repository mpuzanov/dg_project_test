create table Counter_metod
(
    id   smallint    not null
        constraint PK_Counter_metod
            primary key,
    name varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

