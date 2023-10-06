create table Counter_inspector
(
    id                     int identity
        constraint PK_COUNTER_INSPECTOR
            primary key,
    counter_id             int                                 not null
        constraint FK_COUNTER_INSPECTOR_COUNTERS
            references Counters,
    tip_value              smallint
        constraint DF_COUNTER_INSPECTOR_tip_value default 0    not null,
    inspector_value        decimal(14, 6)                      not null,
    inspector_date         smalldatetime                       not null,
    blocked                bit
        constraint DF_COUNTER_INSPECTOR_blocked default 0      not null,
    user_edit              smallint                            not null,
    date_edit              smalldatetime                       not null,
    kol_day                smallint
        constraint DF_COUNTER_INSPECTOR_kol_day default 0      not null,
    actual_value           decimal(14, 6)
        constraint DF_COUNTER_INSPECTOR_actual_value default 0 not null,
    value_vday             decimal(14, 8)
        constraint DF_COUNTER_INSPECTOR_value_vday default 0   not null,
    comments               varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    fin_id                 smallint
        constraint DF_COUNTER_INSPECTOR_fin_id default 0       not null,
    mode_id                int
        constraint DF_COUNTER_INSPECTOR_mode_id default 0      not null,
    tarif                  decimal(9, 4),
    value_paym             decimal(9, 2),
    volume_arenda          decimal(14, 6),
    is_info                bit
        constraint DF_COUNTER_INSPECTOR_is_info default 0      not null,
    metod_input            smallint,
    metod_rasch            smallint,
    ProgramInput           varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    warning                varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_Counter_inspector_Warning
            check ([warning] IS NULL OR ([warning] = 'OK' OR [warning] = 'ALERT')),
    blocked_value_negativ  bit,
    volume_odn             decimal(14, 6),
    norma_odn              decimal(12, 6),
    volume_direct_contract decimal(14, 6)
)
go

exec sp_addextendedproperty 'MS_Description', N'Значения инспектора по счетчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector'
go

exec sp_addextendedproperty 'MS_Description', N'код ПУ', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN',
     'counter_id'
go

exec sp_addextendedproperty 'MS_Description', N'0-показание инспектора,
1-показания квартиросьемщика, 2- общедомовой', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN', 'tip_value'
go

exec sp_addextendedproperty 'MS_Description', N'Значение показания', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'inspector_value'
go

exec sp_addextendedproperty 'MS_Description', N'Дата показания', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'inspector_date'
go

exec sp_addextendedproperty 'MS_Description', N'Дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во дней', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN',
     'kol_day'
go

exec sp_addextendedproperty 'MS_Description', N'факт объем (разница с предыдущим показанием)', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector', 'COLUMN', 'actual_value'
go

exec sp_addextendedproperty 'MS_Description', N'объем в день', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN',
     'value_vday'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'тариф', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN', 'tarif'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма начисления', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'value_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Объём по нежилым', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector',
     'COLUMN', 'volume_arenda'
go

exec sp_addextendedproperty 'MS_Description', N'Показатель только для информации(не для расчётов)', 'SCHEMA', 'dbo',
     'TABLE', 'Counter_inspector', 'COLUMN', 'is_info'
go

exec sp_addextendedproperty 'MS_Description', N'Метод ввода', 'SCHEMA', 'dbo', 'TABLE', 'Counter_inspector', 'COLUMN',
     'metod_input'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчёта по лицевому из таблицы PAYM_LIST', 'SCHEMA', 'dbo',
     'TABLE', 'Counter_inspector', 'COLUMN', 'metod_rasch'
go

exec sp_addextendedproperty 'MS_Description', N'Поле для отметки о подозрительном показании', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector', 'COLUMN', 'warning'
go

exec sp_addextendedproperty 'MS_Description', N'Блокировать отрицательный объем', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector', 'COLUMN', 'blocked_value_negativ'
go

exec sp_addextendedproperty 'MS_Description', N'Объём по ОДН по дому (для расчета по прямым договорам)', 'SCHEMA',
     'dbo', 'TABLE', 'Counter_inspector', 'COLUMN', 'volume_odn'
go

exec sp_addextendedproperty 'MS_Description', N'Норматив для расчета ОДН', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector', 'COLUMN', 'norma_odn'
go

exec sp_addextendedproperty 'MS_Description', N'Объём по услуге на прямых договорах', 'SCHEMA', 'dbo', 'TABLE',
     'Counter_inspector', 'COLUMN', 'volume_direct_contract'
go

