create table Intprint
(
    fin_id                smallint                          not null,
    occ                   int                               not null
        constraint FK_Intprint_Occupations
            references Occupations
            on update cascade on delete cascade,
    SumPaym               decimal(15, 4)                    not null,
    Initials              varchar(120)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    Lgota                 varchar(20)                       not null collate SQL_Latin1_General_CP1251_CI_AS,
    total_people          smallint                          not null,
    Total_sq              smallmoney                        not null,
    Living_sq             smallmoney                        not null,
    FinPeriod             smalldatetime                     not null,
    saldo                 decimal(15, 4)                    not null,
    PaymAccount           decimal(15, 2)                    not null,
    PaymAccount_peny      decimal(15, 2)
        constraint DF_INTPRINT_PaymAccount_peny default 0   not null,
    Debt                  decimal(15, 4)                    not null,
    epd_dolg              decimal(15, 2)
        constraint DF_Intprint_epd_dolg default 0           not null,
    epd_overpayment       decimal(15, 2)
        constraint DF_Intprint_epd_overpayment default 0    not null,
    LastDayPaym           smalldatetime,
    LastDayPaym2          smalldatetime,
    PersonStatus          varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    Penalty_value         decimal(9, 2)
        constraint DF_INTPRINT_Penalty_value default 0      not null,
    StrSubsidia1          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    StrSubsidia2          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    StrSubsidia3          varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    KolMesDolg            decimal(5, 1)
        constraint DF_INTPRINT_KolMesDolg default 0         not null,
    DateCreate            smalldatetime,
    KolMesDolgAll         decimal(5, 1)
        constraint DF_INTPRINT_KolMesDolgAll default 0      not null,
    Initials_owner_id     int,
    Penalty_period        decimal(9, 2),
    Penalty_old           decimal(9, 2),
    PaymAccount_storno    decimal(9, 2)
        constraint DF_Intprint_PaymAccount_storno default 0 not null,
    rasschet              varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    qrData                nvarchar(2000) collate SQL_Latin1_General_CP1251_CI_AS,
    epd_saldo_dolg        decimal(15, 2),
    epd_saldo_overpayment decimal(15, 2),
    constraint PK_INTPRINT_1
        primary key (fin_id, occ)
)
go

exec sp_addextendedproperty 'MS_Description', N'Информация для счетов-квитанций по фин. периодам', 'SCHEMA', 'dbo',
     'TABLE', 'Intprint'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'начислено к оплате', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'SumPaym'
go

exec sp_addextendedproperty 'MS_Description', N'Инициалы квартиросъемщика', 'SCHEMA', 'dbo', 'TABLE', 'Intprint',
     'COLUMN', 'Initials'
go

exec sp_addextendedproperty 'MS_Description', N'список льгот на лицевом', 'SCHEMA', 'dbo', 'TABLE', 'Intprint',
     'COLUMN', 'Lgota'
go

exec sp_addextendedproperty 'MS_Description', N'кол. человек', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'total_people'
go

exec sp_addextendedproperty 'MS_Description', N'Общая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'Total_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Жилая площадь', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'Living_sq'
go

exec sp_addextendedproperty 'MS_Description', N'Фин. период (1 число)', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'FinPeriod'
go

exec sp_addextendedproperty 'MS_Description', N'начальное сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'saldo'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN', 'PaymAccount'
go

exec sp_addextendedproperty 'MS_Description', N'оплачено пени', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'PaymAccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'конечное сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN', 'Debt'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма долга без учёта переплаты на конец периода', 'SCHEMA', 'dbo',
     'TABLE', 'Intprint', 'COLUMN', 'epd_dolg'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма переплаты без учета долга на конец периода', 'SCHEMA', 'dbo',
     'TABLE', 'Intprint', 'COLUMN', 'epd_overpayment'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты прошлого месяца', 'SCHEMA', 'dbo', 'TABLE',
     'Intprint', 'COLUMN', 'LastDayPaym'
go

exec sp_addextendedproperty 'MS_Description', N'Последний день оплаты текущего месяца', 'SCHEMA', 'dbo', 'TABLE',
     'Intprint', 'COLUMN', 'LastDayPaym2'
go

exec sp_addextendedproperty 'MS_Description', N'имеющееся статусы прописки на лицевом', 'SCHEMA', 'dbo', 'TABLE',
     'Intprint', 'COLUMN', 'PersonStatus'
go

exec sp_addextendedproperty 'MS_Description', N'сумма пени', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'Penalty_value'
go

exec sp_addextendedproperty 'MS_Description', N'строка по субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'StrSubsidia1'
go

exec sp_addextendedproperty 'MS_Description', N'строка по субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'StrSubsidia2'
go

exec sp_addextendedproperty 'MS_Description', N'строка по субсидии', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'StrSubsidia3'
go

exec sp_addextendedproperty 'MS_Description', N'кол. месяцев долга', 'SCHEMA', 'dbo', 'TABLE', 'Intprint', 'COLUMN',
     'KolMesDolg'
go

exec sp_addextendedproperty 'MS_Description', N'дата формирования записи', 'SCHEMA', 'dbo', 'TABLE', 'Intprint',
     'COLUMN', 'DateCreate'
go

exec sp_addextendedproperty 'MS_Description', N'Код ответственного квартиросъёмщика', 'SCHEMA', 'dbo', 'TABLE',
     'Intprint', 'COLUMN', 'Initials_owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Данные для генерации QR - кода клиенту (например: СБП)', 'SCHEMA',
     'dbo', 'TABLE', 'Intprint', 'COLUMN', 'qrData'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма долга без учёта переплаты на начало периода', 'SCHEMA', 'dbo',
     'TABLE', 'Intprint', 'COLUMN', 'epd_saldo_dolg'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма переплаты без учета долга на начало периода', 'SCHEMA', 'dbo',
     'TABLE', 'Intprint', 'COLUMN', 'epd_saldo_overpayment'
go

