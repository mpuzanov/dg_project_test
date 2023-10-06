-- =============================================
-- Author:		Пузанов
-- Create date: 19.05.2008
-- Description:	Получем сумму долга после 10 числа заданного фин.периода
-- =============================================

CREATE   FUNCTION [dbo].[Fun_SumDolg10]
(
    @fin_id1 SMALLINT,
    @occ1    INT,
    @day     TINYINT
)
/*
select [dbo].[Fun_SumDolg10](132,700012484,10)
select [dbo].[Fun_SumDolg10](172,680004256,10)

*/
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

	SELECT @end_date = end_date FROM dbo.GLOBAL_VALUES WHERE fin_id = @fin_id1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @fin_id1 >= @fin_current
		SET @fin_id1 = @fin_current

	IF @fin_id1 < @fin_current
		SELECT @saldo = saldo + Penalty_old
		FROM
			dbo.occ_history 
		WHERE
			occ = @occ1
			AND fin_id = @fin_id1

	-- если период декабрь
	IF @fin_id1 IN (143,155,167) SET @day=31

	IF @fin_id1 >= @fin_current
		SELECT @saldo = saldo + Penalty_old
		FROM
			dbo.occupations 
		WHERE
			occ = @occ1

	SET @res = @saldo
	
	IF (@saldo IS NOT NULL)
	BEGIN
		SELECT @oplata = coalesce(sum(p.value), 0)
		FROM
			dbo.PAYINGS AS p
			JOIN dbo.PAYDOC_PACKS AS pd 
				ON p.pack_id = pd.id
		WHERE
			p.occ = @occ1
			AND pd.fin_id = @fin_id1
			AND pd.day <= @end_date
			AND p.sup_id=0

		SELECT @res = coalesce(@saldo, 0) - coalesce(@oplata, 0)

		IF @res < 0
			SET @res = 0

	END

	RETURN @res

END
go

