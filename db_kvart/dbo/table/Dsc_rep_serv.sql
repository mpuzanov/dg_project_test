create table Dsc_rep_serv
(
    id         int identity
        constraint PK_DSC_REP_SERV
            primary key,
    fin_id     smallint                                not null,
    occ        int                                     not null,
    owner_id   int                                     not null,
    service_id varchar(10)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    lgota_id   smallint                                not null,
    discount   smallmoney
        constraint DF_DSC_REP_SERV_discount default 0  not null,
    dsc_value  smallmoney
        constraint DF_DSC_REP_SERV_dsc_value default 0 not null,
    tip        char                                    not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Временная для раскидки льгот по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Dsc_rep_serv'
go

