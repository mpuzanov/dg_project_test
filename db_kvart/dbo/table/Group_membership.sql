create table Group_membership
(
    group_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_GROUP_MEMBERSHIP_USER_GROUPS
            references User_groups
            on update cascade on delete cascade,
    user_id  smallint    not null
        constraint FK_GROUP_MEMBERSHIP_USERS
            references Users
            on update cascade on delete cascade,
    constraint PK_GROUP_MEMBERSHIP
        primary key (group_id, user_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Принадлежность пользователей к группам', 'SCHEMA', 'dbo', 'TABLE',
     'Group_membership'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'Group_membership', 'COLUMN',
     'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Group_membership',
     'COLUMN', 'user_id'
go

