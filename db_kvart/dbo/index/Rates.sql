create index IX_RATES
    on Rates (finperiod, tipe_id, service_id, mode_id, source_id, status_id,
              proptype_id) include (value, full_value, extr_value)
go

