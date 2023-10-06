create index id
    on Buildings (id) include (street_id, nom_dom, tip_id, fin_current)
go

create index ix2
    on Buildings (sector_id, div_id, town_id, tip_id) include (street_id, nom_dom)
go

create index tip_id
    on Buildings (tip_id) include (street_id, town_id, is_paym_build)
go

