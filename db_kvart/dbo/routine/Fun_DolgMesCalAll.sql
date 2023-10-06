CREATE   FUNCTION [dbo].[Fun_DolgMesCalAll]
(
	@fin_id	SMALLINT
	,@occ	INT
)
RETURNS DECIMAL(5, 1)
AS
/*
 Количество календарных месяцев долга с учётом поставщиков  
 
 Если много лицевых выполняется ДОЛГО!
  
 SELECT [dbo].[Fun_DolgMesCalAll] (90,66525) 
*/
BEGIN
	DECLARE	@mes			DECIMAL(5, 1)	= 0
			,@mes_ras		DECIMAL(5, 1)	= 0
			, -- расчётная величина когда задолженность больше чем месяцев расчёта в базе
			@dolg			DECIMAL(15, 2)
			,@paid			DECIMAL(15, 2)
			,@fin_Current	SMALLINT

	SELECT
		@fin_Current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	DECLARE @t TABLE
		(
			fin_id	SMALLINT	PRIMARY KEY
			,dolg	DECIMAL(15, 2)
			,paid	DECIMAL(15, 2)
		)

	IF @fin_id >= @fin_Current
	BEGIN
		INSERT
		INTO @t
		(	fin_id
			,dolg
			,paid)
				SELECT
					@fin_Current
					,(COALESCE(o.SaldoAll, 0) - COALESCE(o.Paymaccount_ServAll, 0) +
						CASE  -- если текущие разовые меньше 0 то учитываем иначе нет
							WHEN COALESCE(o.AddedAll, 0) < 0 THEN o.AddedAll
							ELSE 0
						END
					)
					,COALESCE(o.PaidAll, 0)
				FROM dbo.OCCUPATIONS AS o 
				WHERE o.Occ = @occ
	END

	INSERT
	INTO @t
	(	fin_id
		,dolg
		,paid)
			SELECT
				fin_id
				,(COALESCE(o.SaldoAll, 0) - COALESCE(o.Paymaccount_ServAll, 0))
				,COALESCE(o.PaidAll, 0)
			FROM dbo.OCC_HISTORY AS o 
			WHERE o.Occ = @occ
			AND fin_id < @fin_Current

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
				ELSE ROUND(@dolg / @paid, 1, 1)
			END

	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT
			paid
		FROM @t
		ORDER BY fin_id DESC
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @paid
	WHILE (@@fetch_status = 0)
	BEGIN
		IF @dolg < @paid
			SET @mes = @mes + ROUND(@dolg / @paid, 1, 1)
		ELSE
			SET @mes = @mes + 1

		SET @dolg = @dolg - @paid
		IF @dolg <= 0
			BREAK
		--IF @dolg<=@paid BREAK
		FETCH NEXT FROM curs_1 INTO @paid
	END
	CLOSE curs_1
	DEALLOCATE curs_1

	IF @dolg > 0
		AND @mes_ras > 0 -- долг остался выдаём расчётную величину (Долг/Начисления)
		SET @mes = @mes_ras

	IF @mes IS NULL
		OR @mes < 0
		SET @mes = 0
	IF @mes > 999
		SET @mes = 999


	RETURN @mes

END
go

