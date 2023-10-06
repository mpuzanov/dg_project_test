create table Buildings_history
(
    fin_id             smallint                                      not null,
    bldn_id            int                                           not null,
    street_id          int                                           not null
        constraint FK_BUILDINGS_HISTORY_STREETS
            references Streets,
    sector_id          smallint,
    div_id             smallint                                      not null,
    tip_id             smallint                                      not null,
    nom_dom            varchar(7)                                    not null collate SQL_Latin1_General_CP1251_CI_AS,
    old                bit                                           not null,
    standart_id        int,
    dog_bit            bit
        constraint DF_BUILDINGS_HISTORY_dog_bit default 0            not null,
    penalty_calc_build bit
        constraint DF_BUILDINGS_HISTORY_Penalty_calc_build default 1 not null,
    arenda_sq          decimal(10, 4),
    dog_num            varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    dog_date           smalldatetime,
    is_paym_build      bit
        constraint DF_BUILDINGS_HISTORY_is_paym_build default 1,
    dog_date_sobr      smalldatetime,
    dog_date_protocol  smalldatetime,
    dog_num_protocol   varchar(10) collate SQL_Latin1_General_CP1251_CI_AS,
    opu_sq             decimal(10, 4),
    opu_sq_elek        decimal(10, 4),
    build_total_sq     decimal(10, 4),
    norma_gkal         decimal(9, 6),
    build_type         smallint,
    norma_gkal_gvs     decimal(9, 6),
    norma_gaz_gvs      decimal(9, 6),
    norma_gaz_otop     decimal(9, 6),
    opu_sq_otop        decimal(10, 4),
    build_total_area   decimal(10, 4),
    account_rich       varchar(max) collate SQL_Latin1_General_CP1251_CI_AS,
    constraint PK_BUILDINGS_HISTORY
        primary key (fin_id, bldn_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'История домов', 'SCHEMA', 'dbo', 'TABLE', 'Buildings_history'
go

