create index [NonClusteredIndex fin_id]
    on Calendar_period (fin_id) include (start_date, end_date, StrFinPeriod)
go

