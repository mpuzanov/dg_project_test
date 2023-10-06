create table Discounts
(
    dscgroup_id smallint                              not null
        constraint FK__discounts__dscgr__25490124
            references Dsc_groups,
    service_id  varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    proptype_id char(4)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    Percentage  decimal(4, 2)
        constraint DF_DISCOUNTS_Percentage default 0  not null,
    owner_only  bit
        constraint DF_DISCOUNTS_owner_only default 0  not null,
    norma_only  bit
        constraint DF_DISCOUNTS_norma_only default 0  not null,
    nowork_only bit
        constraint DF_DISCOUNTS_nowork_only default 0 not null,
    constraint PK_DISCOUNTS
        primary key (dscgroup_id, service_id, proptype_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Скидки на льготы', 'SCHEMA', 'dbo', 'TABLE', 'Discounts'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'Discounts', 'COLUMN',
     'dscgroup_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Discounts', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'статус квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Discounts', 'COLUMN',
     'proptype_id'
go

exec sp_addextendedproperty 'MS_Description', N'процент скидки', 'SCHEMA', 'dbo', 'TABLE', 'Discounts', 'COLUMN',
     'Percentage'
go

exec sp_addextendedproperty 'MS_Description', N'только на владельца льготы', 'SCHEMA', 'dbo', 'TABLE', 'Discounts',
     'COLUMN', 'owner_only'
go

exec sp_addextendedproperty 'MS_Description', N'только на норму', 'SCHEMA', 'dbo', 'TABLE', 'Discounts', 'COLUMN',
     'norma_only'
go

exec sp_addextendedproperty 'MS_Description', N'только не трудоспособным', 'SCHEMA', 'dbo', 'TABLE', 'Discounts',
     'COLUMN', 'nowork_only'
go

