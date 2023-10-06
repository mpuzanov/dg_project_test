create table Counter_type
(
    name varchar(30) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_Counter_type
            primary key
)
go

exec sp_addextendedproperty 'MS_Description', N'Типы (марки) приборов учета', 'SCHEMA', 'dbo', 'TABLE', 'Counter_type'
go

