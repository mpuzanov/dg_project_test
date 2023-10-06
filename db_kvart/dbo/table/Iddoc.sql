create table Iddoc
(
    id         int identity
        constraint PK_IDDOC
            primary key,
    owner_id   int                           not null
        constraint FK_IDDOC_PEOPLE
            references People
            on update cascade on delete cascade,
    active     bit
        constraint DF_IDDOC_active default 1 not null,
    DOCTYPE_ID varchar(10)                   not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_IDDOC_IDDOC_TYPES
            references Iddoc_types
            on update cascade,
    DOC_NO     varchar(12)                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    PASSSER_NO varchar(12)                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    ISSUED     smalldatetime                 not null,
    DOCORG     varchar(100)                  not null collate SQL_Latin1_General_CP1251_CI_AS,
    user_edit  smallint,
    date_edit  smalldatetime,
    kod_pvs    varchar(7) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Документы(паспорта) у людей', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc'
go

exec sp_addextendedproperty 'MS_Description', N'Код', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Код человека', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Активный на данный момент', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN',
     'active'
go

exec sp_addextendedproperty 'MS_Description', N'код документа', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN',
     'DOCTYPE_ID'
go

exec sp_addextendedproperty 'MS_Description', N'номер', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'DOC_NO'
go

exec sp_addextendedproperty 'MS_Description', N'серия', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'PASSSER_NO'
go

exec sp_addextendedproperty 'MS_Description', N'дата выдачи', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'ISSUED'
go

exec sp_addextendedproperty 'MS_Description', N'кем выдан', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN', 'DOCORG'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя кто изменял', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc',
     'COLUMN', 'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Iddoc', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Код подразделения выдавшего документ', 'SCHEMA', 'dbo', 'TABLE',
     'Iddoc', 'COLUMN', 'kod_pvs'
go

