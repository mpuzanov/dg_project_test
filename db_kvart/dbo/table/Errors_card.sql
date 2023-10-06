create table Errors_card
(
    id              int identity
        constraint PK_ERRORS_CARD
            primary key,
    data            smalldatetime
        constraint DF_Errors_card_data default getdate() not null,
    user_id         smallint,
    app             varchar(25) collate SQL_Latin1_General_CP1251_CI_AS,
    descriptions    varchar(400) collate SQL_Latin1_General_CP1251_CI_AS,
    host_name       varchar(20) collate SQL_Latin1_General_CP1251_CI_AS,
    OfficeInfo      varchar(200) collate SQL_Latin1_General_CP1251_CI_AS,
    ip              varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    versia          varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    file_error      varbinary(max),
    StackTrace      varchar(4000) collate SQL_Latin1_General_CP1251_CI_AS,
    size_file_error decimal(9, 2)
)
go

exec sp_addextendedproperty 'MS_Description', N'Журнал ошибок пользователей в время работы', 'SCHEMA', 'dbo', 'TABLE',
     'Errors_card'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Errors_card', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'дата ошибки', 'SCHEMA', 'dbo', 'TABLE', 'Errors_card', 'COLUMN', 'data'
go

exec sp_addextendedproperty 'MS_Description', N'код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Errors_card', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'название программы', 'SCHEMA', 'dbo', 'TABLE', 'Errors_card', 'COLUMN',
     'app'
go

exec sp_addextendedproperty 'MS_Description', N'описание ошибки', 'SCHEMA', 'dbo', 'TABLE', 'Errors_card', 'COLUMN',
     'descriptions'
go

exec sp_addextendedproperty 'MS_Description', N'размер картинки с ошибкой  в КБ', 'SCHEMA', 'dbo', 'TABLE',
     'Errors_card', 'COLUMN', 'size_file_error'
go

