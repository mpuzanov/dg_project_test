create table Subsidia12
(
    fin_id     smallint                              not null,
    occ        int                                   not null,
    service_id varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    value_max  decimal(9, 2)
        constraint DF_SUBSIDIA12_value_max default 0 not null,
    value      decimal(9, 2)
        constraint DF_SUBSIDIA12_value default 0     not null,
    paid       decimal(9, 2)
        constraint DF_SUBSIDIA12_paid default 0      not null,
    sub12      decimal(9, 2)
        constraint DF_SUBSIDIA12_sub12 default 0     not null,
    kol_people decimal(12, 6)
        constraint DF_SUBSIDIA12_kol_people default 0,
    tarif12    decimal(10, 4),
    tarif      decimal(10, 4),
    norma12    decimal(12, 6),
    norma      decimal(12, 6),
    value12    decimal(9, 2),
    procent    decimal(9, 4),
    fin_12     smallint,
    kol        decimal(12, 6),
    kol_odn    decimal(12, 6),
    constraint PK_SUBSIDIA12
        primary key (fin_id, occ, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Суммы возмещения платежей из бюджета', 'SCHEMA', 'dbo', 'TABLE',
     'Subsidia12'
go

