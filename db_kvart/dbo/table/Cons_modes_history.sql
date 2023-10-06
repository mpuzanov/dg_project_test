create table Cons_modes_history
(
    fin_id     smallint    not null,
    mode_id    int         not null,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    name       varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id    varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_Cons_modes_history
        primary key (fin_id, mode_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История режимов потребления по месяцам', 'SCHEMA', 'dbo', 'TABLE',
     'Cons_modes_history'
go

