create table Service_units
(
    fin_id      smallint                             not null,
    service_id  varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_SERVICE_UNITS_SERVICES
            references Services
            on update cascade,
    roomtype_id varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_SERVICE_UNITS_ROOM_TYPES
            references Room_types,
    tip_id      smallint
        constraint DF_SERVICE_UNITS_tip_id default 1 not null
        constraint FK_SERVICE_UNITS_OCCUPATION_TYPES
            references Occupation_Types
            on update cascade on delete cascade,
    unit_id     varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_SERVICE_UNITS_UNITS
            references Units,
    constraint PK_SERVICE_UNITS
        primary key (fin_id, service_id, roomtype_id, tip_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Единицы измерения по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Service_units'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Service_units', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Service_units', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'тип квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Service_units', 'COLUMN',
     'roomtype_id'
go

exec sp_addextendedproperty 'MS_Description', N'Тип жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Service_units', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'единица измерения', 'SCHEMA', 'dbo', 'TABLE', 'Service_units', 'COLUMN',
     'unit_id'
go

