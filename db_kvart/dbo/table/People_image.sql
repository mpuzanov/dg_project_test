create table People_image
(
    owner_id   int              not null
        constraint PK_People_image
            primary key
        constraint People_image_People_people_uid_fk
            references People
            on update cascade on delete cascade,
    foto       varbinary(max),
    people_uid uniqueidentifier not null
)
go

exec sp_addextendedproperty 'MS_Description', N'Фотографии людей', 'SCHEMA', 'dbo', 'TABLE', 'People_image'
go

exec sp_addextendedproperty 'MS_Description', N'фотография', 'SCHEMA', 'dbo', 'TABLE', 'People_image', 'COLUMN', 'foto'
go

exec sp_addextendedproperty 'MS_Description', N'идентификатор гражданина', 'SCHEMA', 'dbo', 'TABLE', 'People_image',
     'COLUMN', 'people_uid'
go

