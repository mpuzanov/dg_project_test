create table Build_source_id
(
    build_id   int         not null,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    kod        int         not null,
    comments   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_BUILD_SOURCE_ID_1
        primary key (build_id, service_id, kod)
)
go

exec sp_addextendedproperty 'MS_Description', N'Коды счетчиков по домам', 'SCHEMA', 'dbo', 'TABLE', 'Build_source_id'
go

