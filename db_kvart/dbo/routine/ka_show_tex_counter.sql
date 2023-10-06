CREATE   PROCEDURE [dbo].[ka_show_tex_counter]
(
	@occ1 INT
)
AS
	--
	--  Показываем техническую корректировку по счетчикам 
	--
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	SELECT
		pc.service_id
		,serv_name = s.name
		,cl.sup_id
		,sa.name AS sup_name
		,'name' = s.short_name
		,saldo = COALESCE(pc.saldo, 0)
		,'calcvalue' = COALESCE(pc.value, 0)
		,'sum1' = COALESCE((SELECT
				SUM(ap2.value)
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.service_id = pc.service_id
			AND ap2.fin_id = @fin_current)
		, 0)
		,'sum2' = COALESCE((SELECT
				SUM(ap2.value)
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.service_id = pc.service_id
			AND ap2.fin_id = @fin_current
			AND ap2.add_type <> 10)
		, 0)
		,'sum3' = COALESCE((SELECT
				SUM(value)
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.service_id = pc.service_id
			AND ap2.fin_id = @fin_current
			AND ap2.add_type = 10)
		, 0)
		,'doc' = COALESCE((SELECT TOP 1
				doc
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.doc IS NOT NULL
			AND ap2.fin_id = @fin_current
			AND ap2.add_type = 10)
		, '')
		,doc_no = COALESCE((SELECT TOP 1
				doc_no
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.fin_id = @fin_current
			AND ap2.add_type = 10)
		, '')
		,doc_date = COALESCE((SELECT TOP 1
				doc_date
			FROM dbo.ADDED_COUNTERS_ALL AS ap2 
			WHERE ap2.occ = @occ1
			AND ap2.fin_id = @fin_current
			AND ap2.add_type = 10)
		, NULL)
	FROM dbo.PAYM_COUNTER_ALL AS pc 
	JOIN dbo.CONSMODES_LIST cl
		ON pc.occ = cl.occ
		AND pc.service_id = cl.service_id
	JOIN dbo.SUPPLIERS_ALL sa 
		ON cl.sup_id = sa.id
	JOIN dbo.View_SERVICES AS s 
		ON pc.service_id = s.id
	WHERE pc.occ = @occ1
	AND pc.fin_id = @fin_current
	ORDER BY s.service_no
go

