CREATE   PROCEDURE [dbo].[rep_status_history]
(
@tip_id smallint = null
)
AS
	/*
	
	Выдаем историю изменения кол-во людей по статусам прописки
	за последние 12 месяцев
	
	EXEC rep_status_history

	EXEC rep_status_history 1

	*/
	SET NOCOUNT ON;

	DECLARE @fin_id1 SMALLINT
	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	SET @fin_id1 = @fin_id1 - 8
	IF @fin_id1 < 0
		SET @fin_id1 = 0

	;WITH cte AS (
	SELECT
		p.fin_id
		,dbo.Fun_NameFinPeriodDate(MIN(voa.start_date)) AS 'Month'
		,ps.name AS 'Status'
		,COUNT(p.owner_id) AS 'Kol_vo'
	FROM dbo.View_occ_all AS voa -- для ограничения доступа
		JOIN dbo.View_people_all AS p
			ON voa.fin_id = p.fin_id AND voa.occ = p.occ
		JOIN dbo.Person_statuses AS ps 
			ON p.status2_id = ps.id
	WHERE 1=1
		AND voa.fin_id >= @fin_id1
		AND voa.status_id<>'закр'
		AND (@tip_id is null or voa.tip_id=@tip_id)
	GROUP BY p.fin_id
			,ps.name
	)
	SELECT t1.fin_id 
	, t1.Month
	, t1.Status
	, t1.Kol_vo
	, t1.Kol_vo-t2.Kol_vo as dif
	FROM cte t1
	 LEFT JOIN cte t2 
		ON t2.fin_id=t1.fin_id-1 
		AND t1.Status=t2.Status
	ORDER BY t1.fin_id
go

