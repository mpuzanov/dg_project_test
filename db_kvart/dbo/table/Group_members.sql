create table Group_members
(
    group_id smallint     not null
        constraint FK_GROUP_MEMBERS_GROUPS
            references Groups,
    sysuser  nvarchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_GROUP_MEMBERS
        primary key (group_id, sysuser)
)
go

exec sp_addextendedproperty 'MS_Description', N'Спиок пользователей по группам', 'SCHEMA', 'dbo', 'TABLE',
     'Group_members'
go

exec sp_addextendedproperty 'MS_Description', N'Код группы', 'SCHEMA', 'dbo', 'TABLE', 'Group_members', 'COLUMN',
     'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'Логин пользователя группы', 'SCHEMA', 'dbo', 'TABLE', 'Group_members',
     'COLUMN', 'sysuser'
go

