create table Pid
(
    id          int identity
        constraint PK_Pid
            primary key,
    occ         int                       not null,
    data_create smalldatetime             not null,
    pid_tip     smallint                  not null,
    sup_id      int                       not null,
    data_end    smalldatetime,
    Summa       decimal(9, 2)
        constraint DF_PID_Summa default 0 not null,
    fin_id      smallint                  not null,
    occ_sup     int,
    dog_int     int,
    kol_mes     smallint,
    date_edit   smalldatetime,
    user_edit   varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    owner_id    int,
    is_peny     bit,
    SumPeny     decimal(9, 2),
    PenyPeriod1 smalldatetime,
    PenyPeriod2 smalldatetime,
    GosTax      decimal(9, 2),
    SumDolg     decimal(9, 2),
    DolgPeriod1 smalldatetime,
    DolgPeriod2 smalldatetime,
    court_id    smallint,
    doc_no      varchar(10) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Претензионно-исковые документы', 'SCHEMA', 'dbo', 'TABLE', 'Pid'
go

exec sp_addextendedproperty 'MS_Description', N'Код документа', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой счёт', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Дата создания', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'data_create'
go

exec sp_addextendedproperty 'MS_Description', N'Код типа документа', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'pid_tip'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Дата окончания', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'data_end'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма по документу', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'Summa'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой счёт по поставщику', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'occ_sup'
go

exec sp_addextendedproperty 'MS_Description', N'Код договора', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'dog_int'
go

exec sp_addextendedproperty 'MS_Description', N'Кол-во месяцев', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'kol_mes'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Код гражданина', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Включать сумму пени в документ', 'SCHEMA', 'dbo', 'TABLE', 'Pid',
     'COLUMN', 'is_peny'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма пени', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'SumPeny'
go

exec sp_addextendedproperty 'MS_Description', N'Период пени от', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'PenyPeriod1'
go

exec sp_addextendedproperty 'MS_Description', N'Период пени по', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'PenyPeriod2'
go

exec sp_addextendedproperty 'MS_Description', N'Госпошлина', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN', 'GosTax'
go

exec sp_addextendedproperty 'MS_Description', N'Сумма задолженности', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'SumDolg'
go

exec sp_addextendedproperty 'MS_Description', N'Период задолженности с', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'DolgPeriod1'
go

exec sp_addextendedproperty 'MS_Description', N'Период задолженности по', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'DolgPeriod2'
go

exec sp_addextendedproperty 'MS_Description', N'Код судебного участка', 'SCHEMA', 'dbo', 'TABLE', 'Pid', 'COLUMN',
     'court_id'
go

