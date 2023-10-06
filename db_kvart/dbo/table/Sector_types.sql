create table Sector_types
(
    tip_id    smallint not null
        constraint FK_Sector_types_Occupation_Types
            references Occupation_Types
            on update cascade on delete cascade,
    sector_id smallint not null,
    constraint PK_SECTOR_TYPES
        primary key (tip_id, sector_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Участки по типам фонда', 'SCHEMA', 'dbo', 'TABLE', 'Sector_types'
go

exec sp_addextendedproperty 'MS_Description', N'код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Sector_types', 'COLUMN',
     'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'код участка', 'SCHEMA', 'dbo', 'TABLE', 'Sector_types', 'COLUMN',
     'sector_id'
go

