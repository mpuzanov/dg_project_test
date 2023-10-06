create unique index IX_RATES_COUNTER
    on Rates_counter (fin_id, tipe_id, service_id, unit_id, source_id, mode_id) include (tarif)
go

