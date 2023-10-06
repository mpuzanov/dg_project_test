create table Reports_favorites
(
    id          int identity
        constraint PK_REPORTS_FAVORITES
            primary key,
    id_parent   int
        constraint DF_REPORTS_FAVORITES_id_parent default 0         not null,
    user_id     smallint                                            not null,
    rep_id      int,
    name        varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    REPORT_BODY varbinary(max),
    rep_type    varchar(10)
        constraint DF_Reports_favorites_rep_type default 'REPORTS'  not null collate SQL_Latin1_General_CP1251_CI_AS,
    sql_query   varchar(8000) collate SQL_Latin1_General_CP1251_CI_AS,
    date_edit   smalldatetime
        constraint DF_Reports_favorites_date_edit default getdate() not null,
    is_for_all  bit default 0,
    size_body   decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Список избранных отчётов по пользователям (АРМ Отчёты)', 'SCHEMA',
     'dbo', 'TABLE', 'Reports_favorites'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Reports_favorites',
     'COLUMN', 'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код отчёта', 'SCHEMA', 'dbo', 'TABLE', 'Reports_favorites', 'COLUMN',
     'rep_id'
go

exec sp_addextendedproperty 'MS_Description', N'наименование', 'SCHEMA', 'dbo', 'TABLE', 'Reports_favorites', 'COLUMN',
     'name'
go

exec sp_addextendedproperty 'MS_Description', N'Внешний персональный отчёт', 'SCHEMA', 'dbo', 'TABLE',
     'Reports_favorites', 'COLUMN', 'REPORT_BODY'
go

exec sp_addextendedproperty 'MS_Description', N'REPORTS или OLAP', 'SCHEMA', 'dbo', 'TABLE', 'Reports_favorites',
     'COLUMN', 'rep_type'
go

exec sp_addextendedproperty 'MS_Description', N'размер отчета', 'SCHEMA', 'dbo', 'TABLE', 'Reports_favorites', 'COLUMN',
     'size_body'
go

