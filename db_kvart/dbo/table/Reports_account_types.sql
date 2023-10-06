create table Reports_account_types
(
    tip_id     smallint not null,
    id_account int      not null
        constraint FK_Reports_account_types_Reports_account
            references Reports_account
            on delete cascade,
    constraint PK_REPORTS_ACCOUNT_TYPES
        primary key (tip_id, id_account)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список доступных для печати квитанций по типу фонда', 'SCHEMA', 'dbo',
     'TABLE', 'Reports_account_types'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account_types',
     'COLUMN', 'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'код квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Reports_account_types',
     'COLUMN', 'id_account'
go

