create table Vid_blag
(
    id   smallint     not null
        constraint PK_VID_BLAG
            primary key,
    name varchar(150) not null collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Категории благоустройства жил.фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Vid_blag'
go

