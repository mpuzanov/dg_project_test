CREATE   PROCEDURE [dbo].[rep_11_svod]
(
	  @nrep SMALLINT = 1 -- Номер отчета
	, @fin_id SMALLINT = NULL -- Фин.период
	, @tip_id SMALLINT = 0 -- тип жилого фонда
	, @div_id SMALLINT = NULL -- код района
	, @build_id INT = NULL -- код дома
	, @tip_counter SMALLINT = NULL -- тип счётчика
	, @sup_id INT = NULL -- поставщик
	, @town_id SMALLINT = NULL

)
AS
	/*
	--
	--   Вывод сводных отчетов по начислениям
	--   Итоговые значения по районам и участкам
	--   1. Начислено без учета льгот и субсидий
	--   2. Начислено с учетом льгот и субсидий
	--   3. Поступления
	--   4. Задолженность с учетом переплаты
	--   5. Задолженность без учета переплаты
	--   6. Текущая задолженность
	--   7. Разовые 
	--   8. Льготы
	--   9. Субсидии
	--  10. Оплата пени
	--  11. Оплата по услугам(без пени)
	--  12. Комиссия банка
	
	-- дата изменения:	24/12/10
	-- автор изменения:	Пузанов
	
	rep_11_svod 1,242,4
	rep_11_svod 1,162,28
	
	*/
	SET NOCOUNT ON


	IF @nrep IS NULL
		SET @nrep = 1 --RETURN

	IF @tip_id IS NULL
		AND @town_id IS NULL
		SET @tip_id = 0


	DECLARE @fin_current SMALLINT = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)
		  , @fin_pred SMALLINT

	IF @fin_id IS NULL
		OR @fin_id = 0
		SET @fin_id = @fin_current

	SET @fin_pred = @fin_id - 1

	DECLARE @CurrentDate SMALLDATETIME = current_timestamp

	-- для ограничения доступа услуг
	CREATE TABLE #s (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, name VARCHAR(100) COLLATE database_default
		, short_name VARCHAR(20) COLLATE database_default
	)
	INSERT INTO #s (id
				  , name
				  , short_name)
	SELECT id
		 , name
		 , short_name
	FROM dbo.View_services

	IF (@nrep IN (1, 2, 3, 4, 7, 8, 9, 10, 11))
	BEGIN
		SELECT b.div_name AS 'Район'
			 , b.adres AS 'Дом'
			 , s.name AS service_id
			 , CASE
				   WHEN @nrep = 1 THEN SUM(p.VALUE)
				   WHEN @nrep = 2 THEN SUM(p.Paid)
				   WHEN @nrep = 3 THEN SUM(p.PaymAccount)
				   WHEN @nrep = 4 THEN SUM((p.SALDO - p.PaymAccount))
				   WHEN @nrep = 7 THEN SUM(p.Added)
				   WHEN @nrep = 8 THEN SUM(p.Discount)
				   WHEN @nrep = 9 THEN SUM(p.Compens)
				   WHEN @nrep = 10 THEN SUM(p.PaymAccount_peny)
				   WHEN @nrep = 11 THEN SUM(p.PaymAccount - p.PaymAccount_peny)
				   ELSE 0
			   END AS VALUE
		FROM dbo.View_paym AS p 
			JOIN dbo.View_occ_all AS o ON p.Occ = o.Occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_build_all AS b  ON o.bldn_id = b.bldn_id
				AND p.fin_id = b.fin_id
			JOIN #s AS s ON p.service_id = s.id
		WHERE 1=1
			AND p.fin_id = @fin_id
			AND o.fin_id = @fin_id
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)
			AND (b.div_id = @div_id OR @div_id IS NULL)
			AND (o.bldn_id = @build_id OR @build_id IS NULL)
			AND (p.sup_id = @sup_id OR @sup_id IS NULL)
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (p.is_counter = @tip_counter OR @tip_counter IS NULL)
		GROUP BY b.div_name
			   , b.adres
			   , s.name
		HAVING CASE
				WHEN @nrep = 1 THEN SUM(p.VALUE)
				WHEN @nrep = 2 THEN SUM(p.Paid)
				WHEN @nrep = 3 THEN SUM(p.PaymAccount)
				WHEN @nrep = 4 THEN SUM((p.SALDO - p.PaymAccount))
				WHEN @nrep = 7 THEN SUM(p.Added)
				WHEN @nrep = 8 THEN SUM(p.Discount)
				WHEN @nrep = 9 THEN SUM(p.Compens)
				WHEN @nrep = 10 THEN SUM(p.PaymAccount_peny)
				WHEN @nrep = 11 THEN SUM(p.PaymAccount - p.PaymAccount_peny)
				ELSE 0
			END <> 0
		OPTION (MAXDOP 1, FAST 10);
	END

	-- Задолженность без учета переплаты
	IF @nrep = 5
	BEGIN
		SELECT b.div_name AS 'Район'
			 , b.adres AS 'Дом'
			 , s.name AS service_id
			 , SUM(p.SALDO - p.PaymAccount) AS VALUE
		FROM dbo.View_paym AS p 
			JOIN dbo.View_occ_all AS o ON p.Occ = o.Occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_build_all AS b ON o.bldn_id = b.bldn_id
				AND p.fin_id = b.fin_id
			JOIN #s AS s ON p.service_id = s.id
		WHERE p.fin_id = @fin_id
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)
			AND (b.div_id = @div_id OR @div_id IS NULL)
			AND (o.bldn_id = @build_id OR @build_id IS NULL)
			AND (p.sup_id = @sup_id OR @sup_id IS NULL)
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (o.SALDO - o.PaymAccount) > 0 -- только если лицевой должен   08.06.10		
		GROUP BY b.div_name
			   , b.adres
			   , s.name
		OPTION (MAXDOP 1, FAST 10);
	END

	--  Текущая задолженность
	IF @nrep = 6
	BEGIN
		--PRINT 'Текущая задолженность из истории' 
		SELECT b.div_name AS 'Район'
			 , b.adres AS 'Дом'
			 , s.name AS service_id
			 , SUM(ph.Paid - p.PaymAccount) AS VALUE
		FROM dbo.View_paym AS p 
			JOIN dbo.Paym_history AS ph  ON p.Occ = ph.Occ
			JOIN dbo.View_occ_all AS o  ON p.Occ = o.Occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_build_all AS b  ON o.bldn_id = b.bldn_id
				AND p.fin_id = b.fin_id
			JOIN #s AS s ON p.service_id = s.id
		WHERE p.fin_id = @fin_id
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)
			AND (b.div_id = @div_id OR @div_id IS NULL)
			AND (o.bldn_id = @build_id OR @build_id IS NULL)
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND ph.Paid <> 0
			AND p.service_id = ph.service_id
			AND ph.fin_id = @fin_pred -- пред.фин.период
		GROUP BY b.div_name
			   , b.adres
			   , s.name
		HAVING SUM(ph.Paid - p.PaymAccount) <> 0
		OPTION (MAXDOP 1, FAST 10);
	END

	-- Комиссия банка
	IF @nrep = 12
	BEGIN
		SELECT b.div_name AS 'Район'
			 , b.adres AS 'Дом'
			 , s.name AS service_id
			 , SUM(p.commission) AS VALUE
		FROM dbo.Paying_serv AS p 
			JOIN dbo.Payings AS pp ON p.paying_id = pp.id
			JOIN dbo.View_occ_all AS o ON p.Occ = o.Occ
				AND pp.fin_id = o.fin_id
			JOIN dbo.View_build_all AS b ON o.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			JOIN #s AS s ON p.service_id = s.id
		WHERE pp.fin_id = @fin_id
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)
			AND (b.div_id = @div_id OR @div_id IS NULL)
			AND (o.bldn_id = @build_id OR @build_id IS NULL)
			AND (p.sup_id = @sup_id OR @sup_id IS NULL)
			AND (b.town_id = @town_id OR @town_id IS NULL)
		GROUP BY b.div_name
			   , b.adres
			   , s.name
		OPTION (MAXDOP 1, FAST 10);
	END
go

