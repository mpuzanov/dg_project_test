create table Dom_svod_all
(
    fin_id          smallint                            not null,
    build_id        int                                 not null,
    mode_id         int                                 not null,
    source_id       int                                 not null,
    is_counter      smallint
        constraint DF_DOM_SVOD_ALL_is_counter default 0 not null,
    countlic        int                                 not null,
    countflats      int                                 not null,
    square          decimal(15, 2)                      not null,
    squarelive      decimal(15, 2)                      not null,
    currentdate     smalldatetime                       not null,
    countpeople     int                                 not null,
    countpeoplelgot int                                 not null,
    countliclgot    int                                 not null,
    countlicsubsid  int                                 not null,
    countpeople_no  int,
    constraint PK_DOM_SVOD_ALL
        primary key (fin_id, build_id, mode_id, source_id, is_counter)
)
go

exec sp_addextendedproperty 'MS_Description', N'Свод по дому по режимам и поставщикам', 'SCHEMA', 'dbo', 'TABLE',
     'Dom_svod_all'
go

