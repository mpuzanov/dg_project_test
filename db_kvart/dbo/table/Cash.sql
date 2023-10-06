create table Cash
(
    id       int identity
        constraint PK_CASH
            primary key,
    name     varchar(50) not null collate SQL_Latin1_General_CP1251_CI_AS,
    num_cash varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    num_fn   varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    tip_id   smallint    not null
        constraint FK_CASH_OCCUPATION_TYPES
            references Occupation_Types
)
go

exec sp_addextendedproperty 'MS_Description', N'Контрольно-кассовая техника', 'SCHEMA', 'dbo', 'TABLE', 'Cash'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Cash', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'регистрационный номер ККТ', 'SCHEMA', 'dbo', 'TABLE', 'Cash', 'COLUMN',
     'num_cash'
go

exec sp_addextendedproperty 'MS_Description', N'Номер фискального регистратора', 'SCHEMA', 'dbo', 'TABLE', 'Cash',
     'COLUMN', 'num_fn'
go

exec sp_addextendedproperty 'MS_Description', N'Тип жилого фонда', 'SCHEMA', 'dbo', 'TABLE', 'Cash', 'COLUMN', 'tip_id'
go

