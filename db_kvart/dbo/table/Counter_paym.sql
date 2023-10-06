create table Counter_paym
(
    fin_id     smallint                                not null,
    counter_id int                                     not null,
    kod_insp   int                                     not null
        constraint FK_COUNTER_PAYM_COUNTER_INSPECTOR
            references Counter_inspector
            on delete cascade,
    tip_value  smallint
        constraint DF_COUNTER_PAYM_tip_value default 0 not null,
    tarif      decimal(9, 4)                           not null,
    kol_day    smallint                                not null,
    value_vday decimal(14, 8)                          not null,
    value      decimal(14, 6)                          not null,
    mode_id    int,
    constraint PK_Counter_paym_1
        primary key (fin_id, counter_id, kod_insp, tip_value, tarif)
)
go

exec sp_addextendedproperty 'MS_Description', N'Расчеты по показанию счётчиков', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_paym'
go

