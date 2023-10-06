create table People_list_ras
(
    id           int identity
        constraint PK_PEOPLE_LIST_RAS
            primary key,
    occ          int         not null,
    owner_id     int         not null,
    service_id   varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    lgota_id     smallint,
    Snorm        decimal(10, 4),
    percentage   decimal(10, 4),
    owner_only   bit,
    norma_only   bit,
    nowork_only  bit,
    status_id    smallint,
    is_paym      bit,
    is_lgota     bit,
    is_subs      bit,
    is_norma     bit,
    is_norma_sub bit,
    is_rates     smallint,
    birthdate    smalldatetime,
    tarif        decimal(10, 4),
    kolday       smallint,
    koefday      decimal(8, 4),
    KolDayLgota  smallint,
    KoefDayLgota decimal(8, 4),
    Sown_s       decimal(10, 4),
    LgotaAll     smallint,
    discount     decimal(10, 4),
    owner_lgota  int
)
go

exec sp_addextendedproperty 'MS_Description', N'В таблицу заносится служебная информация при расчете квартплаты',
     'SCHEMA', 'dbo', 'TABLE', 'People_list_ras'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'People_list_ras', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'People_list_ras', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'People_list_ras', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'номер льготы', 'SCHEMA', 'dbo', 'TABLE', 'People_list_ras', 'COLUMN',
     'lgota_id'
go

exec sp_addextendedproperty 'MS_Description', N'код льготника, чья берется льгота', 'SCHEMA', 'dbo', 'TABLE',
     'People_list_ras', 'COLUMN', 'owner_lgota'
go

