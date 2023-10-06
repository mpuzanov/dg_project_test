create table Bankdbf_comments
(
    id       int not null
        constraint PK_BANKDBF_COMMENTS
            primary key
        constraint FK_BANKDBF_COMMENTS_BANK_DBF
            references Bank_Dbf
            on delete cascade,
    comments varchar(50) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Комментарии к платежам', 'SCHEMA', 'dbo', 'TABLE', 'Bankdbf_comments'
go

