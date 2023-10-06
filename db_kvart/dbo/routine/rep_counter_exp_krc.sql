-- =============================================
-- Author:		Пузанов
-- Create date: 06/10/2011
-- Description:	Реестр показаний ИПУ
-- =============================================
CREATE     PROCEDURE [dbo].[rep_counter_exp_krc]
	@tip_id1	SMALLINT
	,@fin_id1	SMALLINT
	,@build_id1	INT	= NULL
	,@is_del	BIT	= 0
	,@is_exp	BIT	= 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@db_name	VARCHAR(20)	= UPPER(DB_NAME())
			,@user_id	INT
	SELECT
		@user_id = [dbo].[Fun_GetCurrentUserId]()

	IF @is_del IS NULL
		SET @is_del = 0
	IF EXISTS (SELECT
				group_id
			FROM dbo.GROUP_MEMBERSHIP 
			WHERE [user_id] = @user_id
			AND group_id = 'адмн')
		SET @is_exp = 1

	DECLARE @fin_current SMALLINT

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)
	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	SELECT
		o.start_date
		,cl.occ
		,occ_sup = sup.occ_sup
		,o.kol_people
		,serv_name = serv.short_name
		,s.name AS street
		,b.nom_dom
		,o.nom_kvr
		,c.serial_number
		,dbo.Fun_GetCounterDate_pred(c.id, @fin_id1) AS date_pred
		,dbo.Fun_GetCounterValue_pred(c.id, @fin_id1) AS value_pred
		,inspector_date
		,inspector_value
		,actual_value
		,o.total_sq
		,o.roomtype_id
		,o.proptype_id
		,o.[floor]
		,c.[type]
		,c.build_id
		,c.date_create
		,c.count_value
		,c.PeriodCheck
		,serv_name = S1.name
		,c.date_del
	FROM dbo.View_OCC_ALL AS o 
	JOIN dbo.OCC_SUPPLIERS AS sup 
		ON o.occ = sup.occ
		AND sup.fin_id = @fin_id1
	JOIN dbo.View_COUNTER_ALL AS cl 
		ON o.occ = cl.occ
		AND o.fin_id = cl.fin_id
	JOIN dbo.COUNTERS AS c 
		ON o.flat_id = c.flat_id
		AND cl.counter_id = c.id
	JOIN dbo.BUILDINGS AS b 
		ON o.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	JOIN dbo.View_SERVICES AS serv 
		ON c.service_id = serv.id
	OUTER APPLY (SELECT TOP 1
			inspector_value
			,inspector_date
			,actual_value
		FROM dbo.COUNTER_INSPECTOR 
		WHERE cl.counter_id = counter_id
		AND fin_id = @fin_id1
		AND tip_value = 1
		ORDER BY inspector_date DESC) AS ci
	JOIN dbo.SERVICES AS S1 
		ON c.service_id = S1.id
	WHERE o.fin_id = @fin_id1
	AND o.tip_id = COALESCE(@tip_id1, o.tip_id)
	AND COALESCE(c.date_del, '19000101') =
		CASE
			WHEN @is_del = 0 THEN '19000101'
			ELSE COALESCE(c.date_del, '19000101')
		END
	AND o.bldn_id = COALESCE(@build_id1, o.bldn_id)
	AND cl.service_id IN ('гвод', 'отоп', 'гвс2', 'ото2')
	-- Блокируем СПДУ по гвс
	AND c.service_id =
		CASE
			WHEN @is_exp = 1 THEN c.service_id
			WHEN (@db_name IN ('KVART') AND
			b.tip_id = 27 AND
			c.service_id IN ('гвод', 'гвс2', 'отоп')) THEN ''
			WHEN (@db_name IN ('KOMP') AND
			b.tip_id = 137 AND
			c.service_id IN ('гвод', 'гвс2', 'отоп')) THEN ''
			ELSE c.service_id
		END
	ORDER BY s.name
	, b.nom_dom_sort
	, o.nom_kvr_sort


END
go

