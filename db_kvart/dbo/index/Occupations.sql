create index id_els_gis
    on Occupations (id_els_gis, id_jku_gis) include (flat_id)
go

create index IX_OCCUPATIONS_1
    on Occupations (flat_id) include (status_id, tip_id, Occ, kol_people, prefix, proptype_id, total_sq, fin_id)
go

create index tip_id
    on Occupations (tip_id, status_id) include (Occ, flat_id, kol_people)
go

