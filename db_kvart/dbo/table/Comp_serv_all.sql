create table Comp_serv_all
(
    fin_id       smallint      not null,
    occ          int           not null,
    service_id   varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    tarif        decimal(9, 2) not null,
    value_socn   decimal(9, 2) not null,
    value_paid   decimal(9, 2) not null,
    value_subs   decimal(9, 2) not null,
    subsid_norma decimal(9, 2),
    constraint PK_COMP_SERV_ALL
        primary key (fin_id, occ, service_id),
    constraint FK_COMP_SERV_ALL_COMPENSAC_ALL
        foreign key (fin_id, occ) references Compensac_all
            on update cascade
)
go

exec sp_addextendedproperty 'MS_Description', N'Компенсации по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Comp_serv_all'
go

