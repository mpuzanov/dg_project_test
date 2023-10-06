create table Peny_added
(
    fin_id      smallint                               not null,
    occ         int                                    not null,
    value_added decimal(9, 2)
        constraint DF_Peny_added_value_added default 0 not null,
    doc         varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit   date,
    user_edit   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    finPeriods  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_Peny_added
        primary key (fin_id, occ)
)
go

exec sp_addextendedproperty 'MS_Description', N'список фин.периодов через запятую', 'SCHEMA', 'dbo', 'TABLE',
     'Peny_added', 'COLUMN', 'finPeriods'
go

