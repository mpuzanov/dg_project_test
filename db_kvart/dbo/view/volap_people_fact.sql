/* VOLAP_PEOPLE_FACT */
CREATE   VIEW [dbo].[volap_people_fact]
AS
SELECT
	ph.occ
	,ph.fin_id
	,ph.owner_id
	,ph.lgota_id
	,ph.status_id
	,ph.status2_id
	,p.birthdate
	,bh.bldn_id
	,bh.street_id
	,bh.sector_id
	,bh.div_id
	,bh.tip_id
	,p.Last_name
	,p.First_name
	,p.sex
	,p.Military
	,p.Criminal
	,p.Citizen
	,p.Nationality
	,oh.roomtype_id
	,oh.proptype_id
	,oh.status_id AS status_occ
	,oh.total_sq
	,oh.living_sq
	,ps.is_paym
FROM People_history ph
INNER JOIN Occ_history oh
	ON ph.fin_id = oh.fin_id
	AND ph.occ = oh.occ
INNER JOIN Buildings_history bh
	ON ph.fin_id = bh.fin_id
INNER JOIN Flats
	ON oh.flat_id = FLATS.id
	AND bh.bldn_id = FLATS.bldn_id
INNER JOIN People AS p
	ON ph.owner_id = p.id
INNER JOIN Person_statuses AS ps
	ON ph.status2_id = ps.id
WHERE (ps.is_paym = 1)
go

