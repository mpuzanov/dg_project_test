create table Added_Payments_History
(
    fin_id         smallint                                   not null,
    occ            int                                        not null,
    service_id     varchar(10)                                not null collate SQL_Latin1_General_CP1251_CI_AS,
    add_type       smallint                                   not null,
    id             int identity,
    value          decimal(9, 2)                              not null,
    doc            varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    data1          smalldatetime,
    data2          smalldatetime,
    Hours          smallint,
    add_type2      smallint,
    manual_bit     bit,
    Vin1           int,
    Vin2           int,
    doc_no         varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    doc_date       smalldatetime,
    user_edit      smallint,
    dsc_owner_id   int,
    fin_id_paym    smallint,
    comments       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    tnorm2         smallint,
    kol            decimal(12, 6),
    repeat_for_fin smallint,
    date_edit      smalldatetime,
    sup_id         int
        constraint DF_ADDED_PAYMENTS_HISTORY_sup_id default 0 not null,
    constraint PK_ADDED_PAYMENTS_HISTORY
        primary key (fin_id, occ, service_id, add_type, id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История разовых', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History'
go

exec sp_addextendedproperty 'MS_Description', N'фин. период', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History', 'COLUMN',
     'occ'
go

exec sp_addextendedproperty 'MS_Description', N'услуга', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'типы разовых', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History',
     'COLUMN', 'add_type'
go

exec sp_addextendedproperty 'MS_Description', N'сумма', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History', 'COLUMN',
     'value'
go

exec sp_addextendedproperty 'MS_Description', N'документ', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments_History', 'COLUMN',
     'doc'
go

