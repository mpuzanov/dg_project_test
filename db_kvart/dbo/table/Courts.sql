create table Courts
(
    id         smallint identity
        constraint PK_COURTS
            primary key,
    name       varchar(100) not null collate SQL_Latin1_General_CP1251_CI_AS,
    owner_id   smallint,
    div_id     smallint,
    Number_uch smallint
)
go

exec sp_addextendedproperty 'MS_Description', N'Суды и судебные участки', 'SCHEMA', 'dbo', 'TABLE', 'Courts'
go

exec sp_addextendedproperty 'MS_Description', N'Код суда', 'SCHEMA', 'dbo', 'TABLE', 'Courts', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование', 'SCHEMA', 'dbo', 'TABLE', 'Courts', 'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'владелец (для группировки)', 'SCHEMA', 'dbo', 'TABLE', 'Courts',
     'COLUMN', 'owner_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код района', 'SCHEMA', 'dbo', 'TABLE', 'Courts', 'COLUMN', 'div_id'
go

exec sp_addextendedproperty 'MS_Description', N'Номер участка', 'SCHEMA', 'dbo', 'TABLE', 'Courts', 'COLUMN',
     'Number_uch'
go

