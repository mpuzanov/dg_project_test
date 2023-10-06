create table Barcode_type
(
    id              smallint                                 not null
        constraint PK_BARCODE_TYPE
            primary key,
    name            varchar(50)                              not null collate SQL_Latin1_General_CP1251_CI_AS,
    len_occ         smallint
        constraint DF_BARCODE_TYPE_len_occ default 9         not null,
    is_period_print bit
        constraint DF_BARCODE_TYPE_is_period_print default 0 not null,
    len_mes         smallint
        constraint DF_BARCODE_TYPE_len_mes default 2         not null
        constraint CK_BARCODE_TYPE
            check ([len_mes] = 2 OR [len_mes] = 0),
    len_god         smallint
        constraint DF_BARCODE_TYPE_len_god default 1         not null
        constraint CK_BARCODE_TYPE_1
            check ([len_god] >= 0 AND [len_god] <= 4),
    len_sum         smallint
        constraint DF_BARCODE_TYPE_len_sum default 8         not null,
    len_inn         smallint
        constraint DF_BARCODE_TYPE_len_inn default 0         not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Описание используемых штрих-кодов', 'SCHEMA', 'dbo', 'TABLE',
     'Barcode_type'
go

