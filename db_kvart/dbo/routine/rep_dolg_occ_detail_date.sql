-- =============================================
-- Author:		Пузанов
-- Create date: 19/03/15
-- Description:	
-- =============================================
CREATE           PROCEDURE [dbo].[rep_dolg_occ_detail_date]
	@P1			SMALLINT  -- 1-по всем услугам, 2- по единой, 3- по поставщику  из rep_vibor
	,@occ		INT
	,@fin_id1	SMALLINT
	,@sup_id	INT	= NULL
	,@date1		SMALLDATETIME
	,@date2		SMALLDATETIME
	,@debug		BIT	= NULL
	,@blocked_payment BIT = 0  -- не использовать в отчёте оплате
AS
/*
для отчёта Задолженность по группе (Задолженность по услугам)
в Картотеке

по услугам

exec [rep_dolg_occ_detail_date] 2,680002998,182,323, '20170301','20170320',0
exec [rep_dolg_occ_detail_date] 2,680002998,182,347, '20170301','20170320',0
exec [rep_dolg_occ_detail_date] 3,680002998,182,323, '20170301','20170320',0

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@tip_id			SMALLINT
			,@kol_people	SMALLINT
			,@rooms			SMALLINT
			,@build_id		INT
			,@koefDay		DECIMAL(10, 4)

	IF @P1 IS NULL
		OR @P1 NOT IN (1, 2, 3)
		SET @P1 = 1
	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	SELECT
		@tip_id = voa.tip_id
		,@kol_people = voa.kol_people
		,@build_id = voa.bldn_id
	FROM dbo.View_OCC_ALL_LITE AS voa 
	WHERE voa.occ = @occ
	AND voa.fin_id = @fin_id1

	SELECT
		@rooms = COALESCE(o.rooms, 0)
	FROM dbo.OCCUPATIONS AS o 
	WHERE o.occ = @occ

	SELECT
		@koefDay = dbo.Fun_GetKoefDay_FinPeriod(@date1, @date2, @fin_id1)

	IF @debug = 1
		SELECT
			@tip_id AS tip_id
			,@kol_people AS kol_people
			,@build_id AS build_id
			,@rooms AS rooms

	CREATE TABLE #paym_list1
	(
		occ					INT
		,fin_id				SMALLINT
		,service_id			VARCHAR(10)		COLLATE database_default
		,serv_name			VARCHAR(100)	COLLATE database_default
		,sort_no			SMALLINT		DEFAULT 100
		,unit_id			VARCHAR(10)		COLLATE database_default DEFAULT ''
		,tarif				DECIMAL(10, 4)	DEFAULT 0
		,kol				DECIMAL(12, 6)	DEFAULT 0
		,saldo				DECIMAL(9, 2)	NOT NULL DEFAULT 0
		,value				DECIMAL(9, 2)	NOT NULL DEFAULT 0
		,added				DECIMAL(9, 2)	NOT NULL DEFAULT 0
		,paymaccount		DECIMAL(9, 2)	NOT NULL DEFAULT 0
		,paymaccount_peny	DECIMAL(9, 2)	NOT NULL DEFAULT 0
		,paid				DECIMAL(9, 2)	DEFAULT 0
		,debt				DECIMAL(9, 2)	DEFAULT 0
		,metod				TINYINT			DEFAULT 1
		,mode_id			INT				DEFAULT NULL
		,is_counter			TINYINT			DEFAULT 0
		,norma				DECIMAL(12, 6)	DEFAULT 0
	--,PRIMARY KEY (occ, service_id)
	)


	IF 1 = @P1
		INSERT
		INTO #paym_list1
		(	occ
			,fin_id
			,service_id
			,unit_id
			,tarif
			,kol
			,saldo
			,value
			,added
			,paid
			,paymaccount
			,paymaccount_peny
			,debt
			,metod
			,mode_id
			,is_counter
			,norma)
			SELECT
				p.occ
				,p.fin_id
				,p.service_id
				,p.unit_id
				,p.tarif
				,p.kol
				,p.saldo
				,p.value
				,p.added
				,p.paid
				,p.paymaccount
				,p.paymaccount_peny
				,p.debt
				,COALESCE(p.metod, 0)
				,p.mode_id
				,CASE
					WHEN p.is_counter > 0 THEN 1
					ELSE 0
				END
				,p.kol_norma_single
			FROM dbo.View_PAYM AS p 
			WHERE p.occ = @occ
			AND (p.fin_id = @fin_id1)
			AND (p.saldo <> 0
			OR p.value <> 0
			OR p.added <> 0
			OR p.paid <> 0
			OR p.paymaccount <> 0
			OR p.kol <> 0
			)

	IF 2 = @P1
		INSERT
		INTO #paym_list1
		(	occ
			,fin_id
			,service_id
			,unit_id
			,tarif
			,kol
			,saldo
			,value
			,added
			,paid
			,paymaccount
			,paymaccount_peny
			,debt
			,metod
			,mode_id
			,is_counter
			,norma)
			SELECT
				p.occ
				,p.fin_id
				,p.service_id
				,p.unit_id
				,p.tarif
				,p.kol
				,p.saldo
				,p.value
				,p.added
				,p.paid
				,p.paymaccount
				,p.paymaccount_peny
				,p.debt
				,COALESCE(p.metod, 0)
				,p.mode_id
				,CASE
					WHEN p.is_counter > 0 THEN 1
					ELSE 0
				END
				,p.kol_norma_single
			FROM dbo.View_PAYM AS p 
			WHERE p.occ = @occ
			AND p.fin_id = @fin_id1
			AND p.account_one = 0
			AND (p.saldo <> 0
			OR p.value <> 0
			OR p.added <> 0
			OR p.paid <> 0
			OR p.paymaccount <> 0)

	IF 3 = @P1
		INSERT
		INTO #paym_list1
		(	occ
			,fin_id
			,service_id
			,unit_id
			,tarif
			,kol
			,saldo
			,value
			,added
			,paid
			,paymaccount
			,paymaccount_peny
			,debt
			,metod
			,mode_id
			,is_counter
			,norma)
			SELECT
				occ = os.occ_sup
				,os.fin_id
				,p.service_id
				,p.unit_id
				,p.tarif
				,p.kol
				,p.saldo
				,p.value
				,p.added
				,p.paid
				,p.paymaccount
				,p.paymaccount_peny
				,p.debt
				,COALESCE(p.metod, 0)
				,p.mode_id
				,CASE
					WHEN p.is_counter > 0 THEN 1
					ELSE 0
				END
				,p.kol_norma_single
			FROM dbo.OCC_SUPPLIERS AS os 
			JOIN dbo.View_PAYM AS p 
				ON p.occ = os.occ
				AND p.fin_id = os.fin_id
				AND p.sup_id = os.sup_id
			WHERE --os.occ_sup=@occ
			os.occ = @occ
			AND (os.sup_id = @sup_id OR @sup_id IS NULL)
			AND (os.fin_id = @fin_id1)
			AND p.account_one = 1
			AND (p.saldo <> 0
			OR p.value <> 0
			OR p.added <> 0
			OR p.paid <> 0
			OR p.paymaccount <> 0)


	DELETE FROM #paym_list1
    WHERE kol <> 0 AND value = 0 AND paid = 0 AND saldo = 0
    AND service_id NOT IN ('гвод','гвс2')

	if @blocked_payment=1
		UPDATE p 
		SET paymaccount=0, paymaccount_peny=0
		FROM #paym_list1 AS p;

	UPDATE p
	SET	serv_name	= S.name
		,sort_no	= S.sort_no
		,norma		=
			CASE
				WHEN p.value = 0 THEN 0
				WHEN metod IN (2, 3, 4) THEN 0
				WHEN p.service_id IN ('отоп', 'ото2') THEN (SELECT TOP 1
						vba.norma_gkal
					FROM dbo.View_BUILD_ALL AS vba 
					WHERE vba.bldn_id = @build_id
					AND vba.fin_id = @fin_id1)
				WHEN p.norma>0 THEN p.norma
				WHEN p.unit_id IN ('кубм') AND
				(p.service_id NOT IN ('вотв', 'вот2', 'хвсд', 'хв2д')) THEN [dbo].[Fun_GetNormaSingle](p.unit_id, p.mode_id, 1, @tip_id, p.fin_id)  --p.is_counter
				WHEN p.unit_id IN ('кубм') THEN [dbo].[Fun_GetNormaSingle](p.unit_id, p.mode_id, p.is_counter, @tip_id, p.fin_id)
				--WHEN p.unit_id IN ('квтч') THEN [dbo].[Fun_GetNormaSingleEE](@occ,p.fin_id,p.mode_id,@rooms,@kol_people)
				ELSE 0
			END
	FROM #paym_list1 AS p
	JOIN dbo.SERVICES AS S 
		ON p.service_id = S.id

	UPDATE p
	SET serv_name = S.service_name
	FROM #paym_list1 AS p
	JOIN dbo.[SERVICES_TYPES] AS S
		ON p.service_id = S.service_id
	WHERE S.tip_id = @tip_id

	UPDATE p
	SET	serv_name	= S2.service_name
		,sort_no	= 1
		,metod		= 0
		,service_id	= ''
	FROM #paym_list1 AS p
	JOIN dbo.[SERVICES_TYPES] AS S 
		ON p.service_id = S.service_id
	JOIN dbo.[SERVICES_TYPES] AS S2 
		ON S.owner_id = S2.id
	WHERE S.tip_id = @tip_id

	DELETE FROM #paym_list1 WHERE value=0 AND kol=0 AND added=0 --AND saldo = 0

	IF @debug = 1
		SELECT
			*
		FROM #paym_list1

	SELECT
		serv_name AS 'Услуга'
		,sort_no
		,u.short_id AS 'Ед.изм.'
		,CASE --[dbo].[Fun_GetMetodText]
			WHEN SUM(value) = 0 AND (sort_no<>1) THEN ''
			WHEN p.service_id IN ('вотв', 'вот2') THEN 'сум. ХВС,ГВС'
			WHEN p.serv_name IN ('Водоотведение') THEN 'сум. ХВС,ГВС'
			WHEN metod = 1 THEN 'по норме'
			WHEN metod = 2 THEN 'по среднему'
			WHEN metod = 3 THEN 'по ИПУ'
			WHEN metod = 4 THEN 'по ОПУ'
			WHEN u.short_id = 'м2' THEN 'на площадь'
			WHEN u.short_id = 'ед' THEN 'тариф'
			WHEN metod = 0 AND
			SUM(COALESCE(p.norma,0)) > 0 THEN 'по норме'
			ELSE ''
		END AS 'Метод'
		,CASE
				WHEN SUM(added) <> 0 AND
				p.service_id <> '' THEN [dbo].[Fun_GetAddStrServ](@occ, @fin_id1, p.service_id)
				WHEN SUM(added) <> 0 AND
				p.service_id = '' THEN [dbo].[Fun_GetAddStrServ](@occ, @fin_id1, NULL)
				WHEN metod = 4 THEN COALESCE((SELECT TOP 1
						REPLACE(pcb.comments, 'Ф11:', '')
					FROM dbo.[PAYM_OCC_BUILD] pcb 
					WHERE pcb.fin_id = @fin_id1
					AND pcb.occ = @occ
					AND pcb.service_id = p.service_id
					AND pcb.value<>0
					)
				, '')
				ELSE ''
		END AS StrAdd
		,SUM(t.V1) AS opu_v1
		,SUM(t.V2) AS opu_v2
		,SUM(COALESCE(p.norma,0)) AS norma
		,CASE
					WHEN short_id = 'м2' THEN SUM(tarif)
					ELSE AVG(tarif)
				END AS 'Тариф'
		,CASE
				WHEN u.short_id = 'м2' THEN AVG(kol)
				ELSE ROUND(SUM(kol), 4)
			END AS 'Кол-во'
		,SUM(saldo) AS 'Вх.Сальдо'
		,SUM(value*@koefDay) AS 'Начислено'
		,SUM(added) AS 'Перерасчет'
		,SUM((value*@koefDay)+added) AS 'Итого начисл.'
		,SUM(paymaccount) AS 'Оплатил'
		,SUM(paymaccount_peny) AS 'из них пени'
		,SUM(saldo+((value*@koefDay)+added)-(paymaccount-paymaccount_peny)) AS 'Кон. сальдо'
	FROM #paym_list1 p
	LEFT JOIN dbo.UNITS AS u 
		ON p.unit_id = u.id
	LEFT JOIN (SELECT
			service_id
			,V1
			,V2
			,V3
		FROM dbo.CounterHouse 
		WHERE fin_id = @fin_id1
		AND tip_id = @tip_id
		AND build_id = @build_id) AS t
		ON p.service_id = t.service_id
	GROUP BY	serv_name
				,p.service_id
				,p.sort_no
				,u.short_id
				,p.metod
	ORDER BY sort_no

END
go

