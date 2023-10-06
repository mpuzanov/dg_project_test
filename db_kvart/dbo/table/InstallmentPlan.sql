create table InstallmentPlan
(
    pid_id       int           not null
        constraint FK_InstallmentPlan_Pid
            references Pid,
    date_payment smalldatetime not null,
    summa        decimal(9, 2) not null,
    constraint PK_InstallmentPlan
        primary key (pid_id, date_payment)
)
go

exec sp_addextendedproperty 'MS_Description', N'План рассрочки платежей по соглашению (ПИД)', 'SCHEMA', 'dbo', 'TABLE',
     'InstallmentPlan'
go

