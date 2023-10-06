create table Print_group
(
    id               smallint identity
        constraint PK_Print_Group
            primary key,
    name             varchar(30)                             not null collate SQL_Latin1_General_CP1251_CI_AS,
    comments         varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    print_only_group bit
        constraint DF_PRINT_GROUP_print_only_group default 0 not null,
    date_edit        date,
    user_edit        int
)
go

exec sp_addextendedproperty 'MS_Description', N'Наименование групп лицевых для печати квитанций', 'SCHEMA', 'dbo',
     'TABLE', 'Print_group'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'Print_group', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Print_group', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Print_group', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'признак печати только из группы', 'SCHEMA', 'dbo', 'TABLE',
     'Print_group', 'COLUMN', 'print_only_group'
go

