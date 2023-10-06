-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_peny_vozvrat]
(
	  @occ1 INT
	, @fin_id1 SMALLINT
	, @fin_id2 SMALLINT
	, @sup_id1 INT = NULL
	, @service_id_out VARCHAR(10) = NULL
	, @debug BIT = 0
)
AS
/*
Возврат начисленных пени за период

EXEC k_peny_vozvrat	@occ1=680003552,@fin_id1=182,@fin_id2=187,@sup_id1=323,@service_id_out='площ',@debug=1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Peny_start DECIMAL(9, 2)
		  , @Peny_vozvrat DECIMAL(9, 2)
		  , @Peny_new DECIMAL(9, 2)
		  , @Peny_add DECIMAL(9, 2) = 0
		  , @Peny_paymaccount DECIMAL(9, 2)
		  , @occ_sup INT
		  , @fin_current SMALLINT
		  , @comments1 VARCHAR(50)
		  , @str_fin_period VARCHAR(50)

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);

	IF @sup_id1 IS NULL
	BEGIN
		SELECT @Peny_vozvrat = SUM(Penalty_value)
			 , @Peny_paymaccount = SUM(PaymAccount_peny)
		FROM dbo.View_peny_all AS vp
		WHERE occ = @occ1
			AND fin_id BETWEEN @fin_id1 AND @fin_id2

		SELECT @Peny_start = o.Penalty_old
		FROM dbo.View_occ_all_lite AS o
		WHERE o.occ = @occ1
			AND o.fin_id = @fin_current
	END
	ELSE
	BEGIN
		SELECT @Peny_start = o.Penalty_old
			 , @occ_sup = occ_sup
		FROM dbo.Occ_Suppliers AS o
		WHERE occ = @occ1
			AND fin_id = @fin_current
			AND sup_id = @sup_id1

		SELECT @Peny_vozvrat = SUM(o.Penalty_value)
			 , @Peny_paymaccount = SUM(PaymAccount_peny)
		FROM dbo.View_peny_all AS o
		WHERE o.occ = @occ_sup
			AND o.fin_id BETWEEN @fin_id1 AND @fin_id2
	END

	SELECT @Peny_new = @Peny_start - @Peny_vozvrat

	IF @Peny_new < 0
		SELECT @Peny_add = @Peny_new
			 , @Peny_new = 0

	IF @debug = 1
		SELECT @Peny_start AS Peny_start
			 , @Peny_vozvrat AS Peny_vozvrat
			 , @Peny_new AS Peny_new
			 , @Peny_add AS Peny_add
			 , @Peny_paymaccount AS Peny_paymaccount
			 , @occ_sup AS occ_sup


	IF @Peny_new = @Peny_start
		RETURN

	SELECT @str_fin_period = SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
	FROM dbo.Global_values 
	WHERE fin_id = @fin_id1;

	IF @fin_id1 < @fin_id2
		SELECT @str_fin_period = @str_fin_period + '-' + SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
		FROM dbo.Global_values 
		WHERE fin_id = @fin_id2

	-- Корректируем текущее пени из @Peny_start-@Peny_vozvrat
	IF @Peny_new <> @Peny_start
	BEGIN
		SELECT @comments1 = 'возврат пени за ' + @str_fin_period

		EXEC k_vvod_penalty @occ1 = @occ1
						  , @Peny_old1 = @Peny_new
						  , @comments1 = @comments1
						  , @sup_id1 = @sup_id1
						  , @debug = 0
	END


	-- добавляем разовые на услугу 
	IF @Peny_add < 0
	BEGIN
		IF @service_id_out IS NULL
		BEGIN
			RAISERROR ('Задайте услугу для возрата оплаченных пеней!', 16, 1)
			RETURN
		END
		SELECT @comments1 = 'возврат оплаченых пени за ' + @str_fin_period

		DECLARE @addyes BIT
		EXEC ka_add_added_3 @occ1 = @occ1
						  , @service_id1 = @service_id_out
						  , @add_type1 = 2 --  тех.кор.
						  , @doc1 = @comments1
						  , @value1 = @Peny_add
						  , @doc_no1 = NULL
						  , @doc_date1 = NULL
							--,@comments = @comments1
						  , @sup_id = @sup_id1
						  , @addyes = @addyes OUTPUT
	END

END
go

