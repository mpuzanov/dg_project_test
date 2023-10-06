create table Month
(
    id    smallint    not null
        constraint PK_MONTH
            primary key,
    name  varchar(20) not null collate SQL_Latin1_General_CP1251_CI_AS,
    name2 varchar(20) not null collate SQL_Latin1_General_CP1251_CI_AS,
    name3 varchar(20) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Названия месяцев в разных падежах', 'SCHEMA', 'dbo', 'TABLE', 'Month'
go

