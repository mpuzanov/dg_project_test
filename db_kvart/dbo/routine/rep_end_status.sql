CREATE   PROCEDURE [dbo].[rep_end_status]
(
	@date1			SMALLDATETIME
	,@date2			SMALLDATETIME
	,@div_id1		SMALLINT	= NULL
	,@tip_id1		SMALLINT	= NULL
	,@ShowDel		BIT			= 1 -- показывать удалённые
	,@property_id	VARCHAR(10)	= NULL
	,@town_id		SMALLINT	= NULL
)
AS
/*
	Список людей по которым заканчивается статус прописки
	rep_end_status '20160101','20160130'
*/
	SET NOCOUNT ON


	SELECT
		p.occ
		,o.address
		,CONCAT(RTRIM([Last_name]),' ',LEFT([First_name],1),'. ',LEFT(Second_name,1),'.') AS Initials
		,ps.NAME
		,p.DateEnd
		,p.DateDel
		,o.proptype_id
	FROM dbo.PEOPLE AS p 
	JOIN dbo.PERSON_STATUSES AS ps
		ON p.status2_id = ps.id
	JOIN dbo.VOCC AS o 
		ON p.occ = o.occ
	JOIN dbo.BUILDINGS AS b 
		ON o.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	WHERE 
		DateEnd BETWEEN @date1 AND @date2
		AND b.div_id = COALESCE(@div_id1, b.div_id)
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.town_id = COALESCE(@town_id, b.town_id)
		AND o.proptype_id = COALESCE(@property_id, o.proptype_id)
		AND COALESCE(p.DateDel, 0) =
			CASE
				WHEN @ShowDel = 1 THEN COALESCE(p.DateDel, 0)
				ELSE 0
			END
	ORDER BY b.town_id, s.NAME, b.nom_dom_sort, o.nom_kvr_sort
go

