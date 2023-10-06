create table People
(
    id              int                                not null
        constraint PK_PEOPLE
            primary key,
    occ             int                                not null,
    Del             bit
        constraint DF_PEOPLE_Del default 0             not null,
    Last_name       varchar(50)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    First_name      varchar(30)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    Second_name     varchar(30)                        not null collate SQL_Latin1_General_CP1251_CI_AS,
    Lgota_id        smallint
        constraint DF_PEOPLE_Lgota_id default 0        not null
        constraint FK__people__Lgota_id__263D255D
            references Dsc_groups
            on update cascade,
    Status_id       smallint
        constraint DF_PEOPLE_Status_id default 0       not null
        constraint FK_PEOPLE_STATUS
            references Status,
    Status2_id      varchar(10)
        constraint DF_PEOPLE_Status2_id default 'пост' not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_PEOPLE_PERSON_STATUSES
            references Person_statuses,
    Fam_id          char(4)                            not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint FK_PEOPLE_FAM_RELATIONS
            references Fam_relations,
    Doxod           decimal(9, 2),
    KolMesDoxoda    smallint,
    dop_norma       smallint,
    Reason_extract  smallint,
    Birthdate       smalldatetime,
    DateReg         smalldatetime,
    DateDel         smalldatetime,
    DateEnd         smalldatetime,
    DateDeath       smalldatetime,
    sex             smallint
        constraint CK_PEOPLE_SEX
            check ([sex] IS NULL OR [sex] = 0 OR [sex] = 1 OR [sex] = 2),
    Military        smallint
        constraint CK_PEOPLE_Military
            check ([Military] >= 0 AND [Military] <= 2),
    Criminal        smallint
        constraint CK_PEOPLE_Criminal
            check ([Criminal] IS NULL OR ([Criminal] = 1 OR [Criminal] = 0)),
    Comments        varchar(80) collate SQL_Latin1_General_CP1251_CI_AS,
    Dola_priv       varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    kol_day_add     smallint,
    kol_day_lgota   smallint,
    lgota_kod       int,
    Citizen         smallint,
    OwnerParent     int,
    Nationality     varchar(15) collate SQL_Latin1_General_CP1251_CI_AS,
    Dola_priv1      smallint,
    Dola_priv2      smallint,
    dateoznac       smalldatetime,
    datesoglacie    smalldatetime,
    DateRegBegin    smalldatetime,
    doc_privat      varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    AutoDelPeople   smallint,
    DateBeginPrivat smalldatetime,
    DateEndPrivat   smalldatetime,
    Contact_info    varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    DateEdit        smalldatetime,
    snils           varchar(11) collate SQL_Latin1_General_CP1251_CI_AS,
    date_create     smalldatetime,
    new             bit
        constraint DF_PEOPLE_new default 1,
    inn             varchar(12) collate SQL_Latin1_General_CP1251_CI_AS
        constraint CK_PEOPLE_inn
            check ([inn] IS NULL OR
                   patindex('[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]', [inn]) > 0 OR
                   patindex('[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]', [inn]) > 0),
    people_uid      uniqueidentifier,
    email           varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    user_edit       smallint,
    is_owner_flat   bit,
    constraint CK_PEOPLE_Birthdate
        check ([Birthdate] <= [DateReg])
)
go

exec sp_addextendedproperty 'MS_Description', N'Информация по людям', 'SCHEMA', 'dbo', 'TABLE', 'People'
go

exec sp_addextendedproperty 'MS_Description', N'код человека', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'id'
go

exec sp_addextendedproperty 'MS_Description', N'лицевой', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'occ'
go

exec sp_addextendedproperty 'MS_Description', N'признак выписки', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Del'
go

exec sp_addextendedproperty 'MS_Description', N'Фамилия', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Last_name'
go

exec sp_addextendedproperty 'MS_Description', N'Имя', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'First_name'
go

exec sp_addextendedproperty 'MS_Description', N'Отчество', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Second_name'
go

exec sp_addextendedproperty 'MS_Description', N'номер льготы', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Lgota_id'
go

exec sp_addextendedproperty 'MS_Description', N'социальный статус', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Status_id'
go

exec sp_addextendedproperty 'MS_Description', N'статус прописки', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Status2_id'
go

exec sp_addextendedproperty 'MS_Description', N'родственные отношения', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Fam_id'
go

exec sp_addextendedproperty 'MS_Description', N'доход за 3 мес', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Doxod'
go

exec sp_addextendedproperty 'MS_Description', N'кол-во мес.дохода (устаревщее для субсидий)', 'SCHEMA', 'dbo', 'TABLE',
     'People', 'COLUMN', 'KolMesDoxoda'
go

exec sp_addextendedproperty 'MS_Description', N'доп. норма', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'dop_norma'
go

exec sp_addextendedproperty 'MS_Description', N'причина выписки', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Reason_extract'
go

exec sp_addextendedproperty 'MS_Description', N'дата рождения', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Birthdate'
go

exec sp_addextendedproperty 'MS_Description', N'дата регистрации', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'DateReg'
go

exec sp_addextendedproperty 'MS_Description', N'дата выписки', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'DateDel'
go

exec sp_addextendedproperty 'MS_Description', N'дата окончания действия статуса прописки', 'SCHEMA', 'dbo', 'TABLE',
     'People', 'COLUMN', 'DateEnd'
go

exec sp_addextendedproperty 'MS_Description', N'дата смерти', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'DateDeath'
go

exec sp_addextendedproperty 'MS_Description', N'пол', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'sex'
go

exec sp_addextendedproperty 'MS_Description', N'военнообязанность', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Military'
go

exec sp_addextendedproperty 'MS_Description', N'судимость', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Criminal'
go

exec sp_addextendedproperty 'MS_Description', N'коментарий', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'Comments'
go

exec sp_addextendedproperty 'MS_Description', N'доля приватизации', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Dola_priv'
go

exec sp_addextendedproperty 'MS_Description', N'кол. дней проживания для разовых', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'kol_day_add'
go

exec sp_addextendedproperty 'MS_Description', N'кол. дней льготы для разовых', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'kol_day_lgota'
go

exec sp_addextendedproperty 'MS_Description', N'код льготы', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'lgota_kod'
go

exec sp_addextendedproperty 'MS_Description', N'код гражданства', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Citizen'
go

exec sp_addextendedproperty 'MS_Description', N'Код родителя', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'OwnerParent'
go

exec sp_addextendedproperty 'MS_Description', N'Национальность', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Nationality'
go

exec sp_addextendedproperty 'MS_Description', N'числитель собственности', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Dola_priv1'
go

exec sp_addextendedproperty 'MS_Description', N'знаменатель собственности', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'Dola_priv2'
go

exec sp_addextendedproperty 'MS_Description', N'Дата ознакомления', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'dateoznac'
go

exec sp_addextendedproperty 'MS_Description', N'Дата согласования', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'datesoglacie'
go

exec sp_addextendedproperty 'MS_Description', N'Регистрация с заданной даты', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'DateRegBegin'
go

exec sp_addextendedproperty 'MS_Description', N'Документ основание собственности', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'doc_privat'
go

exec sp_addextendedproperty 'MS_Description', N'Действие по окончании даты регистрации', 'SCHEMA', 'dbo', 'TABLE',
     'People', 'COLUMN', 'AutoDelPeople'
go

exec sp_addextendedproperty 'MS_Description', N'Дата начала права собственности', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'DateBeginPrivat'
go

exec sp_addextendedproperty 'MS_Description', N'Дата окончания права собственности', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'DateEndPrivat'
go

exec sp_addextendedproperty 'MS_Description', N'Контактная информация', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'Contact_info'
go

exec sp_addextendedproperty 'MS_Description', N'дата изменения записи', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'DateEdit'
go

exec sp_addextendedproperty 'MS_Description', N'СНИЛС', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'snils'
go

exec sp_addextendedproperty 'MS_Description', N'дата добавления гражданина', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'date_create'
go

exec sp_addextendedproperty 'MS_Description', N'служебный признак новой записи', 'SCHEMA', 'dbo', 'TABLE', 'People',
     'COLUMN', 'new'
go

exec sp_addextendedproperty 'MS_Description', N'ИНН', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'inn'
go

exec sp_addextendedproperty 'MS_Description', 'email', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN', 'email'
go

exec sp_addextendedproperty 'MS_Description', N'Последний редактиравший пользователь', 'SCHEMA', 'dbo', 'TABLE',
     'People', 'COLUMN', 'user_edit'
go

exec sp_addextendedproperty 'MS_Description', N'собственник помещения', 'SCHEMA', 'dbo', 'TABLE', 'People', 'COLUMN',
     'is_owner_flat'
go

