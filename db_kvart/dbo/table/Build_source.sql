create table Build_source
(
    build_id   int         not null
        constraint FK_Build_source_Buildings
            references Buildings
            on update cascade on delete cascade,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    source_id  int         not null
        constraint FK_BUILD_SOURCE_SUPPLIERS
            references Suppliers (id)
            on update cascade,
    constraint PK_BUILD_SOURCE
        primary key (build_id, service_id, source_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Поставщики по услугам на домах', 'SCHEMA', 'dbo', 'TABLE',
     'Build_source'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Build_source', 'COLUMN',
     'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Build_source', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Build_source', 'COLUMN',
     'source_id'
go

