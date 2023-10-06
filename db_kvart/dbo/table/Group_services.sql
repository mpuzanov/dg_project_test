create table Group_services
(
    GROUP_ID        smallint    not null,
    ONLY_SERVICE_ID varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_GROUP_SERVICES_GROUPS
            references Services
            on update cascade,
    constraint PK_USERS_ONLY_SERVICE_ID
        primary key (GROUP_ID, ONLY_SERVICE_ID)
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица ограничений грапп к услугам', 'SCHEMA', 'dbo', 'TABLE',
     'Group_services'
go

exec sp_addextendedproperty 'MS_Description', N'Код группы', 'SCHEMA', 'dbo', 'TABLE', 'Group_services', 'COLUMN',
     'GROUP_ID'
go

exec sp_addextendedproperty 'MS_Description', N'доступ только к этой услуге', 'SCHEMA', 'dbo', 'TABLE',
     'Group_services', 'COLUMN', 'ONLY_SERVICE_ID'
go

