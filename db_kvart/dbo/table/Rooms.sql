create table Rooms
(
    id              int identity
        constraint PK_ROOMS
            primary key,
    flat_id         int not null
        constraint FK_ROOMS_FLATS
            references Flats
            on update cascade on delete cascade,
    name            varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    id_room_gis     varchar(16) collate SQL_Latin1_General_CP1251_CI_AS,
    CadastralNumber varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Комнаты', 'SCHEMA', 'dbo', 'TABLE', 'Rooms'
go

exec sp_addextendedproperty 'MS_Description', N'Код комнаты', 'SCHEMA', 'dbo', 'TABLE', 'Rooms', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код квартиры', 'SCHEMA', 'dbo', 'TABLE', 'Rooms', 'COLUMN', 'flat_id'
go

exec sp_addextendedproperty 'MS_Description', N'№ комнаты', 'SCHEMA', 'dbo', 'TABLE', 'Rooms', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Код комнаты в ГИС ЖКХ', 'SCHEMA', 'dbo', 'TABLE', 'Rooms', 'COLUMN',
     'id_room_gis'
go

exec sp_addextendedproperty 'MS_Description', N'Кадастровый номер комнаты', 'SCHEMA', 'dbo', 'TABLE', 'Rooms', 'COLUMN',
     'CadastralNumber'
go

