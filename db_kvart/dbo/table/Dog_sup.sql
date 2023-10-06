create table Dog_sup
(
    dog_id            varchar(20)                         not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_DOG_SUP
            primary key,
    dog_name          varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    sup_id            int                                 not null
        constraint FK_DOG_SUP_SUPPLIERS_ALL
            references Suppliers_all,
    tip_id            smallint                            not null
        constraint FK_DOG_SUP_OCCUPATION_TYPES
            references Occupation_Types
            on update cascade,
    first_occ         int,
    bank_account      int,
    dog_date          smalldatetime,
    id_accounts       int,
    date_edit         smalldatetime,
    login_edit        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS,
    id                int identity,
    data_start        smalldatetime,
    tip_name_dog      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    is_cessia         bit
        constraint DF_DOG_SUP_is_cessia default 0         not null,
    NumberOfDigits    smallint
        constraint DF_DOG_SUP_NumberOfDigits default 9    not null,
    last_occ          int,
    isfirst_occ_added bit
        constraint DF_Dog_sup_isfirst_occ_added default 0 not null,
    dog_uid           uniqueidentifier
)
go

exec sp_addextendedproperty 'MS_Description', N'Договора между поставщиками и упр.компаниями', 'SCHEMA', 'dbo', 'TABLE',
     'Dog_sup'
go

exec sp_addextendedproperty 'MS_Description', N'Текстовый код договора', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'dog_id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование договора', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'dog_name'
go

exec sp_addextendedproperty 'MS_Description', N'Код поставщика', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN', 'sup_id'
go

exec sp_addextendedproperty 'MS_Description', N'Код управляющей компании', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup',
     'COLUMN', 'tip_id'
go

exec sp_addextendedproperty 'MS_Description', N'Значение первых 3-х цифр лицевого счета', 'SCHEMA', 'dbo', 'TABLE',
     'Dog_sup', 'COLUMN', 'first_occ'
go

exec sp_addextendedproperty 'MS_Description', N'Код банковского счёта', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'bank_account'
go

exec sp_addextendedproperty 'MS_Description', N'Дата договора', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'dog_date'
go

exec sp_addextendedproperty 'MS_Description', N'Код квитанции', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'id_accounts'
go

exec sp_addextendedproperty 'MS_Description', N'дата редактирования', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'логин пользователя кто редактировал', 'SCHEMA', 'dbo', 'TABLE',
     'Dog_sup', 'COLUMN', 'login_edit'
go

exec sp_addextendedproperty 'MS_Description', N'числовой код договора', 'SCHEMA', 'dbo', 'TABLE', 'Dog_sup', 'COLUMN',
     'id'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование управляющей организации по договору', 'SCHEMA', 'dbo',
     'TABLE', 'Dog_sup', 'COLUMN', 'tip_name_dog'
go

exec sp_addextendedproperty 'MS_Description', N'Количество цифр в лицевом счёте поставщика', 'SCHEMA', 'dbo', 'TABLE',
     'Dog_sup', 'COLUMN', 'NumberOfDigits'
go

exec sp_addextendedproperty 'MS_Description', N'Признак присоединения first_occ к ед.лицевому счету', 'SCHEMA', 'dbo',
     'TABLE', 'Dog_sup', 'COLUMN', 'isfirst_occ_added'
go

