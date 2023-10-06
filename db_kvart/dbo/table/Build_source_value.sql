create table Build_source_value
(
    fin_id          smallint                                       not null,
    build_id        int                                            not null,
    service_id      varchar(10)                                    not null collate SQL_Latin1_General_CP1251_CI_AS,
    value_start     decimal(15, 4)
        constraint DF_Build_source_value_value_start default 0     not null,
    value_source    decimal(15, 4)                                 not null,
    value_arenda    decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_volume_arenda default 0   not null,
    value_norma     decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_value_norma default 0     not null,
    value_add       decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_value_add default 0       not null,
    value_ipu       decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_value_ipu default 0       not null,
    value_gvs       decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_value_gvs default 0       not null,
    value_odn       decimal(15, 4)
        constraint DF_Build_source_value_value_odn default 0       not null,
    v_itog          decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_v_itog default 0          not null,
    S_arenda        decimal(9, 2)
        constraint DF_BUILD_SOURCE_VALUE_S_arenda default 0        not null,
    kol_people_serv int
        constraint DF_BUILD_SOURCE_VALUE_kol_people_serv default 0 not null,
    unit_id         varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    total_sq        decimal(9, 2)
        constraint DF_BUILD_SOURCE_VALUE_total_sq default 0        not null,
    use_add         bit,
    flag_raskidka   tinyint,
    value_raspred   decimal(15, 4)
        constraint DF_BUILD_SOURCE_VALUE_value_raspred default 0   not null,
    avg_volume_m2   decimal(14, 6),
    constraint PK_BUILD_SOURCE_VALUE
        primary key (fin_id, build_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Начисления по домовым счётчикам от поставщиков услуг', 'SCHEMA', 'dbo',
     'TABLE', 'Build_source_value'
go

exec sp_addextendedproperty 'MS_Description', N'Учитывать перерасчёты', 'SCHEMA', 'dbo', 'TABLE', 'Build_source_value',
     'COLUMN', 'use_add'
go

exec sp_addextendedproperty 'MS_Description', N'0 - не раскидывать по людям где счётчики, 1- раскидывать где счётчики',
     'SCHEMA', 'dbo', 'TABLE', 'Build_source_value', 'COLUMN', 'flag_raskidka'
go

exec sp_addextendedproperty 'MS_Description', N'Распределяемый объём', 'SCHEMA', 'dbo', 'TABLE', 'Build_source_value',
     'COLUMN', 'value_raspred'
go

exec sp_addextendedproperty 'MS_Description', N'средний расход услуги на м2', 'SCHEMA', 'dbo', 'TABLE',
     'Build_source_value', 'COLUMN', 'avg_volume_m2'
go

