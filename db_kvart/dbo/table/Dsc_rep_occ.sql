create table Dsc_rep_occ
(
    occ           int                                not null
        constraint PK_DSC_REP_OCC
            primary key,
    Kol_people_lg int                                not null,
    Kol_lg        int                                not null,
    discount      decimal(9, 2)
        constraint DF_DSC_REP_OCC_discount default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Временная для раскидки льгот по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Dsc_rep_occ'
go

