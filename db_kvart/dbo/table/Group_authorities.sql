create table Group_authorities
(
    group_id    varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    op_id       varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    areatype_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_GROUP_AUTHORITIES
        primary key (group_id, op_id, areatype_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Доступ групп к операциям', 'SCHEMA', 'dbo', 'TABLE', 'Group_authorities'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'Group_authorities', 'COLUMN',
     'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Group_authorities', 'COLUMN',
     'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'код (Все данные, район, участок)', 'SCHEMA', 'dbo', 'TABLE',
     'Group_authorities', 'COLUMN', 'areatype_id'
go

