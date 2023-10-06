create table Koef_occ
(
    occ        int         not null,
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    Level1     smallint    not null,
    koef_id    int,
    constraint PK_KOEF_OCC
        primary key (occ, service_id, Level1)
)
go

exec sp_addextendedproperty 'MS_Description', N'Значения возможных коэффициенов на лицевых счетах', 'SCHEMA', 'dbo',
     'TABLE', 'Koef_occ'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Koef_occ', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код услуги', 'SCHEMA', 'dbo', 'TABLE', 'Koef_occ', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'уровень 1', 'SCHEMA', 'dbo', 'TABLE', 'Koef_occ', 'COLUMN', 'Level1'
go

exec sp_addextendedproperty 'MS_Description', N'код коэф.', 'SCHEMA', 'dbo', 'TABLE', 'Koef_occ', 'COLUMN', 'koef_id'
go

