-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Отмена ручного изменения пени
-- =============================================
CREATE   PROCEDURE [dbo].[k_peny_cancel_hand_edit]
(
	@occ1		INT
	,@sup_id1	INT	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	,@fin_pred SMALLINT
	,@occ_sup INT
	,@Peny_old_fin_pred DECIMAL(9,2)
	
	select @fin_current=dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);
	SET @fin_pred=@fin_current-1

	BEGIN TRAN

	IF @sup_id1>0
	begin
		SELECT @Peny_old_fin_pred=(os.Penalty_old_new+os.Penalty_value), @occ_sup=os.occ_sup
		FROM dbo.OCC_SUPPLIERS os
		WHERE os.occ=@occ1
		AND os.fin_id=@fin_pred
		AND os.sup_id=@sup_id1

		UPDATE os SET Penalty_old_edit=0, Penalty_old=COALESCE(@Peny_old_fin_pred,0)
		FROM dbo.OCC_SUPPLIERS os
		WHERE os.occ=@occ1
		AND os.fin_id=@fin_current
		AND os.sup_id=@sup_id1

		IF @occ_sup IS NULL
			SELECT @occ_sup=os.occ_sup	
			FROM dbo.OCC_SUPPLIERS os
			WHERE os.occ=@occ1
			AND os.fin_id=@fin_current
			AND os.sup_id=@sup_id1

		SET @occ1=@occ_sup
	end
	ELSE
	BEGIN
		SELECT @Peny_old_fin_pred=(os.Penalty_old_new+os.Penalty_value)
		FROM dbo.OCC_HISTORY os
		WHERE os.occ=@occ1
		AND os.fin_id=@fin_pred
		
    	UPDATE o SET Penalty_old_edit=0, Penalty_old=COALESCE(@Peny_old_fin_pred,0)
		FROM dbo.occupations AS o
		WHERE o.Occ=@occ1
    END

	-- удаляем историю изменения пени
	DELETE from dbo.PENALTY_LOG
	WHERE fin_id=@fin_current
	and occ = @occ1

	COMMIT

END
go

