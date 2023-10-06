create table Added_Counters_All
(
    id           int identity
        constraint PK_ADDED_COUNTERS
            primary key,
    fin_id       smallint                                 not null,
    occ          int                                      not null,
    service_id   varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    add_type     smallint                                 not null
        constraint FK__ADDED_TYPES
            references Added_Types
            on update cascade,
    value        decimal(9, 2)                            not null,
    doc          varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    data1        smalldatetime,
    data2        smalldatetime,
    Vin1         int,
    Vin2         int,
    doc_no       varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    doc_date     smalldatetime,
    user_edit    smallint,
    dsc_owner_id int,
    sup_id       int
        constraint DF_ADDED_COUNTERS_ALL_sup_id default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Разовые по счетчикам', 'SCHEMA', 'dbo', 'TABLE', 'Added_Counters_All'
go

