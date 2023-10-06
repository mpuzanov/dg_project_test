create table Reports
(
    Level1           smallint                          not null,
    Level2           smallint                          not null,
    Name             varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    FileName         varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    Procedures       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    REPORT_BODY      varbinary(max),
    NO_VISIBLE       bit
        constraint DF_REPORTS_NO_VISIBLE default 0     not null,
    ID               int identity,
    ID_PARENT        smallint
        constraint DF_REPORTS_ID_PARENT default 0      not null,
    APP              varchar(15)
        constraint DF_REPORTS_APP default 'DREP'       not null collate SQL_Latin1_General_CP1251_CI_AS,
    SIZE_REPORT_BODY decimal(9, 2),
    date_edit        smalldatetime,
    Personal_access  bit
        constraint DF_REPORTS_Personal_access default 0,
    FileDateEdit     smalldatetime,
    Report_preview   varbinary(max),
    is_account       bit
        constraint DF_REPORTS_is_account default 0     not null,
    pid_tip          smallint,
    is_edit          bit
        constraint DF_REPORTS_is_edit default 0        not null,
    pasport_access   bit
        constraint DF_REPORTS_pasport_access default 0 not null,
    constraint PK_REPORTS
        primary key (Level1, Level2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список отчетов', 'SCHEMA', 'dbo', 'TABLE', 'Reports'
go

exec sp_addextendedproperty 'MS_Description', N'Уровень 1', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'Level1'
go

exec sp_addextendedproperty 'MS_Description', N'Уровень 2', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'Level2'
go

exec sp_addextendedproperty 'MS_Description', N'Название отчета', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'Name'
go

exec sp_addextendedproperty 'MS_Description', N'Название файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN',
     'FileName'
go

exec sp_addextendedproperty 'MS_Description', N'список используемых процедур', 'SCHEMA', 'dbo', 'TABLE', 'Reports',
     'COLUMN', 'Procedures'
go

exec sp_addextendedproperty 'MS_Description', N'сам отчёт', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'убрать из видимости пользователей', 'SCHEMA', 'dbo', 'TABLE', 'Reports',
     'COLUMN', 'NO_VISIBLE'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'ID'
go

exec sp_addextendedproperty 'MS_Description', N'родитель', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN', 'ID_PARENT'
go

exec sp_addextendedproperty 'MS_Description', N'абривиатура приложения, где показан отчёт', 'SCHEMA', 'dbo', 'TABLE',
     'Reports', 'COLUMN', 'APP'
go

exec sp_addextendedproperty 'MS_Description', N'размер отчёта в КБ', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN',
     'SIZE_REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'отчет по паспортному столу', 'SCHEMA', 'dbo', 'TABLE', 'Reports',
     'COLUMN', 'Personal_access'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения файла', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN',
     'FileDateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'картинка превию отчёта', 'SCHEMA', 'dbo', 'TABLE', 'Reports', 'COLUMN',
     'Report_preview'
go

exec sp_addextendedproperty 'MS_Description', N'отчёт используется для массовой печати', 'SCHEMA', 'dbo', 'TABLE',
     'Reports', 'COLUMN', 'is_account'
go

exec sp_addextendedproperty 'MS_Description', N'код ПИД (претензионная-исковая деятельность)', 'SCHEMA', 'dbo', 'TABLE',
     'Reports', 'COLUMN', 'pid_tip'
go

exec sp_addextendedproperty 'MS_Description', N'Отчёт разрешено редактировать', 'SCHEMA', 'dbo', 'TABLE', 'Reports',
     'COLUMN', 'is_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Отчёт по паспортному столу', 'SCHEMA', 'dbo', 'TABLE', 'Reports',
     'COLUMN', 'pasport_access'
go

