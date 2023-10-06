-- =============================================
-- Author:		Пузанов
-- Create date: 29.04.2015
-- Description:	
-- =============================================
CREATE         PROCEDURE [dbo].[ws_value_spdu]
(
	@fin_id1   SMALLINT
   ,@tip_str1  VARCHAR(2000) -- список типов фонда через запятую
   ,@xml1	   VARCHAR(MAX) = '' OUTPUT
   ,@fin_id2   SMALLINT		= NULL
   ,@build_id1 INT			= NULL
)
AS
/*
declare @xml VARCHAR(MAX)
exec ws_value_spdu 159, '27', @xml OUT
select @xml

declare @xml VARCHAR(MAX)
exec ws_value_spdu 169, '28', @xml OUT
select @xml

*/
BEGIN

	SET NOCOUNT ON;

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	-- Таблица значениями Типа жил.фонда
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	SELECT vs.id
	FROM dbo.VOcc_types AS vs
		OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
	WHERE @tip_str1 IS NULL OR t.value=vs.id
	--select * from #tip_table


	DECLARE @sup_table TABLE(sup_id INT PRIMARY KEY)
	IF @DB_NAME = 'KVART'
		INSERT INTO @sup_table	VALUES (316)

	-- выбираем дома по типам фонда
	DECLARE @table_bldn TABLE(bldn_id INT PRIMARY KEY)
	INSERT
	INTO @table_bldn
		SELECT DISTINCT
			bldn_id
		FROM dbo.Buildings_history bh 
		WHERE EXISTS (SELECT
				1
			FROM #tip_table AS T
			WHERE T.tip_id = bh.tip_id)

	-- Выбираем разовые: корректировка оплаты
	DECLARE @add_paym_table TABLE
		(
			fin_id			SMALLINT
		   ,occ				INT
		   ,service_id		VARCHAR(10)
		   ,sup_id			INT
		   ,add_paymaccount DECIMAL(9, 2)
		   ,PRIMARY KEY (fin_id, occ, service_id)
		)

	INSERT
	INTO @add_paym_table
	(fin_id
	,occ
	,service_id
	,sup_id
	,add_paymaccount)
		SELECT
			ap.fin_id
		   ,ap.occ
		   ,ap.service_id
		   ,ap.sup_id
		   ,SUM(ap.Value)
		FROM dbo.View_added AS ap 
		JOIN dbo.Occupations AS o
			ON ap.occ = o.occ
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		WHERE ap.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND ap.add_type = 13 -- корректировка оплаты
		AND (f.bldn_id = @build_id1
		OR @build_id1 IS NULL)
		AND EXISTS (SELECT
				1
			FROM @table_bldn
			WHERE bldn_id = f.bldn_id)
		GROUP BY ap.fin_id
				,ap.occ
				,ap.service_id
				,ap.sup_id


	SELECT
		o.start_date
	   ,o.build_id AS bldn_id -- код дома
	   ,0 AS occ -- лицевой счет
	   ,pl.service_id -- код услуги
	   ,pl.mode_id -- код режима потребления 
	   ,pl.tarif -- тариф
	   ,SUM(pl.saldo) AS saldo -- нач.сальдо
	   ,SUM(pl.VALUE) AS VALUE -- начислено
	   ,SUM(pl.discount) AS discount -- льгота
	   ,SUM(pl.added - COALESCE(AT.add_paymaccount, 0)) AS added -- перерасчеты
	   ,SUM(pl.paid - COALESCE(AT.add_paymaccount, 0)) AS paid -- пост.начисления (value-discount+added)
	   ,SUM(pl.debt) AS debt      -- конечное сальдо
	   ,SUM(pl.paymaccount) AS paymaccount      -- оплата
	   ,SUM(pl.paymaccount_peny) AS paymaccount_peny      -- оплата пени
	INTO #t
	FROM dbo.View_occ_all_lite AS o 
	JOIN dbo.View_paym AS pl
		ON pl.occ = o.occ
		AND pl.fin_id = o.fin_id
	JOIN #tip_table AS t
		ON o.tip_id = t.tip_id
	JOIN @table_bldn AS tb
		ON tb.bldn_id = o.bldn_id
	LEFT JOIN @add_paym_table AS AT
		ON pl.fin_id = AT.fin_id
		AND pl.occ = AT.occ
		AND pl.service_id = AT.service_id
		AND pl.sup_id = AT.sup_id
	LEFT JOIN @sup_table AS st
		ON pl.sup_id = st.sup_id
	WHERE 1=1
		AND o.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (pl.sup_id = 0 OR st.sup_id > 0)
		AND (@build_id1 IS NULL OR o.build_id = @build_id1)
	GROUP BY o.start_date
			,o.build_id
			,pl.service_id
			,pl.mode_id
			,pl.tarif
	HAVING SUM(pl.VALUE) <> 0
		OR SUM(pl.added - COALESCE(AT.add_paymaccount, 0)) <> 0
		OR SUM(pl.paid - COALESCE(AT.add_paymaccount, 0)) <> 0
		OR SUM(pl.saldo) <> 0
		OR SUM(pl.debt) <> 0

	-- 08/09/19 По кап.ремонту Оплату пени надо добавить к начислению
	UPDATE t
	SET Paid			 = t.Paid + PaymAccount_peny
	   ,Debt			 = Debt + PaymAccount_peny
	   ,PaymAccount_peny = 0
	FROM #t AS t
	WHERE service_id = 'Крем'

	SET @xml1 = (SELECT
			start_date
		   ,bldn_id
		   ,occ
		   ,service_id
		   ,mode_id
		   ,tarif
		   ,SALDO
		   ,Value
		   ,Discount
		   ,Added
		   ,Paid
		   ,Debt
		--,paymaccount
		--,paymaccount_peny
		FROM #t
		FOR XML RAW ('VALUE'), ROOT ('root'))

	SELECT
		*
	FROM #t

--SELECT @xml1 AS xml1

END
go

