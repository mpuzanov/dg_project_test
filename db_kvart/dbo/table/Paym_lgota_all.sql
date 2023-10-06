create table Paym_lgota_all
(
    fin_id      smallint      not null,
    occ         int           not null,
    owner_id    int           not null,
    service_id  varchar(10)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    lgota_id    smallint      not null,
    lgotaAll    smallint      not null,
    discount    smallmoney    not null,
    subsid_only bit           not null,
    Snorm       decimal(5, 2) not null,
    owner_lgota int,
    is_counter  bit,
    constraint PK_PAYM_LGOTA_ALL
        primary key (fin_id, occ, owner_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Сумма льгот по услугам на человека', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_lgota_all'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN',
     'lgota_id'
go

exec sp_addextendedproperty 'MS_Description', N'расчет был по этой льготе', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all',
     'COLUMN', 'lgotaAll'
go

exec sp_addextendedproperty 'MS_Description', N'сумма льготы', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN',
     'discount'
go

exec sp_addextendedproperty 'MS_Description', N'Площадь', 'SCHEMA', 'dbo', 'TABLE', 'Paym_lgota_all', 'COLUMN', 'Snorm'
go

exec sp_addextendedproperty 'MS_Description', N'код льготника, чья берется льгота', 'SCHEMA', 'dbo', 'TABLE',
     'Paym_lgota_all', 'COLUMN', 'owner_lgota'
go

