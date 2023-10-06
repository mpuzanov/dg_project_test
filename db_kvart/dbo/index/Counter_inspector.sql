create index fin_id_counter_id
    on Counter_inspector (counter_id, fin_id) include (inspector_value, inspector_date, tip_value, kol_day, actual_value)
go

