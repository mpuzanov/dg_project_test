create table Consmodes_history
(
    fin_id       smallint                                not null,
    occ          int                                     not null
        constraint FK_CONSMODES_HISTORY_OCCUPATIONS
            references Occupations
            on update cascade,
    service_id   varchar(10)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id       int
        constraint DF_CONSMODES_HISTORY_sup_id default 0 not null,
    source_id    int                                     not null,
    mode_id      int                                     not null
        constraint FK_CONSMODES_HISTORY_CONS_MODES
            references Cons_modes
            on update cascade on delete cascade,
    koef         decimal(10, 4)                          not null,
    subsid_only  bit                                     not null,
    is_counter   smallint,
    account_one  bit,
    dog_int      int,
    occ_serv_kol decimal(12, 6),
    date_end     date,
    date_start   date,
    constraint PK_CONSMODES_HISTORY_1
        primary key (fin_id, occ, service_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История режимов потребления', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_history'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history',
     'COLUMN', 'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'коэффициент', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history', 'COLUMN',
     'koef'
go

exec sp_addextendedproperty 'MS_Description', N'признак внешней услуги', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_history',
     'COLUMN', 'subsid_only'
go

