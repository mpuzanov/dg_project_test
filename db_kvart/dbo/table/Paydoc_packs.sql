create table Paydoc_packs
(
    id              int identity
        constraint PK_PAYDOC_PACKS
            primary key,
    fin_id          smallint                            not null,
    source_id       int                                 not null
        constraint FK_PAYDOC_PACKS_PAYCOLL_ORGS
            references Paycoll_orgs
            on update cascade on delete cascade,
    day             smalldatetime                       not null,
    docsnum         int                                 not null,
    total           decimal(15, 2)
        constraint DF_PAYDOC_PACKS_total default 0      not null,
    checked         bit
        constraint DF_PAYDOC_PACKS_checked default 0    not null,
    forwarded       bit
        constraint DF_PAYDOC_PACKS_forwarded default 0  not null,
    blocked         bit
        constraint DF_PAYDOC_PACKS_blocked default 0    not null,
    user_edit       smallint,
    date_edit       smalldatetime,
    tip_id          smallint,
    commission      decimal(9, 2)
        constraint DF_PAYDOC_PACKS_commission default 0 not null,
    sup_id          int                                 not null,
    send_data_check smalldatetime,
    pack_uid        uniqueidentifier
)
go

exec sp_addextendedproperty 'MS_Description', N'Пачки с платежами', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs'
go

exec sp_addextendedproperty 'MS_Description', N'номер пачки', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'фин. период', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'источник платежа', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'source_id'
go

exec sp_addextendedproperty 'MS_Description', N'день платежей в пачке', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs',
     'COLUMN', 'day'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во платежей в пачке', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs',
     'COLUMN', 'docsnum'
go

exec sp_addextendedproperty 'MS_Description', N'сумма', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN', 'total'
go

exec sp_addextendedproperty 'MS_Description', N'проверена', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'checked'
go

exec sp_addextendedproperty 'MS_Description', N'признак закрытия', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'forwarded'
go

exec sp_addextendedproperty 'MS_Description', N'признак блокировки', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'blocked'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs',
     'COLUMN', 'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'тип фонда в пачке', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'комиссия', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'commission'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Paydoc_packs', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Дата формирования фискальных чеков по пачке', 'SCHEMA', 'dbo', 'TABLE',
     'Paydoc_packs', 'COLUMN', 'send_data_check'
go

