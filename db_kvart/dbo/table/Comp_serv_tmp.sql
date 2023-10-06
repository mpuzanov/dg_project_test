create table Comp_serv_tmp
(
    occ          int           not null
        constraint FK_COMP_SERV_TMP_COMPENSAC_TMP
            references Compensac_tmp
            on update cascade on delete cascade,
    service_id   varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    tarif        decimal(9, 2) not null,
    value_socn   decimal(9, 2) not null,
    value_paid   decimal(9, 2) not null,
    value_subs   decimal(9, 2) not null,
    subsid_norma decimal(5, 2),
    constraint PK_COMP_SERV_TMP
        primary key (occ, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Временный расчет субсидии по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Comp_serv_tmp'
go

