create table Pensia
(
    ID       int identity
        constraint PK_PENSIA
            primary key,
    FIN_ID   smallint                           not null,
    ORGAN_ID smallint
        constraint DF_PENSIA_ORGAN_ID default 1 not null,
    FAMILY   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    NAME     varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    FATHER   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    D_ROGD   datetime,
    NAI_PEN  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    OSNOVAN  varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    PUNKT    varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    STREET   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    HOUSE    varchar(12) collate SQL_Latin1_General_CP1251_CI_AS,
    KORP     varchar(5) collate SQL_Latin1_General_CP1251_CI_AS,
    FLAT     varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    RAION    smallint,
    RAB      smallint,
    SUM1     smallmoney,
    SUM2     smallmoney,
    SUM3     smallmoney,
    SUM4     smallmoney,
    SUM5     smallmoney,
    SUM6     smallmoney,
    ITOGO    as coalesce([SUM1], 0) + coalesce([SUM2], 0) + coalesce([SUM3], 0) + coalesce([SUM4], 0) +
                coalesce([SUM5], 0) + coalesce([SUM6], 0)
)
go

exec sp_addextendedproperty 'MS_Description', N'Информация из организаций по социальным выплатам', 'SCHEMA', 'dbo',
     'TABLE', 'Pensia'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'ID'
go

exec sp_addextendedproperty 'MS_Description', N'Код  фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'FIN_ID'
go

exec sp_addextendedproperty 'MS_Description', N'код организации', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'ORGAN_ID'
go

exec sp_addextendedproperty 'MS_Description', N'Фамилия', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'FAMILY'
go

exec sp_addextendedproperty 'MS_Description', N'Имя', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'NAME'
go

exec sp_addextendedproperty 'MS_Description', N'Отчество', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'FATHER'
go

exec sp_addextendedproperty 'MS_Description', N'Дата рождения', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'D_ROGD'
go

exec sp_addextendedproperty 'MS_Description', N'Вид назначенной пенсии', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'NAI_PEN'
go

exec sp_addextendedproperty 'MS_Description', N'Основание.
Перечисляются через запятую номера пенсионных дел', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'OSNOVAN'
go

exec sp_addextendedproperty 'MS_Description', N'Город проживания', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'PUNKT'
go

exec sp_addextendedproperty 'MS_Description', N'Улица', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'STREET'
go

exec sp_addextendedproperty 'MS_Description', N'Дом', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'HOUSE'
go

exec sp_addextendedproperty 'MS_Description', N'Корпус', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'KORP'
go

exec sp_addextendedproperty 'MS_Description', N'Квартира', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'FLAT'
go

exec sp_addextendedproperty 'MS_Description', N'Код района', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN', 'RAION'
go

exec sp_addextendedproperty 'MS_Description', N'0- пенсионер не работает, 1-работает', 'SCHEMA', 'dbo', 'TABLE',
     'Pensia', 'COLUMN', 'RAB'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма назначенной пенсии', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'SUM1'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма назначенной пенсии', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'SUM2'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма назначенной пенсии', 'SCHEMA', 'dbo', 'TABLE', 'Pensia', 'COLUMN',
     'SUM3'
go

