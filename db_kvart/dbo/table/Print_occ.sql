create table Print_occ
(
    occ       int                                           not null,
    group_id  smallint                                      not null
        constraint FK_PRINT_OCC_Print_Group
            references Print_group,
    sum1      decimal(9, 2),
    date_edit date
        constraint DF_Print_occ_date_edit default getdate() not null,
    constraint PK_PRINT_OCC
        primary key (occ, group_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Лицевые счета для печати квитанций по группам', 'SCHEMA', 'dbo',
     'TABLE', 'Print_occ'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой счёт', 'SCHEMA', 'dbo', 'TABLE', 'Print_occ', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код группы', 'SCHEMA', 'dbo', 'TABLE', 'Print_occ', 'COLUMN', 'group_id'
go

exec sp_addextendedproperty 'MS_Description', N'Какая либо сумма для служебных целей в зависимости от ситуации',
     'SCHEMA', 'dbo', 'TABLE', 'Print_occ', 'COLUMN', 'sum1'
go

