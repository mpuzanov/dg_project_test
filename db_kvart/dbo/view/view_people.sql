-- dbo.view_people source

CREATE   VIEW [dbo].[view_people]
AS
SELECT
	p.Occ
	,p.id AS owner_id
	,p.last_name
	,p.first_name
	,p.second_name
	,p.id
	,birthdate
	,p.status2_id
	,p.STATUS_ID
	,p.lgota_id
	,p.sex
	,ps.name AS person_status
	,id.DOCTYPE_ID
	,id.doc_no
	,id.PASSSER_NO
	,id.issued
	,id.DOCORG
	,id.kod_pvs
	,CONCAT(RTRIM(p.Last_name),' ',LEFT(p.First_name,1),'. ',LEFT(p.Second_name,1),'.') AS Initials
	,CONCAT(RTRIM(Last_name), ' ', RTRIM(First_name), ' ', RTRIM(Second_name)) AS FIO
	,p.fam_id
	,fr.name AS fam_name
	,P.DateReg
	,P.DateEnd
	,p.people_uid
	,p.Dola_priv1
	,p.Dola_priv2
	,p.is_owner_flat
    ,ps.is_kolpeople
    ,ps.is_registration	
FROM dbo.PEOPLE AS p 
JOIN dbo.PERSON_STATUSES ps
	ON p.status2_id = ps.id
LEFT JOIN dbo.IDDOC id 
	ON p.id = id.owner_id
	AND id.active = 1
LEFT JOIN dbo.FAM_RELATIONS AS fr
	ON p.fam_id=fr.id
WHERE p.Del = CAST(0 AS BIT);
go

