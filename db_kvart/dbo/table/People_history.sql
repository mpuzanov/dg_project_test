create table People_history
(
    fin_id      smallint    not null,
    occ         int         not null,
    owner_id    int         not null,
    lgota_id    smallint    not null,
    status_id   tinyint,
    status2_id  varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    kol_day     tinyint     not null,
    KolDayLgota tinyint     not null,
    data1       smalldatetime,
    data2       smalldatetime,
    lgota_kod   int,
    DateEnd     smalldatetime,
    constraint PK_PEOPLE_HISTORY
        primary key (fin_id, occ, owner_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История по людям', 'SCHEMA', 'dbo', 'TABLE', 'People_history'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'lgota_id'
go

exec sp_addextendedproperty 'MS_Description', N'код соц. статуса', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'status_id'
go

exec sp_addextendedproperty 'MS_Description', N'код статуса прописки', 'SCHEMA', 'dbo', 'TABLE', 'People_history',
     'COLUMN', 'status2_id'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во дней проживал в этом месяце', 'SCHEMA', 'dbo', 'TABLE',
     'People_history', 'COLUMN', 'kol_day'
go

exec sp_addextendedproperty 'MS_Description', N'кол. дней льготы', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'KolDayLgota'
go

exec sp_addextendedproperty 'MS_Description', N'начальная дата проживания в этом месяце', 'SCHEMA', 'dbo', 'TABLE',
     'People_history', 'COLUMN', 'data1'
go

exec sp_addextendedproperty 'MS_Description', N'конечная дата', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'data2'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'People_history', 'COLUMN',
     'lgota_kod'
go

