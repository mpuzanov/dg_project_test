create unique index login
    on Users (login)
go

create unique index login2
    on Users (login) include (id, SuperAdmin)
go

