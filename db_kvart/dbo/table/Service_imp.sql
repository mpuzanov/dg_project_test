create table Service_imp
(
    name varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_Service_imp
            primary key,
    id   varchar(10)  not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_Service_imp_Services
            references Services
            on update cascade
)
go

exec sp_addextendedproperty 'MS_Description', N'Таблица для стыковки услуг с внешними файлами', 'SCHEMA', 'dbo',
     'TABLE', 'Service_imp'
go

