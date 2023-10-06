CREATE   PROCEDURE [dbo].[rep_people]
(
	@tip_id	SMALLINT	= NULL
	,@dom1	INT			= NULL
	,@kv1	VARCHAR(7)	= NULL
)
AS
	/*
	Выдаем список прописаных людей по улице или дому или квартире
	
	exec rep_people 28, 1031
	
	*/
	SET NOCOUNT ON


	IF @tip_id IS NULL
		AND @dom1 IS NULL
		SET @tip_id = 0

	IF @kv1 = ''
		SET @kv1 = NULL

	SELECT
		o.address AS address
		,concat(s.name , ' д.' , b.nom_dom) AS adres_dom
		,s.name AS street_name
		,b.nom_dom
		,o.nom_kvr
		,o.occ
		,o.proptype_id
		,p.Last_name
		,p.First_name
		,p.Second_name
		,p.DateReg
		,fam.name AS fam_id
		,p.Birthdate
		,p.Status2_id
		,ps.name AS status_reg
		,o.total_sq
		,o.living_sq
		,b.id AS build_id
		,p.id
		,i.PersonStatus AS PersonStatus
		,NULL AS lgota_id
	FROM dbo.PEOPLE AS p 
	JOIN dbo.VOCC AS o 
		ON o.occ = p.occ
	JOIN dbo.BUILDINGS b 
		ON o.build_id = b.id
	LEFT JOIN dbo.VSTREETS s
		ON b.street_id = s.id
	LEFT JOIN dbo.FAM_RELATIONS AS fam 
		ON fam.id = p.fam_id
	LEFT JOIN dbo.PERSON_STATUSES AS ps 
		ON p.Status2_id = ps.id
	LEFT JOIN dbo.INTPRINT AS i 
		ON i.fin_id = o.fin_id
		AND i.occ = o.occ
	WHERE (o.tip_id = @tip_id
	OR @tip_id IS NULL)
	AND (b.id = @dom1
	OR @dom1 IS NULL)
	AND (o.nom_kvr = @kv1
	OR @kv1 IS NULL)
	AND o.Status_id <> 'закр'
	AND p.Del = 0
	ORDER BY s.name
	, b.nom_dom_sort
	, o.nom_kvr_sort
	OPTION (RECOMPILE)
go

