create table Calendar_period
(
    fin_id          smallint      not null
        constraint PK_CALENDAR_PERIOD
            primary key,
    start_date      smalldatetime not null,
    end_date        smalldatetime not null,
    StrFinPeriod    varchar(15)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    KolDayFinPeriod smallint      not null,
    StrFinPeriod2   varchar(15)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    dd_MMM_yyyy     varchar(15)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    dd_MMMM_yyyy    varchar(15)   not null collate SQL_Latin1_General_CP1251_CI_AS,
    yyyymmdd        varchar(8)    not null collate SQL_Latin1_General_CP1251_CI_AS,
    q1              smallint      not null,
    y1              smallint      not null,
    m1              smallint      not null,
    month           varchar(15)   not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Календарь с фин. периодами', 'SCHEMA', 'dbo', 'TABLE', 'Calendar_period'
go

