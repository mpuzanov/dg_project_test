create table Dom_svod
(
    fin_id           smallint                             not null,
    build_id         int                                  not null,
    CountLic         int
        constraint DF_DOM_SVOD_CountLic default 0         not null,
    CountFlats       int
        constraint DF_DOM_SVOD_CountFlats default 0       not null,
    Square           decimal(15, 2)
        constraint DF_DOM_SVOD_Square default 0           not null,
    SquareLive       decimal(15, 2)
        constraint DF_DOM_SVOD_SquareLive default 0       not null,
    CurrentDate      smalldatetime                        not null,
    CountPeople      int
        constraint DF_DOM_SVOD_CountPeople default 0      not null,
    CountPeopleLgot  int
        constraint DF_DOM_SVOD_CountPeopleLgot default 0  not null,
    CountLicLgot     int
        constraint DF_DOM_SVOD_CountLicLgot default 0     not null,
    CountLicSubsid   int
        constraint DF_DOM_SVOD_CountLicSubsid default 0   not null,
    CountIPU         int
        constraint DF_DOM_SVOD_CountIPU default 0         not null,
    CountOPU         int
        constraint DF_DOM_SVOD_CountOPU default 0         not null,
    CountFlatsIPU    int
        constraint DF_DOM_SVOD_CountFlatsIPU default 0    not null,
    CountPeopleIPU   int
        constraint DF_DOM_SVOD_CountPeopleIPU default 0   not null,
    CountFlatsNoIPU  int
        constraint DF_Dom_svod_CountFlatsNoIPU default 0  not null,
    CountPeopleNoIPU int
        constraint DF_Dom_svod_CountPeopleNoIPU default 0 not null,
    constraint PK_DOM_SVOD
        primary key (fin_id, build_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Сводная информация по дому', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN', 'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'кол. лицевых', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'CountLic'
go

exec sp_addextendedproperty 'MS_Description', N'кол. квартир', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'CountFlats'
go

exec sp_addextendedproperty 'MS_Description', N'общая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN', 'Square'
go

exec sp_addextendedproperty 'MS_Description', N'жилая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'SquareLive'
go

exec sp_addextendedproperty 'MS_Description', N'дата формирования записи', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CurrentDate'
go

exec sp_addextendedproperty 'MS_Description', N'кол. человек', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'CountPeople'
go

exec sp_addextendedproperty 'MS_Description', N'кол. льготников', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod', 'COLUMN',
     'CountPeopleLgot'
go

exec sp_addextendedproperty 'MS_Description', N'кол. лицевых со льготой', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CountLicLgot'
go

exec sp_addextendedproperty 'MS_Description', N'кол. лицевых с субсидией', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CountLicSubsid'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во индивидуальных счётчиков', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CountIPU'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во общедомовых счётчиков', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CountOPU'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во квартир со счётчиками', 'SCHEMA', 'dbo', 'TABLE', 'Dom_svod',
     'COLUMN', 'CountFlatsIPU'
go

