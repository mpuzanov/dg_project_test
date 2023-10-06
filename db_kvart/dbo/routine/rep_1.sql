CREATE   PROCEDURE [dbo].[rep_1]
-- Ведомость начислений
(
	@nrep		 SMALLINT -- Номер отчета
   ,@fin_id		 SMALLINT -- Фин.период
   ,@tip_id		 SMALLINT -- тип жилого фонда
   ,@div_id		 SMALLINT = NULL
   ,@build_id	 INT	  = NULL
   ,@tip_counter SMALLINT = NULL -- тип счетчика
   ,@sup_id		 INT	  = NULL -- поставщик
   ,@town_id	 SMALLINT = NULL
)
AS
	/*
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

rep_1 @nrep=1,@fin_id=250,@tip_id=2
rep_1 @nrep=1,@fin_id=250,@tip_id=1,@sup_id=345

-- дата изменения:	9/04/09
-- автор изменения:	Пузанов

отчет: rep1.fr3

*/
	SET NOCOUNT ON

	IF @nrep IS NULL
		SELECT
			@nrep = 1
		   ,@tip_id = 0

	IF @tip_id IS NULL
		AND @div_id IS NULL
		AND @build_id IS NULL
		AND @sup_id IS NULL
		AND @town_id IS NULL
		SET @tip_id = 0

	-- находим значение текущего фин периода  
	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	SELECT
		CASE WHEN(@sup_id>0) THEN MIN(P.occ_sup_paym) ELSE p.occ END AS occ
	   ,s.name
	   ,CASE
			WHEN @nrep = 1 THEN SUM(p.saldo)
			WHEN @nrep = 2 THEN SUM(p.value)
			WHEN @nrep = 3 THEN SUM(p.added)
			WHEN @nrep = 4 THEN SUM(p.Discount)
			WHEN @nrep = 5 THEN SUM(p.Compens)
			WHEN @nrep = 6 THEN SUM(p.paid)
			WHEN @nrep = 7 THEN SUM(p.paymaccount)
			WHEN @nrep = 8 THEN SUM(p.debt)
			WHEN @nrep = 9 THEN SUM(p.paymaccount_peny)
			WHEN @nrep = 10 THEN SUM(p.paymaccount - p.paymaccount_peny)
			ELSE 0
		END AS 'value'
	FROM dbo.View_PAYM AS p
	JOIN dbo.View_OCC_ALL_LITE AS oh
		ON p.occ = oh.occ
		AND p.fin_id = oh.fin_id
	JOIN dbo.View_services AS s
		ON p.service_id = s.Id
	JOIN dbo.BUILDINGS AS b
		ON oh.bldn_id = b.Id
	WHERE 1=1
		AND p.fin_id = @fin_id AND oh.fin_id = @fin_id
		AND (@tip_id IS NULL OR oh.tip_id = @tip_id)
		AND (@div_id IS NULL OR b.div_id = @div_id)
		AND (@build_id IS NULL OR oh.bldn_id = @build_id)
		AND (@town_id IS NULL OR b.town_id = @town_id)
		AND (@sup_id IS NULL OR p.sup_id = @sup_id)
	GROUP BY p.occ
			,s.name
	HAVING CASE
		WHEN @nrep = 1 THEN SUM(p.saldo)
		WHEN @nrep = 2 THEN SUM(p.value)
		WHEN @nrep = 3 THEN SUM(p.added)
		WHEN @nrep = 4 THEN SUM(p.Discount)
		WHEN @nrep = 5 THEN SUM(p.Compens)
		WHEN @nrep = 6 THEN SUM(p.paid)
		WHEN @nrep = 7 THEN SUM(p.paymaccount)
		WHEN @nrep = 8 THEN SUM(p.debt)
		WHEN @nrep = 9 THEN SUM(p.paymaccount_peny)
		WHEN @nrep = 10 THEN SUM(p.paymaccount - p.paymaccount_peny)
		ELSE 0
	END <> 0
	OPTION (RECOMPILE, MAXDOP 1);
go

