create index fin_id
    on Global_values (fin_id) include (start_date, end_date, StrMes)
go

create index closed
    on Global_values (closed)
go

