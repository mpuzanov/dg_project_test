-- =============================================
-- Author:		Пузанов
-- Create date: 08.07.2015
-- Description:	Синхронизация лиц/счетов
-- =============================================
CREATE           PROCEDURE [dbo].[k_sync_occ]
(
	  @occ_from INT
	, @occ_to INT
	, @debug BIT = 0
	, @is_del BIT = 1 -- синхронизировать включая выписанных граждан
	, @people_add SMALLINT = 0 OUTPUT
	, @people_del SMALLINT = 0 OUTPUT
)
AS
/*
DECLARE @people_add SMALLINT
	  , @people_del SMALLINT

EXECUTE dbo.k_sync_occ @occ_from = 289008
					 , @occ_to = 289183
					 , @debug = 1
					 , @is_del = 1
					 , @people_add = @people_add OUTPUT
					 , @people_del = @people_del OUTPUT

SELECT @people_add AS people_add
	 , @people_del AS people_del
*/
BEGIN
	SET NOCOUNT ON;

	SELECT @people_add = 0
		 , @people_del = 0
		 , @is_del = COALESCE(@is_del, 1)

	IF @occ_from = @occ_to
		RETURN

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations AS o 
			WHERE Occ = @occ_from
		)
	BEGIN
		RAISERROR (N'Лицевой счёт %i не найден', 16, 1, @occ_from)
	END

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations AS o 
			WHERE Occ = @occ_to
		)
	BEGIN
		RAISERROR (N'Лицевой счёт %i не найден', 16, 1, @occ_to)
	END

	SELECT o.Occ
		 , last_name
		 , first_name
		 , second_name
		 , status2_id
		 , Fam_id
		 , birthdate
		 , DateReg
		 , DateEnd
		 , Dola_priv1
		 , Dola_priv2
		 , sex
		 , DOCTYPE_ID
		 , doc_no
		 , PASSSER_NO
		 , ISSUED
		 , DOCORG
		 , kod_pvs
		 , Del
		 , DateDel
		 , p.id AS owner_id_old
		 , o.address
		 , F.bldn_id AS build_old
		 , 0 AS build_new
		 , o.occ_uid
	INTO #t
	FROM dbo.People AS p
		JOIN dbo.Occupations AS o ON 
			p.Occ = o.Occ
		JOIN dbo.Flats AS F ON 
			F.id = o.flat_id
		LEFT JOIN dbo.Iddoc AS doc ON 
			p.id = doc.owner_id
			AND doc.active = 1
	WHERE o.Occ = @occ_from
		AND p.Del = CASE WHEN(@is_del = 0) THEN 0 ELSE p.Del END

	DECLARE @i INT = 0
		  , @y INT = 0
		  , @street_id INT
		  , @street_name VARCHAR(50)
		  , @nom_dom VARCHAR(12)
		  , @nom_kvr VARCHAR(20)
		  , @fin_current SMALLINT
		  , @build_new INT
		  , @LAST_NAME VARCHAR(50)
		  , @FIRST_NAME VARCHAR(30)
		  , @SEC_NAME VARCHAR(30)
		  , @STATUS2_ID VARCHAR(10)
		  , @FAM_ID VARCHAR(10)
		  , @BIRTHDATE DATETIME
		  , @DATEREG DATETIME
		  , @DateEnd DATETIME = NULL
		  , @DOLA_PRIV1 SMALLINT
		  , @DOLA_PRIV2 SMALLINT
		  , @SEX SMALLINT
		  , @DOCTYPE_ID VARCHAR(10)
		  , @DOC_NO VARCHAR(12)
		  , @PASSSER_NO VARCHAR(12)
		  , @ISSUED DATETIME
		  , @DOCORG VARCHAR(50)
		  , @KOD_PVS VARCHAR(7)
		  , @DateDel DATETIME
		  , @owner_id INT
		  , @owner_id_old INT
		  , @people_uid UNIQUEIDENTIFIER
		  , @comment1 VARCHAR(50) = 'синхронизация с л/сч ' + LTRIM(STR(@occ_from))

	DECLARE curs CURSOR LOCAL FOR
		SELECT last_name
			 , first_name
			 , second_name
			 , status2_id
			 , Fam_id
			 , birthdate
			 , DateReg
			 , DateEnd
			 , Dola_priv1
			 , Dola_priv2
			 , sex
			 , DOCTYPE_ID
			 , doc_no
			 , PASSSER_NO
			 , ISSUED
			 , DOCORG
			 , kod_pvs
			 , DateDel
			 , owner_id_old
		FROM #t

	OPEN curs
	FETCH NEXT FROM curs INTO @LAST_NAME, @FIRST_NAME, @SEC_NAME, @STATUS2_ID, @FAM_ID, @BIRTHDATE, @DATEREG, @DateEnd,
	@DOLA_PRIV1, @DOLA_PRIV2, @SEX, @DOCTYPE_ID, @DOC_NO, @PASSSER_NO, @ISSUED, @DOCORG, @KOD_PVS, @DateDel,
	@owner_id_old

	WHILE (@@fetch_status = 0)
	BEGIN
		SELECT @i = @i + 1

		IF @debug = 1
		BEGIN
			PRINT CONCAT(@i,' ',@LAST_NAME,' ',@SEC_NAME,' ',@FIRST_NAME,' из Л/сч: ',@occ_from,' в Л/сч: ', @occ_to)
		--PRINT CAST(@DATEREG AS VARCHAR(20)) + ' - ' + CAST(@DateEnd AS VARCHAR(20))
		END

		SELECT @owner_id=NULL, @people_uid = NULL

		EXECUTE [dbo].[adm_load_people] @OCC = @occ_to
									  , @LAST_NAME = @LAST_NAME
									  , @FIRST_NAME = @FIRST_NAME
									  , @SEC_NAME = @SEC_NAME
									  , @STATUS2_ID = @STATUS2_ID
									  , @FAM_ID = @FAM_ID
									  , @BIRTHDATE = @BIRTHDATE
									  , @DATEREG = @DATEREG
									  , @DateEnd = @DateEnd
									  , @DOLA_PRIV1 = @DOLA_PRIV1
									  , @DOLA_PRIV2 = @DOLA_PRIV2
									  , @SEX = @SEX
									  , @DOCTYPE_ID = @DOCTYPE_ID
									  , @DOC_NO = @DOC_NO
									  , @PASSSER_NO = @PASSSER_NO
									  , @ISSUED = @ISSUED
									  , @DOCORG = @DOCORG
									  , @KOD_PVS = @KOD_PVS
									  , @DateDel = @DateDel
									  , @owner_id = @owner_id OUTPUT
									  , @people_uid = @people_uid OUTPUT
									  , @doc_privat = NULL
									  , @only_fio_join = 0
									  , @comment = @comment1
									  , @debug = @debug

		-- перенос истории проживания
		INSERT INTO dbo.People_2 (owner_id
								, KraiOld
								, RaionOld
								, TownOld
								, VillageOld
								, StreetOld
								, Nom_domOld
								, Nom_kvrOld
								, KraiNew
								, RaionNew
								, TownNew
								, VillageNew
								, StreetNew
								, Nom_domNew
								, Nom_kvrNew
								, KraiBirth
								, RaionBirth
								, TownBirth
								, VillageBirth)
		SELECT @owner_id
			 , KraiOld
			 , RaionOld
			 , TownOld
			 , VillageOld
			 , StreetOld
			 , Nom_domOld
			 , Nom_kvrOld
			 , KraiNew
			 , RaionNew
			 , TownNew
			 , VillageNew
			 , StreetNew
			 , Nom_domNew
			 , Nom_kvrNew
			 , KraiBirth
			 , RaionBirth
			 , TownBirth
			 , VillageBirth
		FROM dbo.People_2 
		WHERE owner_id = @owner_id_old
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.People_2 
				WHERE owner_id = @owner_id_old
			)
		IF @debug = 1
			PRINT '=========================='

		SET @people_add = @people_add + 1

		FETCH NEXT FROM curs INTO @LAST_NAME, @FIRST_NAME, @SEC_NAME, @STATUS2_ID, @FAM_ID, @BIRTHDATE, @DATEREG, @DateEnd,
		@DOLA_PRIV1, @DOLA_PRIV2, @SEX, @DOCTYPE_ID, @DOC_NO, @PASSSER_NO, @ISSUED, @DOCORG, @KOD_PVS, @DateDel,
		@owner_id_old
	END

	CLOSE curs
	DEALLOCATE curs

	--**************************************************************

	DROP TABLE IF EXISTS #t;

	-- выбираем выписанных в первом лицевом, а во 2 нет
	--SELECT p2.id
	UPDATE p2
	SET Del = 1
	  , DateDel = p.DateDel
	  , DateDeath = p.DateDeath
	  , Reason_extract = p.Reason_extract
	  , DateEnd = p.DateEnd
	FROM dbo.People AS p 
		JOIN dbo.People AS p2 ON 
			p.last_name = p2.last_name
			AND p.first_name = p2.first_name
			AND p.second_name = p2.second_name
			AND p.birthdate = p2.birthdate
	WHERE 
		p.Occ = @occ_from
		AND p2.Occ = @occ_to
		AND p.DateDel IS NOT NULL
		AND p2.DateDel IS NULL
	SET @people_del = @@rowcount

END
go

