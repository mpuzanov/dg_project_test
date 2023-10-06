create table Counter_list_all
(
    fin_id               smallint                              not null,
    occ                  int                                   not null
        constraint FK_COUNTER_LIST_ALL_OCCUPATIONS
            references Occupations
            on update cascade on delete cascade,
    counter_id           int                                   not null
        constraint FK_COUNTER_LIST_ALL_COUNTERS
            references Counters,
    service_id           varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    occ_counter          int,
    internal             bit
        constraint DF_COUNTER_LIST_ALL_internal default 1      not null,
    no_vozvrat           bit,
    KolmesForPeriodCheck smallint
        constraint DF_COUNTER_LIST_ALL_PeriodCheckOk default 0 not null,
    kol_occ              smallint
        constraint DF_COUNTER_LIST_ALL_kol_occ default 1       not null,
    avg_vday             decimal(12, 6),
    constraint PK_COUNTER_LIST_ALL_1
        primary key (fin_id, occ, counter_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список счётчиков по лицевым и фин.периодам', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_list_all'
go

exec sp_addextendedproperty 'MS_Description', N'код периода', 'SCHEMA', 'dbo', 'TABLE', 'Counter_list_all', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Counter_list_all', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код счётчика', 'SCHEMA', 'dbo', 'TABLE', 'Counter_list_all', 'COLUMN',
     'counter_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Counter_list_all', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак внутр.счётчика', 'SCHEMA', 'dbo', 'TABLE', 'Counter_list_all',
     'COLUMN', 'internal'
go

exec sp_addextendedproperty 'MS_Description', N'Не делать возврат по счётчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_list_all', 'COLUMN', 'no_vozvrat'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во месяцев до периода поверки', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_list_all', 'COLUMN', 'KolmesForPeriodCheck'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во лицевых на счётчики', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_list_all', 'COLUMN', 'kol_occ'
go

exec sp_addextendedproperty 'MS_Description', N'среднее потребление в день', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_list_all', 'COLUMN', 'avg_vday'
go

