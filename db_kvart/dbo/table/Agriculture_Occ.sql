create table Agriculture_Occ
(
    fin_id  smallint                                  not null,
    occ     int                                       not null,
    ani_vid smallint                                  not null,
    id      int identity,
    kol     decimal(9, 4)
        constraint DF_ANIMAL_OCC_kol default 0        not null,
    kol_day smallint
        constraint DF_ANIMAL_OCC_kol_day default 0    not null,
    value   decimal(9, 2)
        constraint DF_AGRICULTURE_OCC_value default 0 not null,
    constraint PK_AGRICULTURE_OCC
        primary key (fin_id, occ, ani_vid, id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Расчёты по лицевым по сельским хозяйствам', 'SCHEMA', 'dbo', 'TABLE',
     'Agriculture_Occ'
go

