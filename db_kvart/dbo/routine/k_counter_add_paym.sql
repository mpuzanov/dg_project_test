CREATE   PROCEDURE [dbo].[k_counter_add_paym]
(
	@occ1		 INT
   ,@service_id1 VARCHAR(10)
   ,@var1		 SMALLINT = 1
)
AS
	/*
	
	
	*/
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @var1 IS NULL
		SET @var1 = 1

	IF @var1 = 1
	BEGIN

		DECLARE @rowcount INT = 1000

		SELECT TOP (@rowcount)
			'Месяц' = gb.start_date
		   ,'Начислено_счётчик' = cp2.value
		   ,'Тариф_счётчик' = cp2.tarif
		   ,'Кол_счётчик' = cp2.kol
		   ,'Оплата_счётчик' = cp2.paymaccount
		   ,'Начислено_норма' = ph.value
		   ,'Разовые_норма' = ph.Added
		   ,'Оплата_норма' = ph.paymaccount
		   ,'Пост.Начисл._норма' = ph.Paid
		   ,'Тариф_норма' = ph.tarif
		   ,'Кол_норма' = ph.kol
		   ,'Разница_начислено' = (cp2.value - cp2.paymaccount) - (COALESCE(ph.value, 0) - COALESCE(ph.paymaccount, 0))
		   ,internal = (SELECT TOP 1
					internal
				FROM [dbo].[View_COUNTER_ALL] AS vc
				WHERE date_del IS NULL
				AND vc.occ = cp2.occ
				AND vc.fin_id = cp2.fin_id
				AND vc.service_id = cp2.service_id)
		FROM dbo.COUNTER_PAYM2 AS cp2
		LEFT JOIN dbo.PAYM_HISTORY AS ph
			ON cp2.occ = ph.occ
			AND cp2.service_id = ph.service_id
			AND cp2.fin_id = ph.fin_id
		JOIN dbo.GLOBAL_VALUES AS gb
			ON cp2.fin_id = gb.fin_id
		WHERE cp2.occ = @occ1
		AND cp2.tip_value = 1
		AND cp2.service_id = @service_id1
		AND cp2.fin_id < @fin_current
		ORDER BY cp2.fin_id DESC

	END

	IF @var1 = 2
	BEGIN
		SELECT
			'Месяц' = gb.start_date
		   ,'Тариф_счётчик' = cp2.tarif
		   ,'Кол_счётчик' = cp2.kol
		   ,'Начислено_счётчик' = cp2.Paid
		   ,'Тариф_льгота' = CAST(cp2.tarif - cp2.tarif * pch.koef_lgota AS DECIMAL(9, 2))
		   ,'Оплата_норма' = COALESCE(pch.paymaccount, 0) + COALESCE(ph.paymaccount, 0)
		   ,'Кол_оплата' = CAST(CASE
				WHEN (COALESCE(pch.paymaccount, 0) + COALESCE(ph.paymaccount, 0)) > 0 AND
				(cp2.tarif - cp2.tarif * pch.koef_lgota) > 0 THEN (COALESCE(pch.paymaccount, 0) + COALESCE(ph.paymaccount, 0)) / (cp2.tarif - cp2.tarif * pch.koef_lgota)
				ELSE 0
			END AS DECIMAL(9, 4))
		   ,'Разница_кол' = cp2.kol - CAST(CASE
				WHEN (COALESCE(pch.paymaccount, 0) + COALESCE(ph.paymaccount, 0)) > 0 AND
				(cp2.tarif - cp2.tarif * pch.koef_lgota) > 0 THEN (COALESCE(pch.paymaccount, 0) + COALESCE(ph.paymaccount, 0)) / (cp2.tarif - cp2.tarif * pch.koef_lgota)
				ELSE 0
			END AS DECIMAL(9, 4))
		   ,internal = (SELECT TOP 1
					internal
				FROM [dbo].[View_COUNTER_ALL] AS vc
				WHERE date_del IS NULL
				AND vc.occ = cp2.occ
				AND vc.fin_id = cp2.fin_id
				AND vc.service_id = cp2.service_id)
		FROM dbo.COUNTER_PAYM2 AS cp2

		LEFT JOIN (SELECT
				occ
			   ,service_id
			   ,fin_id
			   ,Discount
			   ,paymaccount
			   ,value
			   ,koef_lgota = (CASE
					WHEN Discount > 0 AND
					value > 0 THEN Discount / value
					ELSE 0
				END)
			FROM dbo.View_PAYM_COUNTER
			WHERE occ = @occ1
			AND service_id = @service_id1) AS pch
			ON cp2.occ = pch.occ
			AND cp2.service_id = pch.service_id
			AND cp2.fin_id = pch.fin_id

		LEFT JOIN (SELECT
				occ
			   ,service_id
			   ,fin_id
			   ,Discount
			   ,paymaccount
			   ,value
			   ,koef_lgota = (CASE
					WHEN Discount > 0 AND
					value > 0 THEN Discount / value
					ELSE 0
				END)
			FROM dbo.PAYM_HISTORY
			WHERE occ = @occ1
			AND service_id = @service_id1) AS ph
			ON cp2.occ = pch.occ
			AND cp2.service_id = ph.service_id
			AND cp2.fin_id = ph.fin_id
			AND ph.value > 0

		JOIN dbo.GLOBAL_VALUES AS gb
			ON cp2.fin_id = gb.fin_id
		WHERE cp2.occ = @occ1
		AND cp2.tip_value = 1
		AND cp2.service_id = @service_id1
		AND cp2.fin_id < @fin_current
		ORDER BY cp2.fin_id DESC
	END
go

