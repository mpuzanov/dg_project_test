create table Users_occ_types
(
    SYSUSER      nvarchar(30)                                not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_USERS_OCC_TYPES_OCCUPATION_TYPES
            references Users (login)
            on update cascade on delete cascade,
    ONLY_TIP_ID  smallint                                    not null
        constraint FK_Users_occ_types_Occupation_Types1
            references Occupation_Types
            on delete cascade,
    only_read    bit
        constraint DF_USERS_OCC_TYPES_read_only default 0    not null,
    fin_id_start smallint
        constraint DF_USERS_OCC_TYPES_fin_id_start default 0 not null,
    constraint PK_USERS_OCC_TYPES_1
        primary key (SYSUSER, ONLY_TIP_ID)
)
go

exec sp_addextendedproperty 'MS_Description', N'Доступ пользователей по типам фонда', 'SCHEMA', 'dbo', 'TABLE',
     'Users_occ_types'
go

exec sp_addextendedproperty 'MS_Description', N'Логин пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Users_occ_types',
     'COLUMN', 'SYSUSER'
go

exec sp_addextendedproperty 'MS_Description', N'Код типа фонда', 'SCHEMA', 'dbo', 'TABLE', 'Users_occ_types', 'COLUMN',
     'ONLY_TIP_ID'
go

exec sp_addextendedproperty 'MS_Description', N'Разрешено только чтение', 'SCHEMA', 'dbo', 'TABLE', 'Users_occ_types',
     'COLUMN', 'only_read'
go

exec sp_addextendedproperty 'MS_Description', N'Минимально разрешённый фин.период (код)', 'SCHEMA', 'dbo', 'TABLE',
     'Users_occ_types', 'COLUMN', 'fin_id_start'
go

