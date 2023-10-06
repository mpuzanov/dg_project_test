create table Paying_cessia
(
    paying_id       int                                       not null
        constraint PK_PAYING_CESSIA
            primary key
        constraint FK_PAYING_CESSIA_PAYINGS
            references Payings
            on delete cascade,
    value_ces       decimal(9, 2)
        constraint DF_PAYING_CESSIA_value_sec default 0       not null,
    kol_ces         decimal(5, 2)
        constraint DF_PAYING_CESSIA_kol_ces default 0         not null,
    paymaccount_ces decimal(9, 2)
        constraint DF_PAYING_CESSIA_paymaccount_out default 0 not null,
    value_col       decimal(9, 2),
    kol_col         decimal(5, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Платежи по цессии', 'SCHEMA', 'dbo', 'TABLE', 'Paying_cessia'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма вознаграждения по цессии', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cessia', 'COLUMN', 'value_ces'
go

exec sp_addextendedproperty 'MS_Description', N'Процент вознаграждения по цессии', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cessia', 'COLUMN', 'kol_ces'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма вознаграждения коллектору', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cessia', 'COLUMN', 'value_col'
go

exec sp_addextendedproperty 'MS_Description', N'Процент вознаграждения коллектору', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cessia', 'COLUMN', 'kol_col'
go

