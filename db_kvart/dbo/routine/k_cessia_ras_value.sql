-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Расчёт вознаграждения по цессии
-- =============================================

CREATE     PROCEDURE [dbo].[k_cessia_ras_value]
(
    @paying_id   INT,
    @occ         INT,
    @dog_int     SMALLINT,
    @fin_id      SMALLINT,
    @Paymaccount DECIMAL(9, 2),
    @debug       BIT = 0
)
/*
EXEC k_cessia_ras_value 194363, 280359, 43, 128, 8039.37
EXEC k_cessia_ras_value 343577, 83461, 13, 138, 724.85, 1
*/
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @cessia_dolg_mes_start SMALLINT          = NULL,
            @cessia_dolg_mes       SMALLINT          = 0,
            @Kol_ces               DECIMAL(5, 2)     = 0,
            @Kol_col               DECIMAL(5, 2)     = 0,
            @value_ces             DECIMAL(9, 2)     = 0,
            @value_col             DECIMAL(9, 2)     = 0,
            @collector_id          INT,
            @saldo                 DECIMAL(9, 2)     = 0,
            @occ_sup               INT,
            @paymaccount_old       DECIMAL(9, 2)     = 0,
            @paymaccount_out       DECIMAL(9, 2)     = 0


	SELECT TOP 1 @cessia_dolg_mes_start = dolg_mes_start
			   , @occ_sup = occ_sup
	FROM
		dbo.CESSIA 
	WHERE
		occ = @occ
		AND dog_int = @dog_int

	SELECT @collector_id = b.collector_id
	FROM
		dbo.OCCUPATIONS AS O 
		JOIN dbo.FLATS AS F
			ON F.id = O.flat_id
		JOIN dbo.BUILDINGS AS B 
			ON F.bldn_id = B.id

	SELECT @saldo = saldo+coalesce(added,0)
		 , @cessia_dolg_mes = cessia_dolg_mes_old
	FROM
		dbo.OCC_SUPPLIERS AS OS 
	WHERE
		occ = @occ
		AND fin_id = @fin_id
		AND occ_sup = @occ_sup
	--AND dog_int=@dog_int

	IF coalesce(@cessia_dolg_mes, 0) < @cessia_dolg_mes_start
		SET @cessia_dolg_mes = @cessia_dolg_mes_start

	IF @debug = 1
	BEGIN
		PRINT '@cessia_dolg_mes_start: ' + str(@cessia_dolg_mes_start) + ' @occ_sup:' + str(@occ_sup)
		PRINT '@saldo: ' + str(@saldo, 9, 2) + ' @cessia_dolg_mes:' + str(@cessia_dolg_mes)
	END

	SELECT @paymaccount_old = coalesce(sum(PS.value), 0)
	FROM
		dbo.PAYDOC_PACKS AS pd 
		JOIN dbo.PAYINGS AS p 
			ON pd.id = p.pack_id
		JOIN dbo.PAYING_SERV AS PS
			ON p.id = PS.paying_id
	WHERE
		pd.fin_id = @fin_id
		AND p.occ = @occ
		AND p.forwarded = 1
		AND p.sup_id IS NOT NULL -- !!!!!
		AND PS.paying_id < @paying_id

	IF @debug = 1
	BEGIN
		PRINT '@saldo:' + str(@saldo, 9, 2) + ' @paymaccount_old:' + str(@paymaccount_old, 9, 2)
	END

	SELECT @saldo = @saldo - @paymaccount_old
	IF @saldo < @Paymaccount AND @Paymaccount > 0 AND @saldo > 0
		SET @Paymaccount = @saldo

	IF @saldo > 0
	BEGIN
		SELECT @Kol_ces = [dbo].[Fun_GetProcentAgenta](@cessia_dolg_mes, @dog_int, NULL)
		SELECT @value_ces = @Paymaccount * @Kol_ces * 0.01
		SELECT @paymaccount_out = @Paymaccount - @value_ces

		IF @collector_id IS NOT NULL
		BEGIN
			SELECT @Kol_col = [dbo].[Fun_GetProcentAgenta](@cessia_dolg_mes, NULL, @collector_id)
			SELECT @value_col = @Paymaccount * @Kol_col * 0.01
		END

	END

	IF @debug = 1
	BEGIN
		PRINT '@collector_id:' + str(coalesce(@collector_id, 0), 5) + ' @saldo:' + str(@saldo, 9, 2) + ' @paymaccount_old:' + str(@paymaccount_old, 9, 2)
		PRINT '@Paymaccount:' + str(coalesce(@Paymaccount, 0), 9, 2) + ' @paymaccount_out:' + str(@paymaccount_out, 9, 2)
		PRINT '@Kol_ces:' + str(coalesce(@Kol_ces, 0), 5) + ' @value_ces:' + str(@value_ces, 9, 2)
	END

	MERGE dbo.PAYING_CESSIA AS PC USING (SELECT @paying_id) AS P (paying_id) ON (PC.paying_id = P.paying_id) WHEN MATCHED AND (@value_ces = 0) AND (@Kol_ces = 0) AND (@value_col = 0) AND (Kol_col = 0) THEN DELETE WHEN MATCHED THEN UPDATE
	SET
		Kol_ces = @Kol_ces, Kol_col = @Kol_col, value_ces = @value_ces, value_col = @value_col, paymaccount_ces = @Paymaccount
	WHEN NOT MATCHED THEN INSERT (paying_id, Kol_ces, Kol_col, value_ces, value_col, paymaccount_ces)
	VALUES
		(@paying_id, @Kol_ces, @Kol_col, @value_ces, @value_col, @Paymaccount);

END
go

