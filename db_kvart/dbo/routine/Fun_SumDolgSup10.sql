-- =============================================
-- Author:		Пузанов
-- Create date: 19.05.2008
-- Description:	Получем сумму долга после 10 числа заданного фин.периода
-- =============================================

CREATE   FUNCTION [dbo].[Fun_SumDolgSup10]
(
    @fin_id1 SMALLINT,
    @occ1    INT,
    @sup_id  INT,
    @day     TINYINT
)
RETURNS DECIMAL(9, 2)
AS
BEGIN
	DECLARE @res         DECIMAL(9, 2),
            @oplata      DECIMAL(9, 2),
            @end_date    SMALLDATETIME,
            @saldo       DECIMAL(9, 2),
            @fin_current SMALLINT

	SELECT @res = 0
		 , @saldo = NULL

	SELECT @end_date = end_date
	FROM dbo.GLOBAL_VALUES 
	WHERE fin_id = @fin_id1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @fin_id1 >= @fin_current
		SET @fin_id1 = @fin_current

	-- если период декабрь
	IF @fin_id1 IN (143,155,167) SET @day=31
	
	SELECT @saldo = saldo + Penalty_old
	FROM dbo.OCC_SUPPLIERS 
	WHERE occ = @occ1
		AND fin_id =@fin_id1
		AND sup_id =@sup_id

	IF (@saldo IS NOT NULL) 
	BEGIN
		--SET @end_date = str(year(@end_date), 4) + dbo.Fun_AddLeftZero(str(month(@end_date)), 2) + dbo.Fun_AddLeftZero(str(@day), 2)

		SELECT @oplata = coalesce(sum(p.value), 0)
		FROM dbo.PAYINGS AS p 
			JOIN dbo.PAYDOC_PACKS AS pd
				ON p.pack_id = pd.id
		WHERE p.occ = @occ1
			AND	pd.fin_id = @fin_id1
			AND pd.day <= @end_date
			AND p.sup_id=@sup_id

		SELECT @res = coalesce(@saldo, 0) - @oplata

		IF @res < 0
			SET @res = 0

	END

	RETURN @res

END
go

