create table Measurement_units
(
    id               int identity
        constraint PK_MEASUREMENT_UNITS
            primary key,
    fin_id           smallint
        constraint DF_MEASUREMENT_UNITS_fin_id default 131     not null,
    unit_id          varchar(10)                               not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_MEASUREMENT_UNITS_UNITS
            references Units,
    mode_id          int                                       not null,
    is_counter       smallint
        constraint DF_MEASUREMENT_UNITS_is_counter default 0   not null,
    tip_id           smallint
        constraint DF_MEASUREMENT_UNITS_tip_id default 0       not null,
    q_single         decimal(12, 6)
        constraint DF_MEASUREMENT_UNITS_q_single default 0     not null,
    two_single       decimal(12, 6)
        constraint DF_MEASUREMENT_UNITS_two_single default 0   not null,
    three_single     decimal(12, 6)
        constraint DF_MEASUREMENT_UNITS_three_single default 0 not null,
    four_single      decimal(12, 6)
        constraint DF_MEASUREMENT_UNITS_four_single default 0  not null,
    q_member         decimal(12, 6)
        constraint DF_MEASUREMENT_UNITS_q_member default 0     not null,
    user_edit        smallint,
    norma_extr_tarif decimal(12, 6),
    norma_full_tarif decimal(12, 6)
)
go

exec sp_addextendedproperty 'MS_Description', N'Нормы на единицы измерения и кол. человек', 'SCHEMA', 'dbo', 'TABLE',
     'Measurement_units'
go

exec sp_addextendedproperty 'MS_Description', N'код ед. измерения', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units',
     'COLUMN', 'unit_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима потребления', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units',
     'COLUMN', 'mode_id'
go

exec sp_addextendedproperty 'MS_Description', N'норма на одного', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units',
     'COLUMN', 'q_single'
go

exec sp_addextendedproperty 'MS_Description', N'на двоих', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units', 'COLUMN',
     'two_single'
go

exec sp_addextendedproperty 'MS_Description', N'на троих', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units', 'COLUMN',
     'three_single'
go

exec sp_addextendedproperty 'MS_Description', N'на четверых', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units', 'COLUMN',
     'four_single'
go

exec sp_addextendedproperty 'MS_Description', N'на семью', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_units', 'COLUMN',
     'q_member'
go

exec sp_addextendedproperty 'MS_Description', N'от данного норматива считать по extr_tarif', 'SCHEMA', 'dbo', 'TABLE',
     'Measurement_units', 'COLUMN', 'norma_extr_tarif'
go

exec sp_addextendedproperty 'MS_Description', N'больше данного норматива считать по full_tarif', 'SCHEMA', 'dbo',
     'TABLE', 'Measurement_units', 'COLUMN', 'norma_full_tarif'
go

