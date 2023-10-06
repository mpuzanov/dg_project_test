CREATE   FUNCTION [dbo].[Fun_DolgMesCalSup3]
(
	@fin_id SMALLINT
   ,@occ	INT
   ,@sup_id INT
)
RETURNS DECIMAL(5, 1)
AS
/*
Количество календарных месяцев долга по поставщику 

SELECT [dbo].[Fun_DolgMesCalSup3] (175,680000008,323)

*/

BEGIN
	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCC_SUPPLIERS AS o 
			WHERE o.occ = @occ
			AND sup_id = @sup_id
			AND fin_id = @fin_id)
		RETURN
		0

	DECLARE @mes		  DECIMAL(5, 1) = 0
		   ,@dolg		  DECIMAL(15, 2)
		   ,@paid		  DECIMAL(15, 2)
		   ,@last_balance DECIMAL(15, 2)
		   ,@mes_ras	  DECIMAL(5, 1) = 0 -- расчётная величина когда задолженность больше чем месяцев расчёта в базе

	DECLARE @t TABLE
		(
			fin_id  SMALLINT	   PRIMARY KEY
		   ,dolg	DECIMAL(15, 2) NOT NULL
		   ,paid	DECIMAL(15, 2) NOT NULL
		   ,balance DECIMAL(15, 2) DEFAULT 0 NOT NULL
		   ,kol_mes DECIMAL(5, 1)  DEFAULT 0 NOT NULL
		)

	INSERT INTO @t
	(fin_id
	,dolg
	,paid)
		SELECT
			fin_id
		   ,(o.saldo - o.paymaccount) -- 22/03/2013
		   ,o.Paid_old
		FROM dbo.OCC_SUPPLIERS AS o 
		WHERE o.occ = @occ
		AND sup_id = @sup_id
		AND fin_id <= @fin_id

	SELECT TOP 1
		@dolg = dolg
	FROM @t
	ORDER BY fin_id DESC

	IF @dolg <= 0
		RETURN
		@mes

	--SELECT
	--	@dolg AS dolg

	UPDATE @t
	SET balance = t2.balance
	   ,kol_mes =
			CASE
				WHEN t1.paid > t2.balance AND
				t1.paid > 0 AND
				t2.balance > 0 THEN ROUND(t2.balance / t1.paid, 1, 1)
				WHEN t1.paid = 0 AND
				t2.balance > 0 THEN 0
				WHEN t2.balance > 0 THEN 1
				WHEN t1.paid > 0 AND
				t2.balance = 0 THEN 1
				ELSE 0
			END
	FROM @t t1
	JOIN (SELECT
			t.fin_id
		   ,@dolg + SUM(paid * -1) OVER (PARTITION BY NULL ORDER BY t.fin_id DESC
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
		FROM @t t) t2
		ON t1.fin_id = t2.fin_id
	WHERE t2.balance > 0

	SELECT TOP 1
		@last_balance = balance
	FROM @t
	ORDER BY fin_id

	--SELECT @last_balance AS last_balance

	IF @last_balance > 0
		AND @mes_ras > 0 -- долг остался выдаём расчётную величину (Долг/Начисления)
	BEGIN
		SELECT
			@paid = AVG(paid)
		FROM @t
		WHERE paid > 0

		SELECT
			@mes_ras =
				CASE
					WHEN @paid = 0 THEN 0
					WHEN @dolg < @paid THEN 0
					ELSE ROUND(@dolg / @paid, 1, 1)
				END

		IF @mes_ras = 0
			RETURN
			0
		SET @mes = @mes_ras
	END
	ELSE
		SELECT
			@mes = SUM(kol_mes)
		FROM @t

	IF @mes > 999
		SET @mes = 999

	RETURN
	@mes
END
go

