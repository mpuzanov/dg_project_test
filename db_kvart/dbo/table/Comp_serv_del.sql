create table Comp_serv_del
(
    id           int           not null
        constraint FK_COMP_SERV_DEL_COMPENSAC_DEL
            references Compensac_del
            on update cascade on delete cascade,
    occ          int           not null,
    service_id   varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    tarif        decimal(9, 2) not null,
    value_socn   smallmoney    not null,
    value_paid   smallmoney    not null,
    value_subs   smallmoney    not null,
    subsid_norma smallmoney,
    constraint PK_COMP_SERV_DEL
        primary key (id, occ, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Удаленная субсидия по услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Comp_serv_del'
go

