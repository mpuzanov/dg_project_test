create table Cessia
(
    occ_sup             int                           not null
        constraint PK_CESSIA
            primary key,
    dolg_mes_start      smallint
        constraint DF_CESSIA_gl_dolg default 0        not null,
    cessia_dolg_mes_new smallint,
    occ                 int                           not null,
    dog_int             int                           not null,
    saldo_start         decimal(9, 2)
        constraint DF_CESSIA_sum_dolg_start default 0 not null,
    debt_current        decimal(9, 2)
        constraint DF_CESSIA_debt_current default 0   not null,
    data_edit           smalldatetime,
    sysuser             varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Данные по цессии', 'SCHEMA', 'dbo', 'TABLE', 'Cessia'
go

