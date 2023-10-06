create table Agriculture_Vid
(
    id        smallint                                    not null
        constraint PK_ANIMAL_VID
            primary key,
    name      varchar(50)                                 not null collate SQL_Latin1_General_CP1251_CI_AS,
    kol_norma decimal(9, 4)
        constraint DF_AGRICULTURE_VID_kol_norma default 0 not null,
    is_people bit
        constraint DF_AGRICULTURE_VID_is_people default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список и значения нормативов по сельским хозяйствам', 'SCHEMA', 'dbo',
     'TABLE', 'Agriculture_Vid'
go

exec sp_addextendedproperty 'MS_Description', N'Для расчёта использовать кол-во человек', 'SCHEMA', 'dbo', 'TABLE',
     'Agriculture_Vid', 'COLUMN', 'is_people'
go

