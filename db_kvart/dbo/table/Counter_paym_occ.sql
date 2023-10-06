create table Counter_paym_occ
(
    flat_id    int                                     not null,
    fin_id     smallint                                not null,
    occ        int                                     not null,
    service_id varchar(10)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    tip_value  smallint                                not null,
    kol        decimal(9, 4)
        constraint DF_COUNTER_PAYM_OCC_kol default 0   not null,
    value      decimal(9, 2)
        constraint DF_COUNTER_PAYM_OCC_value default 0 not null,
    constraint PK_COUNTER_PAYM_OCC_1
        primary key (flat_id, fin_id, occ, service_id, tip_value)
)
go

exec sp_addextendedproperty 'MS_Description', N'Раскидка показаний по месяцам', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_paym_occ'
go

