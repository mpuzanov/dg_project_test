CREATE   PROCEDURE [dbo].[rep_counter_schtl]
(
	@occ			INT
	,@service_id	VARCHAR(10) = NULL
)

/*
Показания квартиросъемщика

автор:		    Пузанов
дата создания:	25.03.11
дата изменеия:	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	.fr3
*/
AS

	SET NOCOUNT ON


	SELECT
		s.name AS serv_name
		,c.id
		,c.serial_number
		,o.address
		,ci.inspector_value
		,ci.inspector_date
		,ci.actual_value
		,ci.kol_day
		,ci.value_vday
		,ci.tarif
		,ci.value_paym
		,ci.comments
		,ci.date_edit
		,u.Initials AS Name_user
		,cp.StrFinPeriod AS Fin_name
		,CASE
			WHEN ci.mode_id = 0 THEN 'Текущий'
			ELSE (SELECT
					name
				FROM dbo.CONS_MODES 
				WHERE id = ci.mode_id)
		END AS mode_name
		,CASE
			WHEN c.date_del IS NOT NULL THEN 1
			ELSE 0
		END AS closed
	FROM dbo.VOcc AS o 
	JOIN dbo.Flats AS f 
		ON o.flat_id = f.id
	JOIN dbo.Counters AS c 
		ON f.id = c.flat_id
	JOIN dbo.Counter_inspector AS ci
		ON c.id = ci.counter_id
	JOIN dbo.View_SERVICES AS s
		ON c.service_id = s.id
	LEFT JOIN USERS u
		ON u.id = c.user_edit
	JOIN dbo.Calendar_period cp
		ON cp.fin_id = ci.fin_id
	WHERE 
		o.occ = @occ
		AND c.service_id = COALESCE(@service_id, c.service_id)
	ORDER BY s.name, ci.inspector_date DESC
go

