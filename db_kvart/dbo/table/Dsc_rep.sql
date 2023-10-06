create table Dsc_rep
(
    fin_id      smallint                           not null,
    occ         int                                not null,
    owner_id    int                                not null,
    lgota_id    smallint                           not null,
    kol_people  int
        constraint DF_DSC_REP_kol_people default 0 not null,
    Summa       decimal(9, 2)
        constraint DF_DSC_REP_Summa default 0      not null,
    total_sq    decimal(5, 2),
    issued      smalldatetime,
    issued2     smalldatetime,
    expire_date smalldatetime,
    doc         varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_DSC_REP
        primary key (fin_id, occ, owner_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Временная для раскидки льгот по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Dsc_rep'
go

