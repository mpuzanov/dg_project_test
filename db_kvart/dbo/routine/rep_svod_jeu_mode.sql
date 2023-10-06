CREATE   PROCEDURE [dbo].[rep_svod_jeu_mode]
(
	@fin_id1		SMALLINT
	,@tip			SMALLINT	= NULL -- тип жилого фонда
	,@mode			SMALLINT	= 1 --(1-по режимам, 2 - по поставщикам)
	,@service_id	VARCHAR(10)	= NULL
	,@div_id1		SMALLINT	= NULL
	,@jeu1			SMALLINT	= NULL
	,@build1		INT			= NULL
)
AS
	/*
	
	дата создания: 
	автор: 
	
	дата последней модификации: 01.07.2004
	автор изменений: Кривобоков А.В.
	добавлен выбор по услугам @service_id
	
	10.11.2004 Пузанов добавил:  'CountPeople_no'=sum(CountPeople_no) 
	
	2/03/2009
	Заменил таблицы DOM_SVOD_MODE и DOM_SVOD_SOURCE 
	на DOM_SVOD_ALL
	
	23/09/2009
	
	*/

	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, @build1, NULL, NULL)

	IF @service_id = ''
		SET @service_id = NULL

	IF @fin_id1 >= @fin_current
	BEGIN

		IF @mode = 1  -- Выдаем сводный отчет по участкам и режимам
		BEGIN
			SELECT
				jeu = b.sector_id
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.CONS_MODES AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s
					,dbo.BUILDINGS AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.mode_id
			AND s.id = cm.service_id
			AND ds.build_id = b.id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.id = COALESCE(@build1, b.id)
			GROUP BY	b.sector_id
						,s.short_name
						,cm.name
						,s.service_no
						,currentdate
			UNION ALL -- итого
			SELECT
				0
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.CONS_MODES AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS AS b
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.mode_id
			AND s.id = cm.service_id
			AND ds.build_id = b.id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.id = COALESCE(@build1, b.id)
			GROUP BY	s.short_name
						,cm.name
						,s.service_no
						,currentdate
			ORDER BY b.sector_id, s.short_name, CountLic DESC
		END
		ELSE -- Выдаем сводный отчет по участкам и поставщикам
		BEGIN
			SELECT
				jeu = b.sector_id
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.View_SUPPLIERS AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.source_id
			AND s.id = cm.service_id
			AND ds.build_id = b.id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.id = COALESCE(@build1, b.id)
			GROUP BY	b.sector_id
						,s.short_name
						,cm.name
						,s.service_no
						,currentdate
			UNION ALL
			SELECT
				0
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.View_SUPPLIERS AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS AS b
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.source_id
			AND s.id = cm.service_id
			AND ds.build_id = b.id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.id = COALESCE(@build1, b.id)
			GROUP BY	s.short_name
						,cm.name
						,s.service_no
						,currentdate
			ORDER BY b.sector_id, s.short_name, CountLic DESC

		END
	END
	ELSE
	BEGIN  -- прошлые периоды

		IF @mode = 1  -- Выдаем сводный отчет по участкам и режимам
		BEGIN
			SELECT
				jeu = b.sector_id
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.CONS_MODES AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS_HISTORY AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.mode_id
			AND s.id = cm.service_id
			AND ds.build_id = b.bldn_id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.fin_id = @fin_id1
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.bldn_id = COALESCE(@build1, b.bldn_id)
			GROUP BY	b.sector_id
						,s.short_name
						,cm.name
						,s.service_no
						,currentdate
			UNION ALL -- итого
			SELECT
				0
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.CONS_MODES AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS_HISTORY AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.mode_id
			AND s.id = cm.service_id
			AND ds.build_id = b.bldn_id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.fin_id = @fin_id1
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.bldn_id = COALESCE(@build1, b.bldn_id)
			GROUP BY	s.short_name
						,cm.name
						,s.service_no
						,currentdate
			ORDER BY b.sector_id, s.short_name, CountLic DESC
		END
		ELSE -- Выдаем сводный отчет по участкам и поставщикам
		BEGIN
			SELECT
				jeu = b.sector_id
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.SUPPLIERS AS cm 
					,dbo.DOM_SVOD_ALL AS ds
					,dbo.View_SERVICES AS s
					,dbo.BUILDINGS_HISTORY AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.source_id
			AND s.id = cm.service_id
			AND ds.build_id = b.bldn_id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.fin_id = @fin_id1
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.bldn_id = COALESCE(@build1, b.bldn_id)
			GROUP BY	b.sector_id
						,s.short_name
						,cm.name
						,s.service_no
						,currentdate
			UNION ALL
			SELECT
				0
				,s.short_name
				,cm.name
				,s.service_no
				,currentdate
				,CountLic = SUM(CountLic)
				,CountLicLgot = SUM(CountLicLgot)
				,CountLicSubsid = SUM(CountLicSubsid)
				,CountPeople = SUM(CountPeople)
				,CountPeoplelgot = SUM(CountPeoplelgot)
				,[SQUARE] = SUM(SQUARE)
				,CountPeople_no = SUM(CountPeople_no)
			FROM	dbo.SUPPLIERS AS cm 
					,dbo.DOM_SVOD_ALL AS ds 
					,dbo.View_SERVICES AS s 
					,dbo.BUILDINGS_HISTORY AS b 
			WHERE ds.fin_id = @fin_id1
			AND cm.id = ds.source_id
			AND s.id = cm.service_id
			AND ds.build_id = b.bldn_id
			AND b.tip_id = COALESCE(@tip, b.tip_id)
			AND cm.service_id = COALESCE(@service_id, cm.service_id)
			AND b.fin_id = @fin_id1
			AND b.div_id = COALESCE(@div_id1, b.div_id)
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND b.bldn_id = COALESCE(@build1, b.bldn_id)
			GROUP BY	s.short_name
						,cm.name
						,s.service_no
						,currentdate
			ORDER BY b.sector_id, s.short_name, CountLic DESC

		END
	END
go

