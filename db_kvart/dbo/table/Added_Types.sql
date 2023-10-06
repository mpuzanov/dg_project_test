create table Added_Types
(
    id              smallint                                not null
        constraint PK_ADDED_TYPES
            primary key,
    name            varchar(50)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    short_name      varchar(25)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    type_no         smallint                                not null,
    is_counter      bit
        constraint DF_ADDED_TYPES_is_counter default 0      not null,
    visible         bit
        constraint DF_ADDED_TYPES_visible default 1         not null,
    visible_tex     bit
        constraint DF_ADDED_TYPES_visible_tex default 0     not null,
    visible_nedop   bit
        constraint DF_ADDED_TYPES_visible_nedop default 0   not null,
    visible_ras_sum bit
        constraint DF_ADDED_TYPES_visible_ras_sum default 0 not null,
    visible_kvit    bit
        constraint DF_Added_Types_visible_kvit default 1    not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы разовых', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'короткое название', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types', 'COLUMN',
     'short_name'
go

exec sp_addextendedproperty 'MS_Description', N'номер для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types',
     'COLUMN', 'type_no'
go

exec sp_addextendedproperty 'MS_Description', N'Может использоваться в расчётах по счётчикам', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Types', 'COLUMN', 'is_counter'
go

exec sp_addextendedproperty 'MS_Description', N'Показывать а Картотеке', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types',
     'COLUMN', 'visible'
go

exec sp_addextendedproperty 'MS_Description', N'Показывать перерасчёт в технической корректировке', 'SCHEMA', 'dbo',
     'TABLE', 'Added_Types', 'COLUMN', 'visible_tex'
go

exec sp_addextendedproperty 'MS_Description', N'Показывать перерасчёт в недопоставке', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Types', 'COLUMN', 'visible_nedop'
go

exec sp_addextendedproperty 'MS_Description', N'Показывать перерасчёт в раскидке суммы', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Types', 'COLUMN', 'visible_ras_sum'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешен вывод в квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Added_Types',
     'COLUMN', 'visible_kvit'
go

