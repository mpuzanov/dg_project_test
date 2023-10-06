create table People_TmpOut
(
    id          int identity
        constraint PK_PEOPLE_TmpOut
            primary key,
    occ         int                                       not null,
    owner_id    int                                       not null,
    data1       smalldatetime                             not null,
    data2       smalldatetime                             not null,
    doc         varchar(100)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    sysuser     varchar(30)                               not null collate SQL_Latin1_General_CP1251_CI_AS,
    data_edit   smalldatetime                             not null,
    fin_id      smallint,
    is_noliving bit
        constraint DF_People_TmpOut_is_noliving default 1 not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Учёт временного отсутствия граждан', 'SCHEMA', 'dbo', 'TABLE',
     'People_TmpOut'
go

exec sp_addextendedproperty 'MS_Description', N'Лицевой', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'Код гражданина', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut', 'COLUMN',
     'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Дата начала отсутствия', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut',
     'COLUMN', 'data1'
go

exec sp_addextendedproperty 'MS_Description', N'Дата окончания отсутствия', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut',
     'COLUMN', 'data2'
go

exec sp_addextendedproperty 'MS_Description', N'Документ подтверждающий отсутствие', 'SCHEMA', 'dbo', 'TABLE',
     'People_TmpOut', 'COLUMN', 'doc'
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut', 'COLUMN',
     'sysuser'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut', 'COLUMN',
     'data_edit'
go

exec sp_addextendedproperty 'MS_Description', N'в какой период завели', 'SCHEMA', 'dbo', 'TABLE', 'People_TmpOut',
     'COLUMN', 'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'1 -  временное отсутвие, 0 - присутствие', 'SCHEMA', 'dbo', 'TABLE',
     'People_TmpOut', 'COLUMN', 'is_noliving'
go

