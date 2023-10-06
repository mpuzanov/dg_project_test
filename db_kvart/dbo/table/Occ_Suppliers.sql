create table Occ_Suppliers
(
    fin_id              smallint                               not null,
    occ                 int                                    not null
        constraint FK_OCC_SUPPLIERS_OCCUPATIONS
            references Occupations
            on update cascade on delete cascade,
    sup_id              int                                    not null
        constraint FK_OCC_SUPPLIERS_SUPPLIERS_ALL
            references Suppliers_all,
    occ_sup             int                                    not null,
    saldo               decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_saldo default 0            not null,
    value               decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_value default 0            not null,
    added               decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_added default 0            not null,
    paid                decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_paid default 0             not null,
    paymaccount         decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_paymaccount default 0      not null,
    paymaccount_peny    decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_PaymAccount_peny default 0 not null,
    penalty_calc        bit
        constraint DF_OCC_SUPPLIERS_Penalty_calc default 1     not null,
    penalty_old_edit    smallint
        constraint DF_OCC_SUPPLIERS_Penalty_old_edit default 0 not null,
    penalty_old         decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_Penalty_old default 0      not null,
    penalty_old_new     decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_Penalty_old_new default 0  not null,
    penalty_added       decimal(9, 2)
        constraint DF_Occ_Suppliers_Penalty_added default 0    not null,
    penalty_value       decimal(9, 2)
        constraint DF_OCC_SUPPLIERS_Penalty_value default 0    not null,
    kolMesDolg          decimal(5, 1)
        constraint DF_OCC_SUPPLIERS_KolMesDolg default 0       not null,
    debt                as ([saldo] + [paid]) - ([paymaccount] - [paymaccount_peny]),
    paid_old            decimal(9, 2),
    dog_int             int,
    cessia_dolg_mes_old smallint,
    cessia_dolg_mes_new smallint,
    id_jku_gis          varchar(13) collate SQL_Latin1_General_CP1251_CI_AS,
    rasschet            varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    occ_sup_uid         uniqueidentifier,
    schtl_old           varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    paymaccount_storno  decimal(9, 2)
        constraint DF__Occ_Suppl__PaymA__77CAB889 default 0,
    qrData              nvarchar(2000) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_OCC_SUPPLIERS
        primary key (fin_id, occ, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Лицевые счета по поставщикам', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой счёт поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers',
     'COLUMN', 'occ_sup'
go

exec sp_addextendedproperty 'MS_Description', N'вх. сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'saldo'
go

exec sp_addextendedproperty 'MS_Description', N'Начислено', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN', 'value'
go

exec sp_addextendedproperty 'MS_Description', N'Разовые', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN', 'added'
go

exec sp_addextendedproperty 'MS_Description', N'Оплата', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'paymaccount'
go

exec sp_addextendedproperty 'MS_Description', N'Оплата пени', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'paymaccount_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Признак расчёта пени', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers',
     'COLUMN', 'penalty_calc'
go

exec sp_addextendedproperty 'MS_Description', N'Признак редактирования пени', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers',
     'COLUMN', 'penalty_old_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Пени за прошлые периоды', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers',
     'COLUMN', 'penalty_old'
go

exec sp_addextendedproperty 'MS_Description', N'Пени прошлое с учётом оплаты и изменений', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Suppliers', 'COLUMN', 'penalty_old_new'
go

exec sp_addextendedproperty 'MS_Description', N'Рассчитанное пени', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'penalty_value'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во мес. долга', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'kolMesDolg'
go

exec sp_addextendedproperty 'MS_Description', N'кон. сальдо', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'debt'
go

exec sp_addextendedproperty 'MS_Description', N'Начисление за прошлый период', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Suppliers', 'COLUMN', 'paid_old'
go

exec sp_addextendedproperty 'MS_Description', N'Числовой код договора если есть', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Suppliers', 'COLUMN', 'dog_int'
go

exec sp_addextendedproperty 'MS_Description',
     N'Уникальный идентификатор жилищно-коммунальной услуги, созданный ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Suppliers', 'COLUMN', 'id_jku_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Расчётный счёт', 'SCHEMA', 'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN',
     'rasschet'
go

exec sp_addextendedproperty 'MS_Description', N'старый лицевой счет (из других систем)', 'SCHEMA', 'dbo', 'TABLE',
     'Occ_Suppliers', 'COLUMN', 'schtl_old'
go

exec sp_addextendedproperty 'MS_Description', N'Данные для генерации QR - кода клиенту (например: СБП)', 'SCHEMA',
     'dbo', 'TABLE', 'Occ_Suppliers', 'COLUMN', 'qrData'
go

