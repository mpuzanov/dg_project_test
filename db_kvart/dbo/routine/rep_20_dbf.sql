CREATE   PROCEDURE [dbo].[rep_20_dbf]
(
	@fin_id1	SMALLINT
	,@laws_id1	SMALLINT	= NULL
	,   -- код закона
	@div_id1	SMALLINT	= NULL
	, -- код района
	@tip_id1	SMALLINT	= NULL -- тип жил.фонда
)
AS
	--
	--  Список льготников для файла DBF    за 2003 год
	--
	SET NOCOUNT ON

	DECLARE	@start_date1	SMALLDATETIME
			,@end_date1		SMALLDATETIME

	SELECT
		@fin_id1 = fin_id
		,@start_date1 = start_date
		,@end_date1 = end_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_id1

	SELECT
		p.last_name
		,p.first_name
		,p.second_name
		,dr.occ
		,p.birthdate
		,SUBSTRING(s.name, 1, 30) AS 'STREETS'
		,b.nom_dom
		,f.nom_kvr
		,SUBSTRING(dr.doc, 1, 30) AS 'DOC'
		,dr.issued
		,dr.issued2
		,dbo.Fun_GetLastDayMonth(dr.expire_date) AS 'EXPIRE_DATE'
		,dr.lgota_id
		,SUBSTRING(dg.name, 1, 25) AS 'LGOTA'
		,dl.name AS 'ZACON'
		,o.total_sq
		,dr.kol_people
		,dr.summa
	FROM	dbo.DSC_REP AS dr 
			,dbo.DSC_GROUPS AS dg 
			,dbo.View_OCC_ALL AS o 
			,dbo.FLATS AS f 
			,dbo.BUILDINGS AS b 
			,dbo.PEOPLE AS p 
			,dbo.VSTREETS AS s 
			,dbo.DSC_LAWS AS dl 
	WHERE dr.fin_id = @fin_id1
	AND dr.occ = o.occ
	AND dr.lgota_id = dg.id
	AND dr.owner_id = p.id
	AND o.flat_id = f.id
	AND f.bldn_id = b.id
	AND dr.summa > 0
	AND dg.law_id = COALESCE(@laws_id1, dg.law_id)

	AND dg.law_id = dl.id
	AND b.street_id = s.id
	AND b.div_id = COALESCE(@div_id1, b.div_id)
	AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
	AND o.status_id <> 'закр'
	AND o.fin_id = @fin_id1
	ORDER BY p.last_name, p.first_name, p.second_name
go

