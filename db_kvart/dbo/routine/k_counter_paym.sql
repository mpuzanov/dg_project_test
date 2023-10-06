CREATE   PROCEDURE [dbo].[k_counter_paym]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL
	, @tip_value1 SMALLINT = 0
	, @par SMALLINT = 0
)
AS
	/*
	
	Показываем начисления по показаниям счетчиков 
	по заданному лицевому счету
	
	Используется DCARD
	
	дата изменеия:	16.01.05	
	добавленно: выбор всех лицевых,дополнительно поле адресса из occupations
	
	Используеться в отчёте: Начисления по показаниям инспектора
	*/
	SET NOCOUNT ON

	DECLARE @rowcount INT = 1000
	IF @fin_id1 IS NULL
		SET @rowcount = 5000

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT TOP (@rowcount) cp1.StrFinPeriod AS strfin
						 , cp.Occ
						 , cp.fin_id
						 , cp.service_id
						 , CASE
							   WHEN cp.saldo = 0 THEN NULL
							   ELSE cp.saldo
						   END AS saldo
						 , CASE
							   WHEN cp.value = 0 THEN NULL
							   ELSE cp.value
						   END AS value
						 , CASE
							   WHEN cp.discount = 0 THEN NULL
							   ELSE cp.discount
						   END AS discount
						 , CASE
							   WHEN cp.added = 0 THEN NULL
							   ELSE cp.added
						   END AS added
						 , CASE
							   WHEN cp.paymaccount = 0 THEN NULL
							   ELSE cp.paymaccount
						   END AS paymaccount
						 , CASE
							   WHEN cp.paid = 0 THEN NULL
							   ELSE cp.paid
						   END AS paid
						 , CASE
							   WHEN cp.debt = 0 THEN NULL
							   ELSE cp.debt
						   END AS debt
						 , s.short_name
						 , o.address
						 , cp.tarif
						 , CASE
							   WHEN cp.kol = 0 THEN NULL
							   ELSE cp.kol
						   END AS kol
						 , vc.internal
						 , CAST(CASE
							   WHEN (cp.paymaccount > 0) AND
								   cp.tarif > 0 THEN COALESCE(cp.paymaccount, 0) / cp.tarif --(cp.tarif-cp.tarif*coalesce(pch.koef_lgota,0))
							   ELSE NULL
						   END AS DECIMAL(9, 4)) AS kol_paymaccount
						 , cp.kol_counter
						 , cp.kol_inspector
						 , CASE cp.metod_rasch
							   WHEN 0 THEN 'не начислять'
							   WHEN 1 THEN 'по норме'
							   WHEN 2 THEN 'по среднему'
							   WHEN 3 THEN 'по счетчику'
							   WHEN 4 THEN 'по домовому'
							   ELSE NULL
						   END AS metod_rasch
	FROM dbo.Counter_paym2 AS cp 
		JOIN dbo.View_services AS s ON cp.service_id = s.id
		JOIN dbo.Occupations AS o ON cp.Occ = o.Occ
		JOIN dbo.Calendar_period cp1 ON cp1.fin_id = cp.fin_id
		CROSS APPLY (
			SELECT TOP 1 internal
			FROM [dbo].[View_counter_all] AS vc 
			WHERE vc.Occ = cp.Occ
				AND vc.fin_id = cp.fin_id
				AND vc.service_id = cp.service_id
				AND vc.date_del IS NULL
		) AS vc
	WHERE cp.Occ = @occ1
		AND cp.tip_value = @tip_value1
		AND cp.fin_id <>
						CASE
							WHEN @par = 1 THEN @fin_current
							ELSE 0
						END
	ORDER BY cp.fin_id DESC
go

