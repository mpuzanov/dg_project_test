create table Buildings_comments
(
    fin_id     smallint                                   not null,
    build_id   int                                        not null,
    sup_id     int
        constraint DF_BUILDINGS_COMMENTS_sup_id default 0 not null,
    avto       bit
        constraint DF_BUILDINGS_COMMENTS_auto default 0   not null,
    comments   varchar(4000) collate SQL_Latin1_General_CP1251_CI_AS,
    fin_id_end smallint,
    constraint PK_BUILDINGS_COMMENTS
        primary key (fin_id, build_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Комментарии в квитанции по дому', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings_comments'
go

exec sp_addextendedproperty 'MS_Description', N'код периода', 'SCHEMA', 'dbo', 'TABLE', 'Buildings_comments', 'COLUMN',
     'fin_id'
go

exec sp_addextendedproperty 'MS_Description', N'код дома', 'SCHEMA', 'dbo', 'TABLE', 'Buildings_comments', 'COLUMN',
     'build_id'
go

exec sp_addextendedproperty 'MS_Description', N'Автоматически добавлять в следующий месяц', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings_comments', 'COLUMN', 'avto'
go

exec sp_addextendedproperty 'MS_Description', N'Комментарий', 'SCHEMA', 'dbo', 'TABLE', 'Buildings_comments', 'COLUMN',
     'comments'
go

exec sp_addextendedproperty 'MS_Description', N'Последний месяц комментария по дому', 'SCHEMA', 'dbo', 'TABLE',
     'Buildings_comments', 'COLUMN', 'fin_id_end'
go

