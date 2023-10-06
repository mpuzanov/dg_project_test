create table Errors_occ_all
(
    DATA     smalldatetime,
    occ      int,
    summa    decimal(15, 4),
    summa2   decimal(15, 4),
    comments varchar(200) collate SQL_Latin1_General_CP1251_CI_AS,
    fin_id   smallint,
    tip_id   smallint
)
go

