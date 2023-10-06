create table Dog_build
(
    dog_int  int      not null
        constraint FK_DOG_BUILD_DOG_SUP
            references Dog_sup (id),
    fin_id   smallint not null,
    build_id int      not null
        constraint FK_DOG_BUILD_BUILDINGS
            references Buildings,
    constraint PK_DOG_BUILD
        primary key (dog_int, fin_id, build_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Списки домов по договорам', 'SCHEMA', 'dbo', 'TABLE', 'Dog_build'
go

exec sp_addextendedproperty 'MS_Description', N'код договора', 'SCHEMA', 'dbo', 'TABLE', 'Dog_build', 'COLUMN',
     'dog_int'
go

exec sp_addextendedproperty 'MS_Description', N'Код фин. периода', 'SCHEMA', 'dbo', 'TABLE', 'Dog_build', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код дома по договору', 'SCHEMA', 'dbo', 'TABLE', 'Dog_build', 'COLUMN',
     'build_id'
go

