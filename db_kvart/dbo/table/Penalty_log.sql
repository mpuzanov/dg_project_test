create table Penalty_log
(
    id       int identity
        constraint PK_PENALTY_LOG
            primary key,
    occ      int      not null,
    fin_id   smallint not null,
    user_id  smallint,
    data     smalldatetime,
    sum_old  decimal(9, 2),
    sum_new  decimal(9, 2),
    comments varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Ручное изменение пени', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'код фин.периода', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя изменяющего пени', 'SCHEMA', 'dbo', 'TABLE',
     'Penalty_log', 'COLUMN', 'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN',
     'data'
go

exec sp_addextendedproperty 'MS_Description', N'старая сумма пени', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN',
     'sum_old'
go

exec sp_addextendedproperty 'MS_Description', N'новая сумма пени', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN',
     'sum_new'
go

exec sp_addextendedproperty 'MS_Description', N'коментарий', 'SCHEMA', 'dbo', 'TABLE', 'Penalty_log', 'COLUMN',
     'comments'
go

