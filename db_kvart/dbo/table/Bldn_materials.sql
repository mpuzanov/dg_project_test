create table Bldn_materials
(
    id      int not null
        constraint PK_BLDN_MATERIALS
            primary key,
    name    varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    type_id smallint
)
go

exec sp_addextendedproperty 'MS_Description', N'Список материалов для домов', 'SCHEMA', 'dbo', 'TABLE', 'Bldn_materials'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Bldn_materials', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название материала', 'SCHEMA', 'dbo', 'TABLE', 'Bldn_materials',
     'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'тип крыша, стены и т.п.', 'SCHEMA', 'dbo', 'TABLE', 'Bldn_materials',
     'COLUMN', 'type_id'
go

