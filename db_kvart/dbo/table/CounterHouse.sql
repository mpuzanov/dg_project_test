create table CounterHouse
(
    fin_id       smallint                                       not null,
    tip_id       smallint                                       not null,
    build_id     int                                            not null,
    service_id   varchar(10)                                    not null collate SQL_Latin1_General_CP1251_CI_AS,
    short_name   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    unit_id      varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    is_boiler    bit,
    V_start      decimal(15, 6),
    V1           decimal(15, 6)
        constraint DF__CounterHouse__V1__0A0BC65A default 0,
    V_arenda     decimal(15, 6)
        constraint DF__CounterHo__V_are__0AFFEA93 default 0,
    V_norma      decimal(15, 6)
        constraint DF__CounterHo__V_nor__0BF40ECC default 0,
    V_add        decimal(15, 6)
        constraint DF__CounterHo__V_add__0CE83305 default 0,
    V_load_odn   decimal(15, 6),
    V2           decimal(15, 6)
        constraint DF__CounterHouse__V2__0DDC573E default 0,
    V3           decimal(15, 6)
        constraint DF__CounterHouse__V3__0ED07B77 default 0,
    V_economy    decimal(15, 6),
    block_paym_V bit
        constraint DF__CounterHo__block__0FC49FB0 default 0,
    DateCreate   smalldatetime
        constraint DF_CounterHouse_DateCreate default getdate() not null,
    manual_edit  bit
        constraint DF_CounterHouse_manual_edit default 0        not null,
    constraint PK_CounterHouse_1
        primary key (fin_id, tip_id, build_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица со справочной информацией в квитанции по дому', 'SCHEMA', 'dbo',
     'TABLE', 'CounterHouse'
go

exec sp_addextendedproperty 'MS_Description', N'Объём экономии с прошлого месяца', 'SCHEMA', 'dbo', 'TABLE',
     'CounterHouse', 'COLUMN', 'V_start'
go

exec sp_addextendedproperty 'MS_Description', N'Объём ОДПУ', 'SCHEMA', 'dbo', 'TABLE', 'CounterHouse', 'COLUMN', 'V1'
go

exec sp_addextendedproperty 'MS_Description', N'Объём в помещении дома', 'SCHEMA', 'dbo', 'TABLE', 'CounterHouse',
     'COLUMN', 'V2'
go

exec sp_addextendedproperty 'MS_Description', N'Экономия СОИ на конец периода', 'SCHEMA', 'dbo', 'TABLE',
     'CounterHouse', 'COLUMN', 'V_economy'
go

