create table Person_calc
(
    status_id  varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_PERSON_CALC_PERSON_STATUSES
            references Person_statuses
            on update cascade on delete cascade,
    service_id varchar(10)                           not null collate SQL_Latin1_General_CP1251_CI_AS,
    have_paym  bit                                   not null,
    is_rates   smallint
        constraint DF_PERSON_CALC_is_rates default 1 not null
        constraint CK_PERSON_CALC
            check ([is_rates] = 3 OR ([is_rates] = 2 OR [is_rates] = 1)),
    constraint PK_PERSON_CALC
        primary key (status_id, service_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'начисление по услугам в зависимости от статуса прописки', 'SCHEMA',
     'dbo', 'TABLE', 'Person_calc'
go

exec sp_addextendedproperty 'MS_Description', N'код статуса прописки', 'SCHEMA', 'dbo', 'TABLE', 'Person_calc',
     'COLUMN', 'status_id'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Person_calc', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак начисления по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Person_calc',
     'COLUMN', 'have_paym'
go

exec sp_addextendedproperty 'MS_Description', N'код группы тарифов', 'SCHEMA', 'dbo', 'TABLE', 'Person_calc', 'COLUMN',
     'is_rates'
go

