create table Living_wage
(
    status_id smallint      not null
        constraint FK_LIVING_WAGE_STATUS
            references Status
            on update cascade on delete cascade,
    data_pm   smalldatetime not null,
    summa_pm  decimal(9, 2) not null,
    constraint PK_LIVING_WAGE
        primary key (status_id, data_pm)
)
go

exec sp_addextendedproperty 'MS_Description', N'Прожиточные минимумы', 'SCHEMA', 'dbo', 'TABLE', 'Living_wage'
go

