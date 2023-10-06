create table Error_log
(
    id             int identity
        constraint PK_ERROR_LOG_1
            primary key,
    ErrorDate      datetime
        constraint DF_ERROR_LOG_ErrorDate default getdate() not null,
    Db_Name        nvarchar(125) collate SQL_Latin1_General_CP1251_CI_AS,
    Login          varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    ErrorProcedure varchar(125) collate SQL_Latin1_General_CP1251_CI_AS,
    Line           int,
    Message        varchar(2048) collate SQL_Latin1_General_CP1251_CI_AS,
    Number         int,
    Severity       int,
    State          int,
    MessageUser    varchar(4000) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Общие ошибки в системе (не по лицевым)', 'SCHEMA', 'dbo', 'TABLE',
     'Error_log'
go

