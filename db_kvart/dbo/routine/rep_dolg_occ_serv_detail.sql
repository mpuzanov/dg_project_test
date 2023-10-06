-- =============================================
-- Author:		Пузанов
-- Create date: 04/04/13
-- Description:	
-- =============================================
CREATE   PROCEDURE [dbo].[rep_dolg_occ_serv_detail]
	@P1			SMALLINT -- 1-по всем услугам, 2- по единой, 3- по поставщику  из rep_vibor
	,@occ		INT
	,@fin_id1	SMALLINT
	,@sup_id	INT	= NULL
AS
/*
для отчёта Задолженность по группе (Задолженность по услугам)
в Картотеке

по услугам

exec [rep_dolg_occ_serv_detail] 1,56938,142,null,null
exec [rep_dolg_occ_serv_detail] 1,910000723,142,null
exec [rep_dolg_occ_serv_detail] 2,700066105,146,313

*/
BEGIN
	SET NOCOUNT ON;

	IF @P1 IS NULL
		OR @P1 NOT IN (1, 2, 3)
		SET @P1 = 1
	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	IF 1 = @P1
		SELECT
			p.occ
			,p.fin_id
			,s.Name AS 'Услуга'
			,CAST(p.saldo AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			,CAST(p.value AS DECIMAL(9, 2)) AS 'Начислено'
			,CAST(p.added AS DECIMAL(9, 2)) AS 'Перерасчет'
			,CAST(p.paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			,CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'Оплатил'
			,CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			,CAST(p.debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
		FROM dbo.View_PAYM AS p 
		JOIN dbo.SERVICES AS s
			ON p.service_id = s.id
		WHERE p.occ = @occ
		AND (p.fin_id = @fin_id1)
		AND (p.saldo <> 0
		OR p.value <> 0
		OR p.added <> 0
		OR p.paid <> 0
		OR p.paymaccount <> 0)

	IF 2 = @P1
		SELECT
			p.occ
			,p.fin_id
			,s.Name AS 'Услуга'
			,CAST(p.saldo AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			,CAST(p.value AS DECIMAL(9, 2)) AS 'Начислено'
			,CAST(p.added AS DECIMAL(9, 2)) AS 'Перерасчет'
			,CAST(p.paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			,CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'Оплатил'
			,CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			,CAST(p.debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
		FROM dbo.View_PAYM AS p 
		JOIN dbo.SERVICES AS s 
			ON p.service_id = s.id
		WHERE p.occ = @occ
		--AND (p.fin_id BETWEEN @fin_id1 AND @fin_id2)
		AND p.fin_id = @fin_id1
		AND p.account_one = 0
		AND (p.saldo <> 0
		OR p.value <> 0
		OR p.added <> 0
		OR p.paid <> 0
		OR p.paymaccount <> 0)

	--ORDER BY p.fin_id DESC

	IF 3 = @P1
		SELECT
			occ = os.occ_sup
			,os.fin_id
			,s.Name AS 'Услуга'
			,CAST(p.saldo AS DECIMAL(9, 2)) AS 'Вх.Сальдо'
			,CAST(p.value AS DECIMAL(9, 2)) AS 'Начислено'
			,CAST(p.added AS DECIMAL(9, 2)) AS 'Перерасчет'
			,CAST(p.paid AS DECIMAL(12, 2)) AS 'Итого начисл.'
			,CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'Оплатил'
			,CAST(p.PaymAccount_peny AS DECIMAL(9, 2)) AS 'из них пени'
			,CAST(p.debt AS DECIMAL(9, 2)) AS 'Кон. сальдо'
		FROM dbo.OCC_SUPPLIERS AS os 
		JOIN dbo.View_PAYM AS p 
			ON p.occ = os.occ
			AND p.fin_id = os.fin_id
			AND p.sup_id=os.sup_id
		JOIN dbo.SERVICES AS s 
			ON p.service_id = s.id
		WHERE --os.occ_sup=@occ
		os.occ = @occ
		AND (os.sup_id = @sup_id OR @sup_id IS NULL)
		AND (os.fin_id = @fin_id1)
		AND p.account_one = 1
		AND (p.saldo <> 0
		OR p.value <> 0
		OR p.added <> 0
		OR p.paid <> 0
		OR p.paymaccount <> 0
		OR p.debt <> 0)

	--ORDER BY p.fin_id DESC


END
go

