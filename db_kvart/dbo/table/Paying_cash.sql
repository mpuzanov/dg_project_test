create table Paying_cash
(
    paying_id    int                              not null
        constraint FK_PAYING_CASH_PAYINGS
            references Payings
            on update cascade on delete cascade,
    service_name varchar(50)                      not null collate SQL_Latin1_General_CP1251_CI_AS,
    value_cash   decimal(9, 2)
        constraint DF_PAYING_CASH_value default 0 not null,
    constraint PK_Paying_cash
        primary key (paying_id, service_name)
)
go

exec sp_addextendedproperty 'MS_Description', N'Платежи по услугам для чеков (для налоговой)', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cash'
go

exec sp_addextendedproperty 'MS_Description', N'код платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paying_cash', 'COLUMN',
     'paying_id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование услуги в квитанции', 'SCHEMA', 'dbo', 'TABLE',
     'Paying_cash', 'COLUMN', 'service_name'
go

exec sp_addextendedproperty 'MS_Description', N'сумма в чеке по услуге', 'SCHEMA', 'dbo', 'TABLE', 'Paying_cash',
     'COLUMN', 'value_cash'
go

