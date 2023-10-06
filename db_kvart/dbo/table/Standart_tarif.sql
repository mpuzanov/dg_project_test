create table Standart_tarif
(
    standart_id int           not null
        constraint FK_STANDART_TARIF_STANDART
            references Standart
            on update cascade on delete cascade,
    Kol_people  smallint      not null,
    tarif       decimal(9, 2) not null,
    constraint PK_STANDART_TARIF
        primary key (standart_id, Kol_people)
)
go

exec sp_addextendedproperty 'MS_Description', N'Тарифы по стандартам жилья', 'SCHEMA', 'dbo', 'TABLE', 'Standart_tarif'
go

exec sp_addextendedproperty 'MS_Description', N'код стандарта', 'SCHEMA', 'dbo', 'TABLE', 'Standart_tarif', 'COLUMN',
     'standart_id'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во граждан', 'SCHEMA', 'dbo', 'TABLE', 'Standart_tarif', 'COLUMN',
     'Kol_people'
go

exec sp_addextendedproperty 'MS_Description', N'тариф', 'SCHEMA', 'dbo', 'TABLE', 'Standart_tarif', 'COLUMN', 'tarif'
go

