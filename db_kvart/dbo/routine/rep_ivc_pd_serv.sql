-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[rep_ivc_pd_serv]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @occ INT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*
rep_ivc_pd_serv @fin_id=231, @tip_id=2,@build_id=6765, @sup_id=null, @occ=null, @format='xml'	
rep_ivc_pd_serv @fin_id=178, @tip_id=28,@build_id=1031, @sup_id=323
rep_ivc_pd_serv @fin_id=178, @tip_id=28,@build_id=1031, @sup_id=null
rep_ivc_pd_serv @fin_id=222, @tip_id=169,@build_id=null, @sup_id=null, @occ=330001, @format='xml'
*/
BEGIN
	SET NOCOUNT ON;

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @tip_id IS NULL
		SELECT @build_id = 0
			 , @sup_id = 0
			 , @fin_id = 0
			 , @tip_id = 0

	IF @fin_id IS NULL
		SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	-- 2. Создать таблицу с услугами
	-- rep_gis_pd_serv
	CREATE TABLE #pdserv (
		  num_pd VARCHAR(20) COLLATE database_default
		, build_id INT
		, occ INT
		, short_name VARCHAR(50) COLLATE database_default
		, short_id VARCHAR(6) COLLATE database_default
		, service_id VARCHAR(10) COLLATE database_default
		, tarif DECIMAL(10, 4) DEFAULT 0
		, kol DECIMAL(12, 6) DEFAULT 0
		, kol_dom DECIMAL(12, 6) DEFAULT 0
		, koef DECIMAL(10, 4) DEFAULT NULL
		, saldo DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, value DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, value_dom DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, value_itog DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, added1 DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, added12 DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, added DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid_dom DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid_koef_up DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid_itog DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, debt DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, sort_no INT DEFAULT 0
		, mode_id INT DEFAULT NULL
		, unit_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, is_build BIT DEFAULT 0
		, service_id_from VARCHAR(10) COLLATE database_default DEFAULT NULL
		, sup_id INT DEFAULT 0
		, account_one BIT DEFAULT 0
		, is_sum BIT DEFAULT 1
		, subsid_only BIT DEFAULT 0
		, tip_id SMALLINT DEFAULT 0
		, vsoder BIT DEFAULT 0
		, vydel BIT DEFAULT 0
		, OWNER_ID INT DEFAULT 0
		, [service_name] VARCHAR(50) COLLATE database_default DEFAULT ''
		, OWNER_ID_BUILD INT DEFAULT 0
		, metod SMALLINT DEFAULT 0
		, service_name_gis NVARCHAR(100) COLLATE database_default DEFAULT NULL
		, service_type SMALLINT DEFAULT 1
		, is_counter SMALLINT DEFAULT 0
		, reason_added VARCHAR(800) COLLATE database_default DEFAULT NULL
		, is_koef_up BIT DEFAULT 0
		, no_export_volume_gis BIT DEFAULT 0
		, koef_up DECIMAL(9, 4) DEFAULT NULL
		, total_sq DECIMAL(9, 2) DEFAULT 0
		, kol_norma_single DECIMAL(12, 6) DEFAULT 0
		, blocked_kvit BIT DEFAULT 0
		, source_id INT DEFAULT NULL
		, group_name_kvit VARCHAR(100) COLLATE database_default DEFAULT ''
		, group_sort_id SMALLINT DEFAULT 0
		, penalty_serv DECIMAL(15, 4) DEFAULT 0
		, value_occ DECIMAL(15, 4) DEFAULT 0 -- общее начисление по лицевому
	)

	INSERT INTO #pdserv
	EXEC k_intPrintDetail_occ_build @Fin_Id1 = @fin_id -- Фин.период
								  , @build_id = @build_id-- дом
								  , @Occ1 = @occ -- лицевой
								  , @tip_id = @tip_id --жилой фонд
								  , @sup_id = @sup_id
								  , @Debug = 0

	-- nachislenie ROOT
	CREATE TABLE #t_detail (
		  build_id INT
		, occ VARCHAR(20) COLLATE database_default
		, num_pd VARCHAR(20) COLLATE database_default
		, vid VARCHAR(50) COLLATE database_default
		, tarif VARCHAR(20) COLLATE database_default
		, ed VARCHAR(20) COLLATE database_default
		, normativ VARCHAR(20) COLLATE database_default --DECIMAL(12,6)
		, potrebleno VARCHAR(20) COLLATE database_default --DECIMAL(12,6)
		, nachisleno VARCHAR(20) COLLATE database_default --DECIMAL(9,2)
		, pereraschet VARCHAR(20) COLLATE database_default
		, koplate VARCHAR(20) COLLATE database_default
	)
	INSERT INTO #t_detail
	SELECT build_id
		 , occ AS occ
		 , num_pd
		 , short_name AS vid
		 , dbo.FSTR(tarif, 9, 2) AS tarif
		 , short_id AS ed
		 , dbo.FSTR(kol_norma_single, 12, 6) AS normativ
		 , dbo.FSTR(kol, 12, 6) AS potrebleno
		 , dbo.FSTR(value, 9, 2) AS nachisleno
		 , dbo.FSTR(added, 9, 2) AS pereraschet
		 , dbo.FSTR(paid_itog, 9, 2) AS koplate
	FROM #pdserv

	IF @format IS NULL
		SELECT *
		FROM #t_detail

	IF @format = 'xml'
		SELECT occ AS '@occ'
			 , vid AS '@vid'
			 , tarif AS '@tarif'
			 , ed AS '@ed'
			 , normativ AS '@normativ'
			 , potrebleno AS '@potrebleno'
			 , nachisleno AS '@nachisleno'
			 , pereraschet AS '@pereraschet'
			 , koplate AS '@koplate'
		FROM #t_detail AS det
		FOR XML PATH ('nachislenie')

	--select (
	--	SELECT 
	--		nomerls as '@nomerls'
	--		,vid as '@vid'
	--		,tarif as '@tarif'
	--		,ed as '@ed'
	--		,0 as '@normativ'
	--		,potrebleno as '@potrebleno'
	--		,nachisleno as '@nachisleno'
	--		,pereraschet as '@pereraschet'
	--		,koplate as '@koplate'
	--	FROM #t_detail as det FOR XML PATH('nachislenie')
	--) as result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t_detail
				FOR JSON PATH, ROOT ('nachislenie')
			) AS result

END
go

