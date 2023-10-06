create table Added_Payments
(
    id             int identity
        constraint PK_ADDED
            primary key nonclustered,
    occ            int                                not null
        constraint FK_Added_Payments_Occupations
            references Occupations
            on update cascade on delete cascade,
    service_id     varchar(10)                        not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Added_Payments_Services
            references Services
            on update cascade,
    sup_id         int
        constraint DF_ADDED_PAYMENTS_sup_id default 0 not null,
    add_type       smallint                           not null
        constraint FK_Added_Payments_Added_Types
            references Added_Types,
    value          decimal(9, 2)                      not null,
    doc            varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    data1          smalldatetime,
    data2          smalldatetime,
    Hours          smallint,
    add_type2      smallint,
    manual_bit     bit,
    Vin1           int,
    Vin2           int,
    doc_no         varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    doc_date       smalldatetime,
    user_edit      smallint,
    dsc_owner_id   int,
    fin_id_paym    smallint,
    date_edit      smalldatetime,
    comments       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    tnorm2         smallint,
    kol            decimal(12, 6),
    fin_id         smallint,
    repeat_for_fin smallint
)
go

exec sp_addextendedproperty 'MS_Description', N'Разовые', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'услуга', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'service_id'
go

exec sp_addextendedproperty 'MS_Description', N'код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'тип разового', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'add_type'
go

exec sp_addextendedproperty 'MS_Description', N'сумма', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'документ', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'doc'
go

exec sp_addextendedproperty 'MS_Description', N'Начальная дата перерасчёта', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments',
     'COLUMN', 'data1'
go

exec sp_addextendedproperty 'MS_Description', N'Конечная дата перерасчёта', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments',
     'COLUMN', 'data2'
go

exec sp_addextendedproperty 'MS_Description', N'Часы', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'Hours'
go

exec sp_addextendedproperty 'MS_Description', N'под тип разового', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'add_type2'
go

exec sp_addextendedproperty 'MS_Description', N'Признак ручной установки суммы', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Payments', 'COLUMN', 'manual_bit'
go

exec sp_addextendedproperty 'MS_Description', N'Код виновника (ЖРП)', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments',
     'COLUMN', 'Vin1'
go

exec sp_addextendedproperty 'MS_Description', N'Код виновника поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments',
     'COLUMN', 'Vin2'
go

exec sp_addextendedproperty 'MS_Description', N'Номер документа', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'doc_no'
go

exec sp_addextendedproperty 'MS_Description', N'Дата документа', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'doc_date'
go

exec sp_addextendedproperty 'MS_Description', N'Код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'код льготника', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'dsc_owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода на основании которого был произведён расчёт разовых',
     'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN', 'fin_id_paym'
go

exec sp_addextendedproperty 'MS_Description', N'Дата редактирования(расчёта)', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Payments', 'COLUMN', 'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Температура отклонения от нормы', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Payments', 'COLUMN', 'tnorm2'
go

exec sp_addextendedproperty 'MS_Description', N'Количество единиц (объём услуги)', 'SCHEMA', 'dbo', 'TABLE',
     'Added_Payments', 'COLUMN', 'kol'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Added_Payments', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Повторять перерасчёт каждый месяц по заданный период', 'SCHEMA', 'dbo',
     'TABLE', 'Added_Payments', 'COLUMN', 'repeat_for_fin'
go

