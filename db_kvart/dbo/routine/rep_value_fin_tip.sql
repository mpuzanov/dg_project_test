-- =============================================
-- Author:		Пузанов
-- Create date: 02.03.2023
-- Description:	Оборотка по услугам по типу фонда
-- =============================================
CREATE       PROCEDURE [dbo].[rep_value_fin_tip]
(
	@tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @tip_str VARCHAR(2000) = NULL -- список типов фонда через запятую
	, @debug BIT = NULL
)
AS
/*
exec rep_value_fin_tip @fin_id1=250, @tip_id=131, @fin_id2=251, @tip_str='2,7', @debug=1
exec rep_value_fin_tip @fin_id1=239,@tip_id=1, @sup_id=345
exec rep_value_fin_tip @fin_id1=252, @tip_id=Null, @tip_str='28,29'
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 < 0
		SELECT @fin_id1 = @fin_current
			 , @fin_id2 = @fin_current
	ELSE
	IF @fin_id1 IS NULL
		--AND @tip_id IS NOT NULL
		SET @fin_id1 = @fin_current - 1

	IF @fin_id2 IS NULL
		OR @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1


	IF @tip_id IS NULL
		AND @build_id IS NULL
		SET @tip_id = -1

	IF COALESCE(@tip_str, '') = ''
		AND COALESCE(@tip_str, '') = ''
		AND @tip_id IS NULL
		SELECT @tip_str = STUFF((
				SELECT ',' + LTRIM(STR(b.tip_id))
				FROM View_build_all b
				WHERE b.fin_id BETWEEN @fin_id1 AND @fin_id2
					AND (b.build_id = @build_id OR @build_id IS NULL)
					AND (b.tip_id = @tip_id OR @tip_id IS NULL)
				GROUP BY b.tip_id
				FOR XML PATH ('')
			), 1, 1, '')

	-- для ограничения доступа услуг
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #services (id
						 , name)
	SELECT vs.id
		 , vs.name
	FROM dbo.View_services AS vs	

	CREATE UNIQUE INDEX SERV ON #services (id)


	--REGION Таблица со значениями Типа жил.фонда *********************
	DECLARE @tip_table TABLE (tip_id SMALLINT DEFAULT NULL PRIMARY KEY)

	INSERT INTO @tip_table
	SELECT CASE
               WHEN Value = 'Null' THEN NULL
               ELSE Value
               END
	FROM STRING_SPLIT(@tip_str, ',')
	WHERE RTRIM(Value) <> ''

	IF @tip_id IS NOT NULL
	BEGIN
		INSERT INTO @tip_table
		SELECT id
		FROM dbo.VOcc_types
		WHERE id = @tip_id
			AND NOT EXISTS (
				SELECT 1
				FROM @tip_table
				WHERE tip_id = @tip_id
			)
	END
	IF @debug = 1
		SELECT *
		FROM @tip_table
	--ENDREGION ************************************************************


	SELECT pl.fin_id
	  , MIN(o.[start_date])           AS [start_date]
	  , o.tip_name
	  , pl.service_id                                     -- код услуги
	  , CASE
            WHEN COALESCE(MIN(servt.service_name_full), '') = '' THEN MIN(serv.name)
            ELSE MIN(servt.service_name_full)
        END                           AS serv_name        -- заменяем наименования услуг по типам фонда
	  , MIN(s_kvit.service_name_kvit) AS serv_name_kvit
	  , MIN(sup.name)                 AS sup_name
	  , SUM(pl.saldo)                 AS saldo
	  , SUM(pl.value)                 AS value
	  , SUM(pl.added)                 AS added
	  , SUM(pl.paid)                  AS paid             -- пост.начисления (value-discount+added)
	  , SUM(pl.paymaccount)           AS paymaccount
	  , SUM(pl.paymaccount_peny)      AS paymaccount_peny
	  , SUM(pl.paymaccount_serv)      AS paymaccount_serv -- Оплачено по услуге (без пени)
	  , SUM(pl.debt)                  AS debt
	  , SUM(o.kol_people) AS kol_people
	  , SUM(pl.kol) AS kol
	  , SUM(pl.kol_added) AS kol_added
	  , CASE
            WHEN COALESCE(MAX(pl.metod), 1) NOT IN (3, 4) THEN SUM(pl.kol)
            ELSE 0
        END AS kol_norma
	  , CASE
            WHEN MAX(pl.metod) = 3 THEN SUM(pl.kol)
            ELSE 0
        END AS kol_ipu
	  , CASE
            WHEN MAX(pl.metod) = 4 THEN SUM(pl.kol)
            ELSE 0
        END AS kol_opu
	  , SUM(pl.penalty_prev) AS penalty_prev
	  , SUM(pl.penalty_old) AS penalty_old
	  , SUM(pl.penalty_serv) AS penalty_serv
	  , SUM(pl.penalty_old + pl.penalty_serv) AS penalty_itog
	  , SUM(ROUND(pl.SALDO, 2) + pl.penalty_old + pl.PaymAccount_peny) AS saldo_with_peny
	  , SUM(ROUND(pl.Debt, 2) + pl.penalty_old + pl.penalty_serv) AS debt_with_peny	  	  
	FROM @tip_table tt
		JOIN dbo.View_occ_all_lite AS o ON o.tip_id=tt.tip_id			
		JOIN dbo.View_paym AS pl ON o.occ = pl.occ
			AND o.fin_id = pl.fin_id
			AND (pl.sup_id = @sup_id OR @sup_id IS NULL)		
		JOIN #services AS serv ON pl.service_id = serv.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit ON o.tip_id = s_kvit.tip_id
			AND o.build_id = s_kvit.build_id
			AND pl.service_id = s_kvit.service_id
		LEFT JOIN dbo.Services_types AS servt ON servt.service_id = serv.id
			AND servt.tip_id = o.tip_id
		LEFT JOIN dbo.Suppliers_all AS sup ON pl.sup_id = sup.id
		LEFT JOIN dbo.Property_types AS PT ON o.proptype_id = PT.id
		LEFT JOIN dbo.Room_types AS RT ON o.roomtype_id = RT.id
	WHERE pl.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (pl.build_id = @build_id OR @build_id IS NULL)
		AND (pl.saldo <> 0 OR pl.value <> 0 OR pl.debt <> 0 OR pl.added <> 0 OR pl.kol <> 0 OR pl.paymaccount <> 0)
	GROUP BY pl.fin_id
		   , o.tip_name
		   , pl.service_id -- код услуги
	ORDER BY pl.fin_id
		   , o.tip_name
	--	   --, pl.service_id
	OPTION (RECOMPILE)
END
go

