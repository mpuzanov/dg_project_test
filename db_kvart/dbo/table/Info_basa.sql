create table Info_basa
(
    Fin_id                smallint                  not null,
    tip_id                smallint                  not null,
    sup_name              varchar(30)
        constraint DF_INFO_BASA_sup_name default '' not null collate SQL_Latin1_General_CP1251_CI_AS,
    StrFinId              char(15) collate SQL_Latin1_General_CP1251_CI_AS,
    KolLic                int,
    KolBuilds             int,
    KolFlats              int,
    KolPeople             int,
    SumOplata             decimal(15, 2),
    SumOplataMes          decimal(15, 2),
    SumValue              decimal(15, 2),
    SumLgota              decimal(15, 2),
    SumSubsidia           decimal(15, 2),
    SumAdded              decimal(15, 2),
    SumPaymAccount        decimal(15, 2),
    SumPaymAccount_peny   decimal(15, 2),
    SumPaymAccountCounter decimal(15, 2),
    SumPenalty            decimal(15, 2),
    SumSaldo              decimal(15, 2),
    SumTotal_SQ           decimal(15, 2),
    SumDolg               decimal(15, 2),
    ProcentOplata         decimal(15, 2)
        constraint DF_INFO_BASA_ProcentOplata default 0,
    SumDebt               as ([sumsaldo] + [sumvalue] + [sumadded]) - ([sumpaymaccount] - [sumpaymaccount_peny]),
    constraint PK_INFO_BASA_1
        primary key (Fin_id, tip_id, sup_name)
)
go

exec sp_addextendedproperty 'MS_Description', N'Общая информация по базе за фин. периоды', 'SCHEMA', 'dbo', 'TABLE',
     'Info_basa'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'Fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код типа жил. фонда', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'название месяца , год', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'StrFinId'
go

exec sp_addextendedproperty 'MS_Description', N'кол. лицевых', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN', 'KolLic'
go

exec sp_addextendedproperty 'MS_Description', N'кол. домов', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'KolBuilds'
go

exec sp_addextendedproperty 'MS_Description', N'кол. квартир', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'KolFlats'
go

exec sp_addextendedproperty 'MS_Description', N'кол. людей', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'KolPeople'
go

exec sp_addextendedproperty 'MS_Description', N'сумма к оплате', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumOplata'
go

exec sp_addextendedproperty 'MS_Description', N'сумма к оплате в этом месяце', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa',
     'COLUMN', 'SumOplataMes'
go

exec sp_addextendedproperty 'MS_Description', N'начисленно', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN', 'SumValue'
go

exec sp_addextendedproperty 'MS_Description', N'сумма льготы', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumLgota'
go

exec sp_addextendedproperty 'MS_Description', N'сумма субсидий', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumSubsidia'
go

exec sp_addextendedproperty 'MS_Description', N'сумма разовых', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumAdded'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumPaymAccount'
go

exec sp_addextendedproperty 'MS_Description', N'сумма пени', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumPenalty'
go

exec sp_addextendedproperty 'MS_Description', N'входящее сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumSaldo'
go

exec sp_addextendedproperty 'MS_Description', N'Общая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumTotal_SQ'
go

exec sp_addextendedproperty 'MS_Description', N'конечное сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Info_basa', 'COLUMN',
     'SumDebt'
go

