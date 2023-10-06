-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Процедура для тестирования раскидки платежей
-- =============================================
CREATE     PROCEDURE [dbo].[k_payings_serv_add_test]
(
	@debug  BIT = 1 -- вывод диогностических сообщений процедуры раскидки платежа
   ,@sup_id INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	/*
	Отобрать коды платежей для тестов
	1. с задолженностью
	2. без задолженности (долг только прошлый месяц)
	3. с переплатой
	4. с пенями
	5. с отрицательной оплатой
	6. несколько платежей по лицевому / сделать

k_payings_serv_add_test @debug=0,@sup_id=null
k_payings_serv_add_test @debug=0,@sup_id=323
k_payings_serv_add_test @debug=0,@sup_id=0

k_payings_serv_add4 @paying_id=870478, @debug=1
k_payings_serv_add4 @paying_id=870132, @debug=1

SELECT * FROM view_PAYINGS p WHERE P.fin_id=210 AND p.value<0
*/

	DECLARE @t TABLE
		(
			result			 AS (CASE
				WHEN PaymAccount <> PaymAccount THEN 'ERROR'
				ELSE ''
			END)
		   ,tip_pay			 SMALLINT
		   ,Occ				 INT
		   ,paying_id		 INT
		   ,SALDO			 DECIMAL(9, 2)
		   ,Paid_old		 DECIMAL(9, 2)
		   ,Paid			 DECIMAL(9, 2)
		   ,peny_old		 DECIMAL(9, 2)
		   ,PaymAccount		 DECIMAL(9, 2) DEFAULT 0 NOT NULL
		   ,address			 VARCHAR(50)
		   ,occ_sup			 INT
		   ,PaymAccount_serv DECIMAL(9, 2) DEFAULT 0 NOT NULL
		)
	INSERT INTO @t
	(tip_pay
	,Occ
	,paying_id
	,SALDO
	,Paid_old
	,Paid
	,peny_old
	,PaymAccount
	,address
	,occ_sup)
		SELECT
			t2.tip_pay
		   ,t2.Occ
		   ,t2.paying_id
		   ,t2.SALDO
		   ,t2.Paid_old
		   ,t2.Paid
		   ,t2.Penalty_old
		   ,t2.PaymAccount
		   ,t2.address
		   ,t2.occ_sup
		FROM (SELECT
				t.*
			   ,DENSE_RANK() OVER (PARTITION BY tip_pay ORDER BY Occ, paying_id) AS toprank
			FROM (SELECT
					tip_pay =
						CASE
							WHEN p.value < 0 THEN 5
							WHEN o.Penalty_old > 100 THEN 4
							WHEN o.SALDO < 0 THEN 3
							WHEN o.SALDO - o.Paid_old > 0 THEN 1
							WHEN o.SALDO - o.Paid_old <= 0 THEN 2							
							ELSE 0
						END
				   ,p.Occ
				   ,p.id AS paying_id
				   ,o.SALDO
				   ,o.Paid_old
				   ,o.Paid
				   ,o.Penalty_old
				   ,p.[value] AS PaymAccount
				   ,o.[address]
				   ,p.occ_sup
				FROM dbo.PAYINGS p
				JOIN dbo.View_OCC_AND_SUP o 
					ON p.Occ = o.occ_address
					AND p.fin_id = o.fin_id
				JOIN dbo.OCCUPATION_TYPES ot
					ON o.tip_id = ot.id
					AND p.fin_id = ot.fin_id
				WHERE ot.payms_value = 1
				AND (p.sup_id = @sup_id
				OR @sup_id IS NULL)
				AND (o.SALDO <> 0
				OR o.Paid_old <> 0
				OR o.Paid <> 0
				OR o.Penalty_old <> 0)) AS t) AS t2
		WHERE t2.toprank <= 5

	--	SELECT
	--		*
	--	FROM @t

	DECLARE @paying_id1 INT

	DECLARE cur_test CURSOR LOCAL FOR
		SELECT
			paying_id
		FROM @t
	OPEN cur_test
	FETCH NEXT FROM cur_test INTO @paying_id1
	WHILE @@fetch_status = 0
	BEGIN
		IF @debug = 1
			PRINT @paying_id1

		EXEC [dbo].[k_payings_serv_add4] @paying_id = @paying_id1
										,@debug = @debug

		FETCH NEXT FROM cur_test INTO @paying_id1
	END
	CLOSE cur_test;
	DEALLOCATE cur_test;

	-- Записываем результат раскидки по услугам
	UPDATE t
	SET PaymAccount_serv = COALESCE((SELECT
			SUM(ps.value)
		FROM PAYING_SERV ps
		WHERE ps.paying_id = t.paying_id
		AND ps.Occ = t.Occ)
	, 0)
	FROM @t AS t

	---- Выводим краткий результат	
	--SELECT
	--	t.result
	--   ,t.Occ
	--   ,t.paying_id
	--FROM @t AS t
	--WHERE t.result <> ''

	-- Выводим подробный результат	
	SELECT
		t.*
	   ,pl.metod_name
	   ,pl.ostatok
	   ,pl.metod_ostatok
	   ,pl.msg_log
	   ,pl.done
	FROM @t AS t
	LEFT JOIN PAYING_LOG AS pl
		ON t.paying_id = pl.paying_id
		AND t.Occ = pl.occ
	ORDER BY t.result DESC, t.tip_pay
END
go

