create table Program_access
(
    user_id    smallint not null
        constraint FK_PROGRAM_ACCESS_PROGRAM_ACCESS
            references Users
            on update cascade on delete cascade,
    program_id int      not null
        constraint FK_PROGRAM_ACCESS_PROGRAMS
            references Programs
            on update cascade,
    constraint PK_PROGRAM_ACCESS_1
        primary key (user_id, program_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Доступ к программым для пользователей', 'SCHEMA', 'dbo', 'TABLE',
     'Program_access'
go

exec sp_addextendedproperty 'MS_Description', N'Код пользователя', 'SCHEMA', 'dbo', 'TABLE', 'Program_access', 'COLUMN',
     'user_id'
go

exec sp_addextendedproperty 'MS_Description', N'код программы', 'SCHEMA', 'dbo', 'TABLE', 'Program_access', 'COLUMN',
     'program_id'
go

