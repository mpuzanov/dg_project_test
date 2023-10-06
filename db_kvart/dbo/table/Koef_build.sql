create table Koef_build
(
    build_id        int                          not null,
    service_id      varchar(10)                  not null collate SQL_Latin1_General_CP1251_CI_AS,
    div_name        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_KOEF_BUILD_div_name
            check ([div_name] IS NULL OR
                   ([div_name] = 'Октябрьский' OR [div_name] = 'Индустриальный' OR [div_name] = 'Первомайский' OR
                    [div_name] = 'Ленинский' OR [div_name] = 'Устиновский')),
    material        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_KOEF_BUILD_material
            check ([material] IS NULL OR ([material] = 'Деревянное' OR [material] = 'Капитальное')),
    garbage         varchar(20) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_KOEF_BUILD_garbage
            check ([garbage] IS NULL OR ([garbage] = 'Есть' OR [garbage] = 'Нет')),
    lift            varchar(20) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_KOEF_BUILD_lift
            check ([lift] IS NULL OR ([lift] = 'Есть' OR [lift] = 'Нет')),
    central_heating varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_KOEF_BUILD_central_heating
            check ([central_heating] IS NULL OR
                   ([central_heating] = 'Нет ГВС и Отоп' OR [central_heating] = 'Или ГВС или Отоп' OR
                    [central_heating] = 'Наличие ГВС и Отоп')),
    value           decimal(6, 4)
        constraint DF_KOEF_BUILD_value default 1 not null,
    constraint PK_KOEF_BUILD
        primary key (build_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Коэффициенты по домам (для найма)', 'SCHEMA', 'dbo', 'TABLE',
     'Koef_build'
go

