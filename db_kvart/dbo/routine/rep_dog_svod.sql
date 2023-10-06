CREATE   PROCEDURE [dbo].[rep_dog_svod]
(
	@nrep		SMALLINT	= 1 -- Номер отчета
	,@fin_id	SMALLINT	-- Фин.период
	,@tip		SMALLINT	= NULL -- Тип жилого фонда
	,@sup_id	INT			= NULL -- Поставщик
)
AS
	/*
	--
	--
	--   Вывод сводных отчетов по начислениям
	--   Итоговые значения по районам и участкам
--   1. Нач.Сальдо
--   2. Начислено
--   3. Разовые 
--   4. Льготы
--   5. Субсидии
--   6. Пост. начисления
--   7. Оплата
--   8. Конечное сальдо
--   9. Оплата пени
--   10. Оплата по услугам (без пеней)
	--
	-- дата изменения:	
	-- автор изменения:	Пузанов
	
	отчет: 
	
	*/
	SET NOCOUNT ON

	IF @nrep IS NULL
		SET @nrep = 1
		
	IF @tip IS NULL AND @sup_id IS NULL
		SELECT @tip=0,@sup_id=0

	-- находим значение текущего фин периода  
	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	SELECT
		dog.dog_id
		,p.SERVICE_ID
		,value =
			CASE
				WHEN @nrep = 1 THEN SUM(p.saldo)
				WHEN @nrep = 2 THEN SUM(p.value)
				WHEN @nrep = 3 THEN SUM(p.added)
				WHEN @nrep = 4 THEN SUM(p.discount)
				WHEN @nrep = 5 THEN SUM(p.Compens)
				WHEN @nrep = 6 THEN SUM(p.paid)
				WHEN @nrep = 7 THEN SUM(p.paymaccount)
				WHEN @nrep = 8 THEN SUM(p.debt)
				WHEN @nrep = 9 THEN SUM(p.paymaccount_peny)
				WHEN @nrep = 10 THEN SUM(p.paymaccount_serv)
				ELSE 0
			END
	FROM [dbo].[View_DOG_ALL] AS dog 
		JOIN dbo.View_OCC_ALL_LITE AS o
			ON dog.fin_id = o.fin_id
			AND dog.build_id = o.bldn_id
		JOIN dbo.View_PAYM AS p 
			ON dog.fin_id = p.fin_id
			AND dog.sup_id = p.sup_id
			AND dog.SERVICE_ID = p.SERVICE_ID
			AND o.OCC = p.OCC
		JOIN dbo.View_SERVICES AS s 
			ON p.SERVICE_ID = s.id
	WHERE 1=1
		AND dog.fin_id = @fin_id
		AND o.tip_id = COALESCE(@tip, o.tip_id)
		AND dog.SUP_ID = COALESCE(@sup_id, dog.SUP_ID)
	GROUP BY	dog.dog_id
				,p.SERVICE_ID
	HAVING CASE
		WHEN @nrep = 1 THEN SUM(p.saldo)
		WHEN @nrep = 2 THEN SUM(p.value)
		WHEN @nrep = 3 THEN SUM(p.added)
		WHEN @nrep = 4 THEN SUM(p.discount)
		WHEN @nrep = 5 THEN SUM(p.Compens)
		WHEN @nrep = 6 THEN SUM(p.paid)
		WHEN @nrep = 7 THEN SUM(p.paymaccount)
		WHEN @nrep = 8 THEN SUM(p.debt)
		WHEN @nrep = 9 THEN SUM(p.paymaccount_peny)
		WHEN @nrep = 10 THEN SUM(p.paymaccount_serv)
		ELSE 0
	END <> 0
	OPTION (MAXDOP 1, FAST 10);
go

