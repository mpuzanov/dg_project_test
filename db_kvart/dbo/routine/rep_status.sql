CREATE   PROCEDURE [dbo].[rep_status]
AS
	/*
		Выдаем параметры статуса прописки
		
		dbo.rep_status
	*/

	SET NOCOUNT ON

	SELECT
		id
		,CONCAT(name , ' (' , short_name , ')') AS name
		,is_paym
		,is_lgota
		,is_subs
		,is_norma_all
		,is_norma
		,is_norma_sub
		,ps.is_kolpeople
		,is_registration
		,CASE is_temp
			WHEN '1' THEN 'временно'
			WHEN '0' THEN 'постоянно'
			ELSE ''
		END AS is_temp
		,STUFF((SELECT
				CONCAT(' ' , service_id , '-' , LTRIM(STR(COALESCE(have_paym, 0))))
			FROM dbo.View_SERVICES AS s
			LEFT JOIN dbo.PERSON_CALC AS pc
				ON s.id = pc.service_id
			WHERE pc.status_id = ps.id
			ORDER BY s.sort_no
			FOR XML PATH (''))
		, 1, 1, '')
		AS StrServices
	FROM dbo.PERSON_STATUSES AS ps
go

