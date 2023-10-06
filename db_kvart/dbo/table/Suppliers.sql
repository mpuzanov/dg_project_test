create table Suppliers
(
    id_key       int identity
        constraint PK_SUPPLIERS_1
            primary key,
    service_id   varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Suppliers_Services
            references Services
            on update cascade,
    account_one  bit
        constraint DF_SUPPLIERS_account_one default 0 not null,
    sup_id       int                                  not null
        constraint FK_SUPPLIERS_SUPPLIERS_ALL
            references Suppliers_all,
    id           int,
    name         varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    id_accounts  int,
    bank_account int
)
go

exec sp_addextendedproperty 'MS_Description', N'Поставщики по услугам', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers'
go

exec sp_addextendedproperty 'MS_Description', N'Услуга', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN', 'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'признак отдельной квитанции по поставщику', 'SCHEMA', 'dbo', 'TABLE',
     'Suppliers', 'COLUMN', 'account_one'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Название', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'код квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN',
     'id_accounts'
go

exec sp_addextendedproperty 'MS_Description', N'код банковского счёта', 'SCHEMA', 'dbo', 'TABLE', 'Suppliers', 'COLUMN',
     'bank_account'
go

