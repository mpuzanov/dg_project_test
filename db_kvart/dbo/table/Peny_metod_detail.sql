create table Peny_metod_detail
(
    metod_id smallint not null
        constraint FK_PENY_METOD_DETAIL_PENY_METOD
            references Peny_metod,
    day1     smallint not null,
    day2     smallint not null,
    koef     smallint not null,
    comments varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_PENY_METOD_DETAIL_1
        primary key (metod_id, day1, day2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Настройки расчёта пени по методам', 'SCHEMA', 'dbo', 'TABLE',
     'Peny_metod_detail'
go

exec sp_addextendedproperty 'MS_Description', N'Код метода расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod_detail',
     'COLUMN', 'metod_id'
go

exec sp_addextendedproperty 'MS_Description', N'день от', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod_detail', 'COLUMN',
     'day1'
go

exec sp_addextendedproperty 'MS_Description', N'день по', 'SCHEMA', 'dbo', 'TABLE', 'Peny_metod_detail', 'COLUMN',
     'day2'
go

exec sp_addextendedproperty 'MS_Description', N'используемый коэффициент для расчёта', 'SCHEMA', 'dbo', 'TABLE',
     'Peny_metod_detail', 'COLUMN', 'koef'
go

