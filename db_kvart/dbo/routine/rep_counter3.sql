CREATE   PROCEDURE [dbo].[rep_counter3]
(
	@tip_id1		SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@build_id1		INT			= NULL
	,@service_id1	VARCHAR(10)	= NULL
	,@tip_counter	SMALLINT	= NULL
	,@fin_id1		SMALLINT	= NULL
)
/*
Показания квартиросъемщика

автор:		    Пузанов
дата создания:	21.12.10
дата изменеия:	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	Counter3.fr3

exec rep_counter3 @tip_id1=28,@service_id1='хвод'
*/
AS

	SET NOCOUNT ON


	DECLARE	@internal		BIT	= NULL
			,@fin_current	SMALLINT

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)

	SET @internal =
		CASE
			WHEN @tip_counter = 2 THEN 1
			WHEN @tip_counter = 1 THEN 1
			ELSE NULL
		END

	IF @fin_id1 IS NULL
		AND @service_id1 IS NULL
		SELECT
			@fin_id1 = @fin_current



	SELECT
		c.service_id
		,c.id
		,c.serial_number
		,s.name AS street_name
		,b.nom_dom
		,CONCAT(s.name , ' д.' , b.nom_dom) AS Adres_doma
		,f.nom_kvr
		,ci.occ AS occ
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
	FROM dbo.View_COUNTER_INSPECTOR AS ci
	JOIN dbo.COUNTERS AS c
		ON ci.counter_id = c.id
	JOIN dbo.FLATS AS f 
		ON c.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	JOIN CALENDAR_PERIOD cp
		ON ci.fin_id = cp.fin_id
	LEFT JOIN USERS u
		ON ci.user_edit = u.id
	JOIN dbo.View_OCC_ALL_LITE AS o 
			ON ci.occ = o.occ
			AND ci.fin_id = o.fin_id
	WHERE 1=1
		AND (b.id = @build_id1 OR @build_id1 IS null)
		AND (b.div_id = @div_id1 OR @div_id1 IS null)
		AND (b.tip_id = @tip_id1 OR @tip_id1 IS null)
		AND (c.service_id = @service_id1 OR @service_id1 IS NULL)
		AND c.internal = COALESCE(@internal, c.internal)
		AND o.total_sq>0
		AND (ci.fin_id = @fin_id1 OR (@fin_id1 IS NULL AND ci.fin_id >= @fin_current - 6))
	ORDER BY name, b.nom_dom_sort, f.nom_kvr_sort, ci.inspector_date DESC
	OPTION (RECOMPILE)
go

