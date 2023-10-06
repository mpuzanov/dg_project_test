create index flats_id_etc
    on Flats (id) include (bldn_id, nom_kvr, nom_kvr_sort)
go

create index bldn_id
    on Flats (bldn_id) include (id, nom_kvr, nom_kvr_sort)
go

