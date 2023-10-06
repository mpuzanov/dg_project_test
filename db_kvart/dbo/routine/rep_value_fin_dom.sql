-- =============================================
-- Author:		Пузанов
-- Create date: 24.10.2008
-- Description:	Оборотка по услугам с учётом ОПУ
-- =============================================
CREATE           PROCEDURE [dbo].[rep_value_fin_dom]
(
    @fin_id1    SMALLINT,
    @tip_id1    SMALLINT   = NULL,
    @build_id1  INT        = NULL,
    @div_id1    SMALLINT   = NULL,
    @service_id VARCHAR(10)= NULL,
    @sup_id     INT        = NULL,
    @town_id    SMALLINT   = NULL
)
AS
/*
rep_value_fin_dom @fin_id1=198, @tip_id1=28, @sup_id=323
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)

	IF @tip_id1 IS NULL AND @build_id1 IS NULL AND @div_id1 IS NULL AND @town_id IS NULL
		SET @tip_id1 = 0

	-- для ограничения доступа услуг
	CREATE TABLE #s(
		id	 VARCHAR(10) COLLATE database_default PRIMARY KEY,
		[name] VARCHAR(100) COLLATE database_default,
		is_build BIT
	)
	INSERT INTO #s (id
				  , name
				  , is_build)
	SELECT id
		 , name
		 , is_build
	FROM View_services
	WHERE (id = @service_id or @service_id is null)

    SELECT 
		 occ=CASE 
		 WHEN pl.account_one=1 THEN cl.occ_serv
		 ELSE pl.occ
		 END, 
		 pl.service_id,
		 --serv.name AS serv_name,
        CASE
            WHEN servt.service_name_full is NULL THEN serv.name
            ELSE servt.service_name_full
            END AS serv_name, -- заменяем наименования услуг по типам фонда
		 pl.tarif,
		 pl.saldo,
		 pl.value,
		 pl.discount,
		 pl.added,
		 cast(pl.paid AS DECIMAL(10, 4)) as paid,
		 pl.paymaccount,
		 pl.paymaccount_peny,
		 pl.paymaccount_serv, 
		 pl.debt,
		 s.name AS street
         , b.nom_dom
         , o.nom_kvr
         , b.bldn_id
         , cl.occ_serv
         , o.kol_people
         , kol_people_serv=dbo.Fun_GetKolPeopleOccServ(pl.fin_id, pl.occ, pl.service_id)
         , pl.kol
         , pl.unit_id
         , metod = CASE
			   WHEN pl.metod = 0 THEN
				   'не начислять'
			   WHEN pl.metod = 2 THEN
				   'по среднему'
			   WHEN pl.metod = 3 THEN
				   'по счетчику'
			   WHEN pl.metod = 4 THEN
				   'по домовому'
			   WHEN pl.is_counter > 0 THEN
				   'по норме'
			   ELSE
				   NULL
		   END
         , kol_norma = CASE
			   WHEN coalesce(pl.metod, 1) IN (1,4) THEN --NOT IN (2,3,4) THEN
				   coalesce(pl.kol,0)
			   ELSE
				   0
		   END
         , kol_ipu = CASE
			   WHEN pl.metod in (2,3) THEN
				   coalesce(pl.kol,0)
			   ELSE
				   0
		   END
         , kol_opu = coalesce(pl2.kol,0)
         , kol_itog= pl.kol+coalesce(pl2.kol,0)
         , paid_opu = coalesce(pl2.paid,0)
         , value_itog= pl.value+coalesce(pl2.value,0)
         , added_itog= pl.added+coalesce(pl2.added,0)
         , paid_itog= pl.paid+coalesce(pl2.paid,0)
         , saldo_itog= pl.saldo+coalesce(pl2.saldo,0)
         , debt_itog= pl.debt+coalesce(pl2.debt,0)
         , paym_itog= pl.paymaccount_serv+coalesce(pl2.paymaccount_serv,0)
         , paym_itog_all= pl.paymaccount+coalesce(pl2.paymaccount,0)
         , paym_itog_peny= pl.paymaccount_peny+coalesce(pl2.paymaccount_peny,0)
         , o.total_sq
	FROM dbo.View_OCC_ALL AS o 
		JOIN dbo.View_PAYM AS pl 
			ON o.occ = pl.occ AND o.fin_id = pl.fin_id
			AND COALESCE(pl.sup_id, 0) = COALESCE(@sup_id, COALESCE(pl.sup_id, 0))
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id AND o.fin_id = b.fin_id
		JOIN dbo.VSTREETS AS s 
			ON b.street_id = s.id
		JOIN #s AS serv
			ON pl.service_id = serv.id
		LEFT JOIN dbo.Services_types as servt ON servt.service_id=serv.id
			AND servt.tip_id = o.tip_id
		LEFT JOIN dbo.SERVICES S2 
			ON pl.service_id=S2.is_build_serv
		LEFT JOIN dbo.View_PAYM AS pl2 
			ON pl.occ = pl2.occ AND pl.fin_id = pl2.fin_id AND S2.id=pl2.service_id
		LEFT JOIN dbo.CONSMODES_LIST AS cl 
			ON pl.occ = cl.occ AND pl.service_id = cl.service_id
		--LEFT JOIN dbo.View_SUPPLIERS AS vs
		--	ON vs.service_id = serv.id AND vs.id = cl.source_id AND vs.sup_id = coalesce(@sup_id, vs.sup_id)
	WHERE pl.fin_id = @fin_id1
		AND o.fin_id = @fin_id1
		AND serv.is_build=0
		AND (b.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL)
		AND b.div_id = coalesce(@div_id1, b.div_id)
		--AND vs.sup_id = coalesce(@sup_id, vs.sup_id)
		AND (b.town_id = @town_id OR @town_id IS NULL)
		AND (pl.saldo <> 0
		OR pl.value <> 0
		OR pl.debt <> 0
		OR pl.added <> 0
		OR pl.kol <> 0
		OR coalesce(pl2.kol,0)<>0
		OR coalesce(pl2.added,0)<>0
		OR coalesce(pl2.saldo,0)<>0
		OR coalesce(pl2.debt,0)<>0)
	ORDER BY s.name
		   , b.nom_dom_sort
		   , o.nom_kvr_sort
END
go

