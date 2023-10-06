create table Allowed_Areas
(
    user_id  int         not null,
    group_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    op_id    varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    area_id  int         not null,
    constraint PK_ALLOWED_AREAS
        primary key (user_id, group_id, op_id, area_id)
)
go

exec sp_addextendedproperty 'MS_Description',
     N'Список разрешений доступа пользователей (на операции и что можно открывать)', 'SCHEMA', 'dbo', 'TABLE',
     'Allowed_Areas'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Allowed_Areas', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'Allowed_Areas', 'COLUMN',
     'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'код операции', 'SCHEMA', 'dbo', 'TABLE', 'Allowed_Areas', 'COLUMN',
     'op_id'
go

exec sp_addextendedproperty 'MS_Description', N'обычно код участка', 'SCHEMA', 'dbo', 'TABLE', 'Allowed_Areas',
     'COLUMN', 'area_id'
go

