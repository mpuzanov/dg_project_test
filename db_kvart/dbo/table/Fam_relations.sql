create table Fam_relations
(
    Id    char(4)                                       not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_FAM
            primary key,
    name  varchar(30)                                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    id_no smallint
        constraint DF_FAM_RELATIONS_id_no_1 default 100 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список родственных отношений', 'SCHEMA', 'dbo', 'TABLE', 'Fam_relations'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Fam_relations', 'COLUMN', 'Id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Fam_relations', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Fam_relations',
     'COLUMN', 'id_no'
go

