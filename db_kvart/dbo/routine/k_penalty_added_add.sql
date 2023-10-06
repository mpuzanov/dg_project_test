-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE             PROCEDURE [dbo].[k_penalty_added_add]
(
	  @occ1 INT
	, @value_added DECIMAL(9, 2)
	, @doc1 VARCHAR(100) = NULL
	, @sup_id1 INT = NULL
	, @is_plus_peny BIT = 0  -- прибавить к текущему разовому пени
	, @finPeriods VARCHAR(100) = NULL
)
AS
/*
сумма заменит текущую сумму разового если она уже есть
*/
BEGIN
	SET NOCOUNT ON;

	IF dbo.Fun_AccessPenaltyLic(@occ1) = 0
	BEGIN
		RAISERROR (N'Работа с пени Вам запрещена', 16, 1, @occ1)
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		RAISERROR (N'Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
	END

	DECLARE @fin_current SMALLINT = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @sup_id1 > 0
		SELECT @occ1 = occ_sup
		FROM dbo.Occ_Suppliers 
		WHERE Occ = @occ1
			AND fin_id = @fin_current
			AND sup_id = @sup_id1

	BEGIN TRAN

	IF @is_plus_peny = 1
		-- суммируем с текущим разовым
		SELECT @value_added = @value_added + COALESCE((
				SELECT value_added
				FROM dbo.Peny_added
				WHERE fin_id = @fin_current
					AND Occ = @occ1
			), 0)

	DELETE FROM dbo.Peny_added
	WHERE fin_id = @fin_current
		AND Occ = @occ1

	IF @value_added <> 0
		INSERT INTO dbo.Peny_added
			(fin_id
		   , Occ
		   , value_added
		   , doc
		   , finPeriods)
			VALUES (@fin_current
				  , @occ1
				  , @value_added
				  , @doc1
				  , @finPeriods)

	DECLARE @message VARCHAR(100) = CONCAT(N'Разовые: ', dbo.NSTR(@value_added))
	-- сохраняем в историю изменений
	EXEC k_write_log @occ1 = @occ1
				   , @oper1 = N'пеня'
				   , @comments1 = @message

	COMMIT TRAN
END
go

