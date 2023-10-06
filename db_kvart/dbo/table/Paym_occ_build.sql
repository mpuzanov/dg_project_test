create table Paym_occ_build
(
    fin_id     smallint                               not null,
    occ        int                                    not null,
    service_id varchar(10)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    kol        decimal(12, 6)                         not null,
    tarif      smallmoney                             not null,
    value      decimal(9, 2)                          not null,
    comments   varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id    varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    procedura  varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    data       smalldatetime,
    user_login varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_add    decimal(12, 6),
    metod_old  smallint,
    service_in varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_excess decimal(12, 6),
    sup_id     int
        constraint DF_PAYM_OCC_BUILD_sup_id default 0 not null,
    koef_day   decimal(9, 4),
    kol_old    decimal(12, 6),
    constraint PK_PAYM_OCC_BUILD
        primary key (fin_id, occ, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица расчётов по общедомовым приборам учёта', 'SCHEMA', 'dbo',
     'TABLE', 'Paym_occ_build'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'тариф', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN', 'tarif'
go

exec sp_addextendedproperty 'MS_Description', N'сумма', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'код еденицы измерения', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build',
     'COLUMN', 'unit_id'
go

exec sp_addextendedproperty 'MS_Description', N'процедура расчёта', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build',
     'COLUMN', 'procedura'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во разницы между тем что было по норме', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_occ_build', 'COLUMN', 'kol_add'
go

exec sp_addextendedproperty 'MS_Description', N'Предыдущий метод расчета (из таблицы paym_list)', 'SCHEMA', 'dbo',
     'TABLE', 'Paym_occ_build', 'COLUMN', 'metod_old'
go

exec sp_addextendedproperty 'MS_Description', N'расчёт на основании заданной услуги', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_occ_build', 'COLUMN', 'service_in'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во превышение ОДН', 'SCHEMA', 'dbo', 'TABLE', 'Paym_occ_build',
     'COLUMN', 'kol_excess'
go

