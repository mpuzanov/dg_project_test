create table Dsc_owners
(
    id           int identity
        constraint PK_DSC_OWNERS
            primary key,
    owner_id     int                                not null
        constraint FK_DSC_OWNERS_PEOPLE
            references People
            on update cascade on delete cascade,
    dscgroup_id  smallint                           not null
        constraint FK__dsc_owner__dscgr__2454DCEB
            references Dsc_groups,
    active       bit
        constraint DF_DSC_OWNERS_active_1 default 1 not null,
    issued       smalldatetime                      not null,
    issued2      smalldatetime,
    expire_date  smalldatetime                      not null,
    doc          varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DelDateLgota smalldatetime,
    user_id      smallint,
    doc_no       varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    doc_seria    varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    doc_org      varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    people_uid   uniqueidentifier
)
go

exec sp_addextendedproperty 'MS_Description', N'Все Льготники', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners'
go

exec sp_addextendedproperty 'MS_Description', N'код льготника', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN',
     'dscgroup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Признак активности на данный момент', 'SCHEMA', 'dbo', 'TABLE',
     'Dsc_owners', 'COLUMN', 'active'
go

exec sp_addextendedproperty 'MS_Description', N'Дата назначения льготы', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners',
     'COLUMN', 'issued'
go

exec sp_addextendedproperty 'MS_Description', N'Дата выдачи документа', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners',
     'COLUMN', 'issued2'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания льготы', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners',
     'COLUMN', 'expire_date'
go

exec sp_addextendedproperty 'MS_Description', N'название документа', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN',
     'doc'
go

exec sp_addextendedproperty 'MS_Description', N'дата удаления льготы', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN',
     'DelDateLgota'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'номер', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN', 'doc_no'
go

exec sp_addextendedproperty 'MS_Description', N'серия', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN', 'doc_seria'
go

exec sp_addextendedproperty 'MS_Description', N'кем выдан', 'SCHEMA', 'dbo', 'TABLE', 'Dsc_owners', 'COLUMN', 'doc_org'
go

