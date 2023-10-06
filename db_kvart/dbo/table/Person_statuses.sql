create table Person_statuses
(
    id              varchar(10)                                 not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_PERSON_STATUSES
            primary key,
    name            varchar(30)                                 not null collate SQL_Latin1_General_CP1251_CI_AS,
    short_name      varchar(15)                                 not null collate SQL_Latin1_General_CP1251_CI_AS,
    is_paym         bit
        constraint DF_PERSON_STATUSES_is_paym default 1         not null,
    is_lgota        bit
        constraint DF_PERSON_STATUSES_is_lgota default 1        not null,
    is_subs         bit
        constraint DF_PERSON_STATUSES_is_subs default 1         not null,
    is_norma_all    bit
        constraint DF_PERSON_STATUSES_is_norma_all default 0    not null,
    is_norma        bit
        constraint DF_PERSON_STATUSES_is_norma default 0        not null,
    is_norma_sub    bit
        constraint DF_PERSON_STATUSES_is_norma_sub1 default 0   not null,
    is_kolpeople    bit
        constraint DF_PERSON_STATUSES_is_kolpeople default 1    not null,
    id_no           smallint
        constraint DF_PERSON_STATUSES_id_no_1 default 10        not null,
    is_registration bit
        constraint DF_PERSON_STATUSES_is_registration default 0 not null,
    is_temp         char collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Статусы прописок', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses'
go

exec sp_addextendedproperty 'MS_Description', N'код статуса прописки', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'короткое название', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'short_name'
go

exec sp_addextendedproperty 'MS_Description', N'признак начисления', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'is_paym'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчета льготы', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'is_lgota'
go

exec sp_addextendedproperty 'MS_Description', N'признак расчета субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'is_subs'
go

exec sp_addextendedproperty 'MS_Description', N'расчет в общей норме', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'is_norma_all'
go

exec sp_addextendedproperty 'MS_Description', N'расчет нормы', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses', 'COLUMN',
     'is_norma'
go

exec sp_addextendedproperty 'MS_Description', N'расчет нормы для субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'is_norma_sub'
go

exec sp_addextendedproperty 'MS_Description', N'участие в подсчете кол-ва людей в отчётах', 'SCHEMA', 'dbo', 'TABLE',
     'Person_statuses', 'COLUMN', 'is_kolpeople'
go

exec sp_addextendedproperty 'MS_Description', N'номер для сортировки', 'SCHEMA', 'dbo', 'TABLE', 'Person_statuses',
     'COLUMN', 'id_no'
go

exec sp_addextendedproperty 'MS_Description', N'участие в подсчете кол-ва зарегистрированых на л/сч (в квитанции)',
     'SCHEMA', 'dbo', 'TABLE', 'Person_statuses', 'COLUMN', 'is_registration'
go

exec sp_addextendedproperty 'MS_Description', N'Признак временной регистрации', 'SCHEMA', 'dbo', 'TABLE',
     'Person_statuses', 'COLUMN', 'is_temp'
go

