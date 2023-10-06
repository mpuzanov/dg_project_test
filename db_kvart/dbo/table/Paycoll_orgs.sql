create table Paycoll_orgs
(
    id                 int identity
        constraint PK_PAYCOLL_ORGS
            primary key,
    fin_id             smallint                             not null,
    bank               int                                  not null
        constraint FK_PAYCOLL_ORGS_BANK
            references Bank
            on update cascade on delete cascade,
    vid_paym           varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_PAYCOLL_ORGS_PAYING_TYPES
            references Paying_types
            on update cascade on delete cascade,
    comision           decimal(15, 4)
        constraint DF_PAYCOLL_ORGS_comision default 0       not null,
    ext                varchar(10)                          not null collate SQL_Latin1_General_CP1251_CI_AS,
    description        varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    data_edit          smalldatetime,
    user_edit          varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    user_id            smallint,
    sup_processing     smallint
        constraint DF_PAYCOLL_ORGS_sup_processing default 0 not null,
    paying_order_metod varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_PAYCOLL_ORGS_paying_order_metod
            check ([paying_order_metod] IS NULL OR ([paying_order_metod] = 'пени2' OR [paying_order_metod] = 'пени1')),
    paycoll_uid        uniqueidentifier,
    bank_uid           uniqueidentifier,
    constraint IX_PAYCOLL_ORGS
        unique (fin_id, ext)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список параметров организаций принимающих платежи по фин. периодам',
     'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код банка', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN', 'bank'
go

exec sp_addextendedproperty 'MS_Description', N'код типа платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'vid_paym'
go

exec sp_addextendedproperty 'MS_Description', N'комиссия банка', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'comision'
go

exec sp_addextendedproperty 'MS_Description', N'расширение файла с платежами', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs',
     'COLUMN', 'ext'
go

exec sp_addextendedproperty 'MS_Description', N'описание', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'description'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs',
     'COLUMN', 'data_edit'
go

exec sp_addextendedproperty 'MS_Description', N'логин пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Paycoll_orgs', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description',
     N'Обработка платежей: 0-все; 1 - только поставщиков; 2 - только без поставщиков', 'SCHEMA', 'dbo', 'TABLE',
     'Paycoll_orgs', 'COLUMN', 'sup_processing'
go

exec sp_addextendedproperty 'MS_Description', N'Метод погашения оплаты пени(пени1 или пени2)', 'SCHEMA', 'dbo', 'TABLE',
     'Paycoll_orgs', 'COLUMN', 'paying_order_metod'
go

