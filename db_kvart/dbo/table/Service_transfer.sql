create table Service_transfer
(
    service_id varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_Service_transfer
            primary key
        constraint FK_Service_transfer_Services
            references Services
            on update cascade on delete cascade,
    serv_komp  varchar(10) not null collate SQL_Latin1_General_CP1251_CI_AS,
    name       varchar(100) collate SQL_Latin1_General_CP1251_CI_AS
)
go

