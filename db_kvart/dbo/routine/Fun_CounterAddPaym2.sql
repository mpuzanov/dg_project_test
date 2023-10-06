-- =============================================
-- Author:		Пузанов
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         FUNCTION [dbo].[Fun_CounterAddPaym2]
(
	@flat_id1		INT
	,@service_id1	VARCHAR(10)
)
RETURNS @tbl TABLE
(
	occ				INT
	,kol_added		DECIMAL(9, 4)
	,tarif			DECIMAL(9, 4)
	,value_added	DECIMAL(9, 2)
	,first_internal	BIT
)
AS
BEGIN
	DECLARE	@fin_current		SMALLINT
			,@tarif				DECIMAL(9, 4)
			,@first_internal	BIT	= 0
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, @flat_id1, NULL)

	DECLARE @t1 TABLE
		(
			fin_id			SMALLINT
			,occ			INT
			,tarif			DECIMAL(9, 4)
			,Paid			DECIMAL(9, 2)
			,Paymaccount	DECIMAL(9, 2)
			,Kol			DECIMAL(9, 4)
			,Kol_add		DECIMAL(9, 4)
			,internal		BIT
			,counter_value	DECIMAL(9, 2)
			,counter_id		INT
		)

	INSERT INTO @t1
	(	fin_id
		,occ
		,tarif
		,Paid
		,Paymaccount
		,Kol
		,Kol_add
		,internal
		,counter_value
		,counter_id)
		SELECT
			cp2.fin_id
			,cp2.occ
			,cp2.tarif AS 'Тариф_счётчик'
			,COALESCE(cp2.Paid, 0) + COALESCE(ph.value, 0) AS 'Начислено_счётчик'
			,COALESCE(pch.Paymaccount, 0) + COALESCE(ph.Paymaccount, 0) AS 'Оплата_норма'
			,CAST(CASE
				WHEN (pch.Paymaccount > 0 OR ph.Paymaccount > 0) AND cp2.tarif > 0 
					THEN (COALESCE(pch.Paymaccount, 0) + COALESCE(ph.Paymaccount, 0)) / 
						(cp2.tarif - (cp2.tarif * CAST(COALESCE(pch.koef_lgota,0) AS DECIMAL(9, 4))) )
				ELSE 0
			END AS DECIMAL(9, 4)
			) AS 'Кол_оплата'
			,cp2.Kol - CAST(CASE
				WHEN (pch.Paymaccount > 0 OR ph.Paymaccount > 0) AND cp2.tarif > 0 
					THEN (COALESCE(pch.Paymaccount, 0) + COALESCE(ph.Paymaccount, 0)) / 
						(cp2.tarif - (cp2.tarif * CAST(COALESCE(pch.koef_lgota,0) AS DECIMAL(9, 4))) ) 
				ELSE 0
			END AS DECIMAL(9, 4)) AS 'Разница_кол'
			, (SELECT TOP 1
					internal
				FROM [dbo].[View_counter_all] AS vc
				WHERE date_del IS NULL
					AND vc.occ = cp2.occ
					AND vc.fin_id = cp2.fin_id
					AND vc.service_id = cp2.service_id
				) AS internal
			,pch.value
			,(SELECT TOP 1
					counter_id
				FROM [dbo].[View_counter_all] AS vc
				WHERE date_del IS NULL
				AND vc.occ = cp2.occ
				AND vc.fin_id = cp2.fin_id
				AND vc.service_id = cp2.service_id
				) AS counter_id
		FROM dbo.Counter_paym2 AS cp2 

		LEFT JOIN (SELECT
				pch.occ
				,pch.service_id
				,pch.fin_id
				,pch.discount
				,pch.value
				,pch.Paymaccount
				,koef_lgota =
					CASE
						WHEN pch.discount > 0 AND pch.value > 0 THEN pch.discount / pch.value ELSE 0
					END
			FROM dbo.View_paym_counter AS pch 
			JOIN dbo.Occupations AS o 
				ON pch.occ = o.occ
			WHERE pch.occ = o.occ
				AND service_id = @service_id1
				AND o.flat_id = @flat_id1
			) AS pch
			ON cp2.occ = pch.occ 
				AND cp2.service_id = pch.service_id 
				AND cp2.fin_id = pch.fin_id

		LEFT JOIN (SELECT
				ph.occ
				,ph.service_id
				,ph.fin_id
				,ph.discount
				,ph.value
				,ph.Paymaccount
				,koef_lgota =
					CASE
						WHEN ph.discount > 0 AND ph.value > 0 THEN ph.discount / ph.value ELSE 0
					END
			FROM dbo.Paym_history AS ph 
			JOIN dbo.Occupations AS o 
				ON ph.occ = o.occ
			WHERE ph.occ = o.occ
				AND service_id = @service_id1
				AND o.flat_id = @flat_id1
				AND ph.value > 0
				AND ph.fin_id > 107
				AND ph.is_counter = 2
				) AS ph
			ON cp2.occ = ph.occ 
				AND cp2.service_id = ph.service_id 
				AND cp2.fin_id = ph.fin_id

		JOIN dbo.OCCUPATIONS AS o ON 
			cp2.occ = o.occ

		WHERE 
			o.flat_id = @flat_id1
			AND cp2.tip_value = 1
			AND cp2.service_id = @service_id1
	
	--SELECT TOP 1 @first_internal=internal FROM @t1 WHERE fin_id=@fin_current

	DECLARE @counter_id1 INT
	SELECT TOP 1
		@counter_id1 = counter_id
	FROM @t1
	WHERE counter_id IS NOT NULL

	SELECT
		@tarif = dbo.Fun_GetCounterTarf(@fin_current, @counter_id1, NULL);


	IF EXISTS (SELECT
				1
			FROM dbo.Counters AS c 
			JOIN dbo.Counter_inspector AS ci ON 
				c.id = ci.counter_id
			JOIN dbo.Counter_list_all AS cl ON 
				c.id = cl.counter_id 
				AND ci.fin_id = cl.fin_id
			WHERE 
				c.flat_id = @flat_id1
				AND c.service_id = @service_id1
				AND ci.fin_id < @fin_current
				AND cl.internal = 1
			)
		SET @first_internal = 0
	ELSE
		SET @first_internal = 1


	INSERT @tbl
	(	occ
		,kol_added
		,tarif
		,value_added
		,first_internal)
		SELECT
			occ
			,CASE
				WHEN @tarif > 0 THEN (SUM(COALESCE(Paid, 0) - COALESCE(Paymaccount, 0)) / @tarif) ELSE SUM(COALESCE(Kol_add, 0))
			END
			AS kol_added
			,@tarif AS tarif
			,CAST(SUM(COALESCE(Paid, 0) - COALESCE(Paymaccount, 0)) AS DECIMAL(9, 2)) AS value_added
			,@first_internal
		FROM @t1
		WHERE fin_id < @fin_current
		GROUP BY occ

	RETURN
END
go

