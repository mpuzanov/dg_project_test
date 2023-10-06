create table Dsc_groups
(
    id     smallint                               not null
        constraint PK_DSC_GROUPS
            primary key,
    name   varchar(30)                            not null collate SQL_Latin1_General_CP1251_CI_AS,
    law_id int
        constraint DF_DSC_GROUPS_law_id default 0 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Список льгот', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_groups'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_groups', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_groups', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'код закона', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_groups', 'COLUMN', 'law_id'
go

