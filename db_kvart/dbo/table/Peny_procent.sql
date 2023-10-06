create table Peny_procent
(
    data     date          not null
        constraint PK_Peny_procent
            primary key,
    val_proc decimal(9, 4) not null
)
go

