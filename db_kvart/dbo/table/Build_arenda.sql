create table Build_arenda
(
    build_id   int                                   not null,
    fin_id     int                                   not null,
    service_id varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    kol        decimal(15, 6)
        constraint DF_BUILD_ARENDA_kol default 0     not null,
    kol_dom    decimal(15, 6)
        constraint DF_BUILD_ARENDA_kol_dom default 0 not null,
    arenda_sq  decimal(10, 4),
    opu_sq     decimal(10, 4),
    volume_gvs decimal(15, 6),
    constraint PK_BUILD_ARENDA_1
        primary key (build_id, fin_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Информация по нежилым помещениям в доме', 'SCHEMA', 'dbo', 'TABLE',
     'Build_arenda'
go

exec sp_addextendedproperty 'MS_Description', N'Услуга', 'SCHEMA', 'dbo', 'TABLE', 'Build_arenda', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'Объём услуги', 'SCHEMA', 'dbo', 'TABLE', 'Build_arenda', 'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'Общедомовые нужды', 'SCHEMA', 'dbo', 'TABLE', 'Build_arenda', 'COLUMN',
     'kol_dom'
go

exec sp_addextendedproperty 'MS_Description', N'Объём на производство ГВС', 'SCHEMA', 'dbo', 'TABLE', 'Build_arenda',
     'COLUMN', 'volume_gvs'
go

