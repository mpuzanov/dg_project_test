create table Build_sup_out
(
    build_id int not null,
    sup_id   int not null,
    constraint PK_BUILD_SUP_OUT
        primary key (build_id, sup_id)
)
go

exec sp_addextendedproperty 'MS_Description', N'Дома с расчётами по поставщику с отдельной квитанцией', 'SCHEMA', 'dbo',
     'TABLE', 'Build_sup_out'
go

