create table Calendar
(
    data1         datetime not null
        constraint PK_CALENDAR
            primary key,
    y1            int,
    m1            int,
    d1            int,
    month_name    nvarchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    q1            nvarchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    dayofyear1    nvarchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    week1         nvarchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    weekday_name1 nvarchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    weekday1      int,
    month_year    nvarchar(61) collate SQL_Latin1_General_CP1251_CI_AS,
    data_full     nvarchar(82) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Календарь по дням', 'SCHEMA', 'dbo', 'TABLE', 'Calendar'
go

