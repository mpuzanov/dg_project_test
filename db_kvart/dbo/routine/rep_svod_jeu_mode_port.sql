CREATE   PROCEDURE [dbo].[rep_svod_jeu_mode_port]
(
	@fin_id1		SMALLINT
	,@tip			SMALLINT	= NULL -- тип жилого фонда
	,@mode			SMALLINT		= 1
	,@service_id	VARCHAR(10) = NULL
) -- услуга
/*

2/03/2009
Заменил таблицы DOM_SVOD_MODE и DOM_SVOD_SOURCE 
на DOM_SVOD_ALL

*/
AS
	SET NOCOUNT ON


	DECLARE	@t1		SMALLINT
			,@t2	SMALLINT
	IF @tip IS NULL
	BEGIN
		SET @t1 = 1
		SET @t2 = 100
	END
	ELSE
	BEGIN
		SET @t1 = @tip
		SET @t2 = @tip
	END

	IF @service_id = ''
		SET @service_id = NULL


	IF @mode = 1 -- Выдаем сводный отчет по участкам на базе таблицы  DOM_SVOD_MODE
	BEGIN
		SELECT
			jeu = b.sector_id
			,s.short_name
			,cm.Name
			,s.service_no
			,CurrentDate
			,CountLic = SUM(CountLic)
			,CountLicLgot = SUM(CountLicLgot)
			,CountLicSubsid = SUM(CountLicSubsid)
			,CountPeople = SUM(CountPeople)
			,CountPeoplelgot = SUM(CountPeoplelgot)
			,[Square] = SUM(Square)
		FROM	dbo.CONS_MODES AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.SERVICES AS s 
				,dbo.BUILDINGS AS b 
		WHERE ds.fin_id = @fin_id1
		AND cm.id = ds.mode_id
		AND s.id = cm.service_id
		AND ds.build_id = b.id
		AND b.tip_id BETWEEN @t1 AND @t2
		AND cm.service_id = COALESCE(@service_id, cm.service_id)
		GROUP BY	b.sector_id
					,s.short_name
					,cm.Name
					,s.service_no
					,CurrentDate
		UNION -- итого
		SELECT
			0
			,s.short_name
			,cm.Name
			,s.service_no
			,CurrentDate
			,CountLic = SUM(CountLic)
			,CountLicLgot = SUM(CountLicLgot)
			,CountLicSubsid = SUM(CountLicSubsid)
			,CountPeople = SUM(CountPeople)
			,CountPeoplelgot = SUM(CountPeoplelgot)
			,[SQUARE] = SUM(SQUARE)
		FROM	dbo.CONS_MODES AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.SERVICES AS s 
				,dbo.BUILDINGS AS b 
		WHERE ds.fin_id = @fin_id1
		AND cm.id = ds.mode_id
		AND s.id = cm.service_id
		AND ds.build_id = b.id
		AND b.tip_id BETWEEN @t1 AND @t2
		AND cm.service_id = COALESCE(@service_id, cm.service_id)
		GROUP BY	s.short_name
					,cm.Name
					,s.service_no
					,CurrentDate
		ORDER BY jeu, service_no, CountLic DESC
	END
	ELSE -- Выдаем сводный отчет по участкам на базе таблицы  DOM_SVOD_SOURCE
	BEGIN
		SELECT
			jeu = b.sector_id
			,s.short_name
			,cm.Name
			,s.service_no
			,CurrentDate
			,CountLic = SUM(CountLic)
			,CountLicLgot = SUM(CountLicLgot)
			,CountLicSubsid = SUM(CountLicSubsid)
			,CountPeople = SUM(CountPeople)
			,CountPeoplelgot = SUM(CountPeoplelgot)
			,[Square] = SUM(Square)
		FROM	dbo.View_SUPPLIERS AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.SERVICES AS s 
				,dbo.BUILDINGS AS b 
		WHERE ds.fin_id = @fin_id1
		AND cm.id = ds.source_id
		AND s.id = cm.service_id
		AND ds.build_id = b.id
		AND b.tip_id BETWEEN @t1 AND @t2
		AND cm.service_id = COALESCE(@service_id, cm.service_id)
		GROUP BY	b.sector_id
					,s.short_name
					,cm.Name
					,s.service_no
					,CurrentDate
		UNION
		SELECT
			0
			,s.short_name
			,cm.Name
			,s.service_no
			,CurrentDate
			,CountLic = SUM(CountLic)
			,CountLicLgot = SUM(CountLicLgot)
			,CountLicSubsid = SUM(CountLicSubsid)
			,CountPeople = SUM(CountPeople)
			,CountPeoplelgot = SUM(CountPeoplelgot)
			,[Square] = SUM(Square)
		FROM	dbo.View_SUPPLIERS AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.SERVICES AS s 
				,dbo.BUILDINGS AS b 
		WHERE ds.fin_id = @fin_id1
		AND cm.id = ds.source_id
		AND s.id = cm.service_id
		AND ds.build_id = b.id
		AND b.tip_id BETWEEN @t1 AND @t2
		AND cm.service_id = COALESCE(@service_id, cm.service_id)
		GROUP BY	s.short_name
					,cm.Name
					,s.service_no
					,CurrentDate
		ORDER BY jeu, service_no, CountLic DESC

	END
go

