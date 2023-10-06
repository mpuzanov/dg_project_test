CREATE   PROCEDURE [dbo].[k_counter_opu_values]
(
	@build_id1	INT
	,@fin_id1	SMALLINT	= NULL
	,@service_id VARCHAR(10) = null
)
AS
	/*
	Показываем список показания по ОПУ по 
	
	exec k_counter_opu_values 1031, 184	
	exec k_counter_opu_values 1031, 184	,'гвод'
	
	Используется в Картотеке

	*/
	SET NOCOUNT ON


	SELECT TOP 50
		cp.StrFinPeriod AS NameFinPeriod
		,CASE
				WHEN [service_id] IN ('гвод', 'гвс2') THEN 'ГВС'
				WHEN [service_id] IN ('хвод', 'хвс2') THEN 'ХВС'
				WHEN [service_id] IN ('элек', 'эле2', 'элмп') THEN 'ЭЛЕК'
				WHEN [service_id] IN ('отоп', 'ото2') THEN 'ОТОП'
				ELSE [service_id]
		END AS serv_name
		,u.short_id	AS unit_id
		,ci.inspector_date
		,ci.inspector_value
		,ci_pred.inspector_value AS pred_value
		,ci.actual_value
		,ci.service_id
	FROM dbo.View_counter_insp_build AS ci
	JOIN dbo.Calendar_period cp
		ON cp.fin_id=ci.fin_id
	JOIN dbo.Units AS u
		ON ci.unit_id = u.id
	OUTER APPLY (SELECT TOP 1
			ci2.inspector_value
		FROM dbo.Counter_inspector AS ci2
		WHERE ci2.counter_id = ci.counter_id
		AND ci2.fin_id < ci.fin_id
		AND ci2.tip_value = 2
		ORDER BY ci2.inspector_date DESC) AS ci_pred
	WHERE ci.fin_id <= @fin_id1
	AND ci.build_id = @build_id1
	AND (ci.service_id=@service_id OR @service_id IS NULL)
	--AND ci.inspector_value > 0
	ORDER BY ci.fin_id DESC
go

