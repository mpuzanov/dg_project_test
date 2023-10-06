create table Reason_close_pu
(
    id                 smallint                                    not null
        constraint PK_REASON_CLOSE_PU
            primary key,
    name               varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    is_del_current_fin bit
        constraint DF_Reason_close_pu_is_del_current_fin default 1 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Причины архивации приборов учёта', 'SCHEMA', 'dbo', 'TABLE',
     'Reason_close_pu'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reason_close_pu', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reason_close_pu', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Удалять счетчик из текущего периода', 'SCHEMA', 'dbo', 'TABLE',
     'Reason_close_pu', 'COLUMN', 'is_del_current_fin'
go

