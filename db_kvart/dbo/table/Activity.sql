create table Activity
(
    id           int identity
        constraint PK_Activity
            primary key,
    IPaddress    varchar(15)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    program      varchar(20)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    sysuser      varchar(30)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    DataActivity datetime                           not null,
    is_work      bit
        constraint DF_ACTIVITY_is_work default 0    not null,
    StrVer       varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    comp         varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    versia_old   bit
        constraint DF_ACTIVITY_versia_old default 0 not null,
    dir_program  varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Пользователи работающие с базой', 'SCHEMA', 'dbo', 'TABLE', 'Activity'
go

