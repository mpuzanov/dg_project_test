create table Build_mode
(
    build_id   int         not null
        constraint FK_Build_mode_Buildings
            references Buildings
            on update cascade on delete cascade,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    mode_id    int         not null
        constraint FK_BUILD_MODE_CONS_MODES
            references Cons_modes
            on update cascade on delete cascade,
    constraint PK_BUILD_MODE
        primary key (build_id, service_id, mode_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Режимы потребления по услугам на домах', 'SCHEMA', 'dbo', 'TABLE',
     'Build_mode'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Build_mode', 'COLUMN', 'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Build_mode', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код режима', 'SCHEMA', 'dbo', 'TABLE', 'Build_mode', 'COLUMN', 'mode_id'
go

