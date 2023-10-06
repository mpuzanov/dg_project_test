CREATE   FUNCTION [dbo].[Fun_DolgMesCalSup]
(
	@fin_id		SMALLINT
	,@occ		INT
	,@sup_id	INT
)
RETURNS SMALLINT
AS
/*
Количество календарных месяцев долга по поставщику  
  
SELECT [dbo].[Fun_DolgMesCalSup] (118,66525,300)
SELECT [dbo].[Fun_DolgMesCalSup] (175,680000039,323)

*/

BEGIN
	IF NOT EXISTS (SELECT 1
			FROM dbo.OCC_SUPPLIERS AS o 
			WHERE o.occ = @occ
			AND SUP_ID = @sup_id
			AND fin_id = @fin_id)
		RETURN 0

	DECLARE @mes DECIMAL(5, 1) = 0
	DECLARE	@dolg		DECIMAL(15, 2)
			,@paid		DECIMAL(15, 2)
			,@mes_ras	DECIMAL(5, 1)	= 0 -- расчётная величина когда задолженность больше чем месяцев расчёта в базе

	DECLARE @t TABLE
		(
			fin_id	SMALLINT	PRIMARY KEY
			,dolg	DECIMAL(15, 2)
			,paid	DECIMAL(15, 2)
		)

	INSERT INTO @t
	(	fin_id
		,dolg
		,paid)
		SELECT
			fin_id
			--, (o.saldo - o.paid_old - o.paymaccount)
			,(o.saldo - o.paymaccount) -- 22/03/2013
			,o.Paid_old
		FROM dbo.OCC_SUPPLIERS AS o 
		WHERE o.occ = @occ
		AND SUP_ID = @sup_id
		AND fin_id <= @fin_id

	SELECT TOP 1
		@dolg = dolg
	FROM @t
	ORDER BY fin_id DESC

	IF @dolg <= 0
		RETURN @mes

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
		RETURN 0

	DECLARE curs_1 CURSOR FOR
		SELECT
			paid
		FROM @t
		WHERE fin_id < @fin_id
		ORDER BY fin_id DESC
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @paid

	WHILE (@@fetch_status = 0)
	BEGIN

		IF @dolg < @paid
			SET @mes = @mes + ROUND(@dolg / @paid, 1, 1)
		ELSE
			SET @mes = @mes + 1

		SET @dolg=@dolg-@paid
		
		--PRINT STR(@dolg,9,2) +' '+ STR(@paid,9,2) +' '+STR(@mes,5,1)

		IF @dolg <=0
			BREAK

		FETCH NEXT FROM curs_1 INTO @paid
	END

	CLOSE curs_1
	DEALLOCATE curs_1

	IF @dolg > 0 AND @mes_ras > 0 -- долг остался выдаём расчётную величину (Долг/Начисления)
		SET @mes = @mes_ras

	IF @mes > 999
		SET @mes = 999

	RETURN @mes

END
go

