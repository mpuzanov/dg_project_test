create table Consmodes_list
(
    occ          int                                       not null,
    service_id   varchar(10)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id       int
        constraint DF_CONSMODES_LIST_sup_id default 0      not null,
    source_id    int                                       not null,
    mode_id      int                                       not null,
    subsid_only  bit
        constraint DF_CONSMODES_LIST_subsid_only default 0 not null,
    is_counter   smallint
        constraint DF_CONSMODES_LIST_is_counter default 0  not null,
    account_one  bit
        constraint DF_CONSMODES_LIST_account_one default 0 not null,
    koef         decimal(10, 4)
        constraint CK_CONSMODES_LIST
            check ([koef] < 5),
    lic_source   varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    occ_serv     bigint,
    dog_int      int,
    fin_id       smallint                                  not null,
    occ_serv_kol decimal(12, 6),
    date_end     date,
    date_start   date,
    constraint PK_CONSMODES_LIST_1
        primary key (occ, service_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Режимы потребления в квартире', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_list'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой счет', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list', 'COLUMN',
     'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак внешней услуги', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list',
     'COLUMN', 'subsid_only'
go

exec sp_addextendedproperty 'MS_Description', N'Признак платы по отдельной квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_list', 'COLUMN', 'account_one'
go

exec sp_addextendedproperty 'MS_Description', N'коэффициент', 'SCHEMA', 'dbo', 'TABLE', 'Consmodes_list', 'COLUMN',
     'koef'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой счет квартиросъемщика у поставщика', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_list', 'COLUMN', 'lic_source'
go

exec sp_addextendedproperty 'MS_Description', N'объём услуги для конкретного лицевого', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_list', 'COLUMN', 'occ_serv_kol'
go

exec sp_addextendedproperty 'MS_Description', N'Дата окончания расчета по услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Consmodes_list', 'COLUMN', 'date_end'
go

