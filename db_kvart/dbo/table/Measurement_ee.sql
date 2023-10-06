create table Measurement_ee
(
    fin_id     smallint
        constraint DF_MEASUREMENT_EE_fin_id default 131 not null,
    mode_id    int                                      not null
        constraint FK_Measurement_ee_Cons_modes
            references Cons_modes,
    rooms      smallint                                 not null,
    kol_people smallint                                 not null,
    kol_watt   decimal(8, 2)
        constraint DF_MEASUREMENT_EE_kol_watt default 0 not null,
    constraint PK_MEASUREMENT_EE
        primary key (fin_id, mode_id, rooms, kol_people)
)
go

exec sp_addextendedproperty 'MS_Description', N'Нормы потребления по электроэнергии', 'SCHEMA', 'dbo', 'TABLE',
     'Measurement_ee'
go

exec sp_addextendedproperty 'MS_Description', N'Нормы по электроэнергии', 'SCHEMA', 'dbo', 'TABLE', 'Measurement_ee',
     'COLUMN', 'mode_id'
go

