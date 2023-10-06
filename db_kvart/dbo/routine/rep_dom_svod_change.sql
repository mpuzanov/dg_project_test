CREATE   PROCEDURE [dbo].[rep_dom_svod_change]
(
	@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@tip_id	SMALLINT	= NULL
	,@build_id1	INT			= NULL
	,@only_izm	BIT			= 1
)
AS
	/*

reports: Изменение количества и площади в МКД.fr3

rep_dom_svod_change 160, 162, 28 , null, 1

rep_dom_svod_change 170, 170, 27 , null, 1

*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	IF @only_izm IS NULL
		SET @only_izm = 1

	CREATE TABLE #t
	(
		build_id		INT
		,RAION			VARCHAR(30) COLLATE database_default
		,STREETS		VARCHAR(30) COLLATE database_default
		,NOM_DOM		VARCHAR(12) COLLATE database_default
		,total_sq1		DECIMAL(10, 4)
		,total_sq2		DECIMAL(10, 4)
		,living_sq1		DECIMAL(10, 4)
		,living_sq2		DECIMAL(10, 4)
		,arenda_sq1		DECIMAL(10, 4)
		,arenda_sq2		DECIMAL(10, 4)
		,opu_sq1		DECIMAL(10, 4)
		,opu_sq2		DECIMAL(10, 4)
		,privat_sq1		DECIMAL(10, 4)
		,privat_sq2		DECIMAL(10, 4)
		,mun_sq1		DECIMAL(10, 4)
		,mun_sq2		DECIMAL(10, 4)
		,people_fin1	SMALLINT
		,people_fin2	SMALLINT
		,flats_fin1		SMALLINT
		,flats_fin2		SMALLINT
		,occ_fin1		SMALLINT
		,occ_fin2		SMALLINT
		,flats_arenda1	SMALLINT
		,flats_arenda2	SMALLINT
		,flats_itog1	SMALLINT
		,flats_itog2	SMALLINT
	)

	INSERT
	INTO #t
	(	build_id
		,RAION
		,STREETS
		,NOM_DOM
		,total_sq1
		,total_sq2
		,living_sq1
		,living_sq2
		,arenda_sq1
		,arenda_sq2
		,opu_sq1
		,opu_sq2
		,privat_sq1
		,privat_sq2
		,mun_sq1
		,mun_sq2
		,people_fin1
		,people_fin2
		,flats_fin1
		,flats_fin2
		,occ_fin1
		,occ_fin2
		,flats_arenda1
		,flats_arenda2)
		SELECT
			b.bldn_id
			,b.div_name
			,b.street_name
			,b.NOM_DOM
			,total_sq1 = 0
			,total_sq2 = 0
			,living_sq1 = COALESCE((SELECT
					d.[square]
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id1)
			, 0)
			,living_sq2 = COALESCE((SELECT
					d.[square]
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id2)
			, 0)
			,arenda_sq1 = COALESCE(b1.arenda_sq, 0)
			,arenda_sq2 = COALESCE(b.arenda_sq, 0)
			,opu_sq1 = COALESCE(b1.opu_sq, 0)
			,opu_sq2 = COALESCE(b.opu_sq, 0)
			,privat_sq1 = COALESCE((SELECT
					SUM(total_sq)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id1
				AND voal.status_id <> 'закр'
				AND voal.proptype_id <> 'непр'),0)
			,privat_sq2 = COALESCE((SELECT
					SUM(total_sq)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id2
				AND voal.status_id <> 'закр'
				AND voal.proptype_id <> 'непр'),0)
			,mun_sq1 = COALESCE((SELECT
					SUM(total_sq)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id1
				AND voal.status_id <> 'закр'
				AND voal.proptype_id = 'непр'),0)
			,mun_sq2 = COALESCE((SELECT
					SUM(total_sq)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id2
				AND voal.status_id <> 'закр'
				AND voal.proptype_id = 'непр'),0)
			,people_fin1 = COALESCE((SELECT
					d.CountPeople
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id1)
			, 0)
			,people_fin2 = COALESCE((SELECT
					d.CountPeople
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id2)
			, 0)
			,flats_fin1 = COALESCE((SELECT
					d.CountFlats
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id1)
			, 0)
			,flats_fin2 = COALESCE((SELECT
					d.CountFlats
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id2)
			, 0)
			,occ_fin1 = COALESCE((SELECT
					d.CountLic
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id1)
			, 0)
			,occ_fin2 = COALESCE((SELECT
					d.CountLic
				FROM dbo.DOM_SVOD AS d 
				WHERE d.build_id = b.bldn_id
				AND d.fin_id = @fin_id2)
			, 0)
			,flats_arenda1 = COALESCE((SELECT
					COUNT(occ)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id2
				AND voal.status_id <> 'закр'
				AND voal.roomtype_id = 'арен')
			, 0)
			,flats_arenda2 = COALESCE((SELECT
					COUNT(occ)
				FROM dbo.View_OCC_ALL_LITE voal
				WHERE voal.bldn_id = b.bldn_id
				AND voal.fin_id = @fin_id2
				AND voal.status_id <> 'закр'
				AND voal.roomtype_id = 'арен')
			, 0)
		FROM dbo.View_BUILD_ALL AS b 
		JOIN dbo.View_BUILD_ALL AS b1 
			ON b.bldn_id = b1.bldn_id
			AND b1.fin_id = @fin_id1
		WHERE (b.tip_id = @tip_id OR @tip_id IS NULL)
		AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL)
		AND b.fin_id = @fin_id2

	UPDATE #t
	SET	total_sq1		= living_sq1 + arenda_sq1 + opu_sq1
		,total_sq2		= living_sq2 + arenda_sq2 + opu_sq2
		,flats_itog1	= flats_fin1 + flats_arenda1
		,flats_itog2	= flats_fin2 + flats_arenda2

	IF @only_izm = 1
	BEGIN
		DELETE FROM #t
		WHERE (total_sq1 = total_sq2)
			AND (living_sq1 = living_sq2)
			AND (arenda_sq1 = arenda_sq2)
			AND (opu_sq1 = opu_sq2)
			AND (privat_sq1 = privat_sq2)
			AND (mun_sq1 = mun_sq2)
			AND (people_fin1 = people_fin2)
			AND (flats_fin1 = flats_fin2)
			AND (occ_fin1 = occ_fin2)
			AND (flats_arenda1 = flats_arenda2)
			AND (flats_itog1 = flats_itog2)

		UPDATE #t
		SET	total_sq1	= 0
			,total_sq2	= 0
		WHERE total_sq1 = total_sq2

		UPDATE #t
		SET	living_sq1	= 0
			,living_sq2	= 0
		WHERE living_sq1 = living_sq2

		UPDATE #t
		SET	arenda_sq1	= 0
			,arenda_sq2	= 0
		WHERE arenda_sq1 = arenda_sq2

		UPDATE #t
		SET	opu_sq1		= 0
			,opu_sq2	= 0
		WHERE opu_sq1 = opu_sq2

		UPDATE #t
		SET	privat_sq1	= 0
			,privat_sq2	= 0
		WHERE privat_sq1 = privat_sq2

		UPDATE #t
		SET	mun_sq1		= 0
			,mun_sq2	= 0
		WHERE mun_sq1 = mun_sq2

		UPDATE #t
		SET	people_fin1		= 0
			,people_fin2	= 0
		WHERE people_fin1 = people_fin2


		UPDATE #t
		SET	flats_fin1	= 0
			,flats_fin2	= 0
		WHERE flats_fin1 = flats_fin2

		UPDATE #t
		SET	occ_fin1	= 0
			,occ_fin2	= 0
		WHERE occ_fin1 = occ_fin2

		UPDATE #t
		SET	flats_arenda1	= 0
			,flats_arenda2	= 0
		WHERE flats_arenda1 = flats_arenda2

		UPDATE #t
		SET	flats_itog1		= 0
			,flats_itog2	= 0
		WHERE flats_itog1 = flats_itog2

	END

	SELECT
		*
	FROM #t AS t
	ORDER BY STREETS
	, dbo.Fun_SortDom(NOM_DOM)


	DROP TABLE #t
go

