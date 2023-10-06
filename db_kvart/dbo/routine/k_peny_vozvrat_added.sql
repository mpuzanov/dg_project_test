-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_peny_vozvrat_added]
(
	  @occ1 INT
	, @fin_id1 SMALLINT
	, @fin_id2 SMALLINT
	, @sup_id1 INT = NULL
	, @is_plus_peny BIT = 1
	, @debug BIT = 0
)
AS
/*
Возврат начисленных пени за период

EXEC k_peny_vozvrat_added @occ1=111020,@fin_id1=232,@fin_id2=232,@sup_id1=345, @is_plus_peny = null ,@debug=1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Peny_vozvrat DECIMAL(9, 2)
		  , @Peny_new DECIMAL(9, 2)
		  , @Peny_add DECIMAL(9, 2) = 0
		  , @Peny_paymaccount DECIMAL(9, 2)
		  , @fin_current SMALLINT
		  , @comments1 VARCHAR(50)
		  , @str_fin_period VARCHAR(50)

	SET @is_plus_peny = COALESCE(@is_plus_peny, 1)

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);

	IF COALESCE(@sup_id1, 0) = 0
	BEGIN
		SELECT @Peny_vozvrat = SUM(vp.penalty_value)
			 , @Peny_paymaccount = SUM(vp.paymaccount_peny)
		FROM dbo.View_peny_all AS vp
		WHERE vp.occ = @occ1
			AND vp.fin_id BETWEEN @fin_id1 AND @fin_id2
	END
	ELSE
	BEGIN
		SELECT @Peny_vozvrat = SUM(vp.penalty_value)
			 , @Peny_paymaccount = SUM(vp.paymaccount_peny)
		FROM dbo.Occ_Suppliers AS os
			JOIN dbo.View_peny_all AS vp ON 
				vp.occ = os.occ_sup
				AND os.fin_id = vp.fin_id
		WHERE os.occ = @occ1
			AND os.sup_id = @sup_id1
			AND vp.fin_id BETWEEN @fin_id1 AND @fin_id2
	END

	IF @debug = 1
		SELECT @occ1 AS occ
			 , @fin_id1 AS fin_id1
			 , @fin_id2 AS fin_id2
			 , @sup_id1 AS sup_id
			 , @Peny_vozvrat AS Peny_vozvrat
			 , @Peny_paymaccount AS Peny_paymaccount


	IF COALESCE(@Peny_vozvrat, 0) = 0
		RETURN

	SET @Peny_vozvrat = -@Peny_vozvrat

	SELECT @str_fin_period = SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
	FROM dbo.Global_values 
	WHERE fin_id = @fin_id1;

	IF @fin_id1 < @fin_id2
		SELECT @str_fin_period = @str_fin_period + '-' + SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
		FROM dbo.Global_values 
		WHERE fin_id = @fin_id2

	SELECT @comments1 = 'возврат пени за ' + @str_fin_period

	EXEC k_penalty_added_add @occ1 = @occ1
						   , @value_added = @Peny_vozvrat
						   , @doc1 = @comments1
						   , @sup_id1 = @sup_id1
						   , @is_plus_peny = @is_plus_peny


END
go

