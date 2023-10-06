create table Stavki_agenta
(
    id      int identity
        constraint PK_STAVKI_AGENTA
            primary key,
    dog_int int
        constraint DF_STAVKI_AGENTA_dog_uk_id default 0 not null,
    mes1    smallint                                    not null,
    mes2    smallint                                    not null,
    procent decimal(6, 2)                               not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Ставки вознаграждения по цессии', 'SCHEMA', 'dbo', 'TABLE',
     'Stavki_agenta'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Stavki_agenta', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'код договора', 'SCHEMA', 'dbo', 'TABLE', 'Stavki_agenta', 'COLUMN',
     'dog_int'
go

exec sp_addextendedproperty 'MS_Description', N'процент', 'SCHEMA', 'dbo', 'TABLE', 'Stavki_agenta', 'COLUMN', 'procent'
go

