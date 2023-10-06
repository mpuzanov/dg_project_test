create table Iddoc_types
(
    id         varchar(10)                              not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_IDDOC_TYPES
            primary key nonclustered,
    name       varchar(25)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    doc_no     smallint
        constraint DF_IDDOC_TYPES_doc_no default 100    not null,
    short_name varchar(10)
        constraint DF_IDDOC_TYPES_short_name default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    name_dat   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Виды документов', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc_types'
go

exec sp_addextendedproperty 'MS_Description', N'код документа', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc_types', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc_types', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'поле для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc_types', 'COLUMN',
     'doc_no'
go

exec sp_addextendedproperty 'MS_Description', N'Короткое наименование документа', 'SCHEMA', 'dbo', 'TABLE',
     'Iddoc_types', 'COLUMN', 'short_name'
go

exec sp_addextendedproperty 'MS_Description', N'Документ в дательном падеже', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc_types',
     'COLUMN', 'name_dat'
go

