create table User_groups
(
    group_id   varchar(10)                               not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_USER_GROUPS
            primary key nonclustered,
    name       varchar(30)
        constraint DF_USER_GROUPS_name default ''        not null collate SQL_Latin1_General_CP1251_CI_AS,
    group_no   smallint
        constraint DF_USER_GROUPS_group_no default 10    not null,
    max_access smallint
        constraint DF_USER_GROUPS_max_access default 100 not null,
    sys_group  varchar(25)                               not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Группы пользователей в системе', 'SCHEMA', 'dbo', 'TABLE', 'User_groups'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'User_groups', 'COLUMN',
     'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'User_groups', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'номер группы', 'SCHEMA', 'dbo', 'TABLE', 'User_groups', 'COLUMN',
     'group_no'
go

