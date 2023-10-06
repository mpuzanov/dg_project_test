CREATE   PROCEDURE [dbo].[k_penalty_izm]
(
	@occ1	  INT
   ,@SumNew1  DECIMAL(9, 2)
   ,@comment1 VARCHAR(50)
   ,@sup_id	  INT = NULL
)
AS
	/*
	  
	Изменение пени предыдущих периодов
	 
	exec k_penalty_izm @occ1=888001, @SumNew1=100, @comment1='test', @sup_id=null

	*/
	SET NOCOUNT ON

	IF dbo.Fun_AccessPenaltyLic(@occ1) = 0
	BEGIN
		RAISERROR ('Работа с пени Вам запрещена', 16, 1, @occ1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
		RETURN
	END

	DECLARE @user_id1	 SMALLINT
		   ,@date1		 SMALLDATETIME
		   ,@fin_current SMALLINT
		   ,@occ_sup	 INT
		   ,@Penalty_old1 DECIMAL(9, 2)


	DECLARE @isNestedTransaction BIT = CASE
                                           WHEN @@trancount > 0 THEN 1
                                           ELSE 0
        END

	BEGIN TRY

	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()


	IF @isNestedTransaction = 0
        BEGIN TRANSACTION
    ELSE
        SAVE TRANSACTION SavepointName;

		IF @sup_id > 0
		BEGIN
			SELECT
				@Penalty_old1 = Penalty_old
			   ,@occ_sup = occ_sup
			FROM dbo.Occ_Suppliers 
			WHERE Occ = @occ1
			AND fin_id = @fin_current
			AND sup_id = @sup_id;

			UPDATE dbo.OCC_SUPPLIERS 
			SET Penalty_old_edit = 1
				,Penalty_old = COALESCE(@SumNew1, Penalty_old)
				--CASE
				--	WHEN (Penalty_old + COALESCE(@SumNew1, 0)) < 0 THEN 0
				--	ELSE COALESCE(@SumNew1, Penalty_old)
				--END
			WHERE Occ = @occ1
			AND fin_id = @fin_current
			AND sup_id = @sup_id;

			UPDATE [dbo].OCC_SUPPLIERS
			SET Penalty_old_new=Penalty_old
			WHERE Occ = @occ1
			AND fin_id = @fin_current
			AND sup_id = @sup_id;

			SET @occ1 = @occ_sup
		END
		ELSE
		BEGIN
			SELECT
				@Penalty_old1 = Penalty_old
			FROM dbo.Occupations 
			WHERE Occ = @occ1;

			UPDATE dbo.Occupations 
			SET Penalty_old		 = @SumNew1
			   ,Penalty_old_new	 = @SumNew1
			   ,Penalty_old_edit = 1
			WHERE Occ = @occ1;
		END

		DELETE FROM dbo.Penalty_log 
		WHERE Occ = @occ1
			AND data = @date1;

		INSERT INTO dbo.Penalty_log 
		(Occ
		,fin_id
		,data
		,user_id
		,sum_old
		,sum_new
		,COMMENTS)
		VALUES (@occ1
			   ,@fin_current
			   ,@date1
			   ,@user_id1
			   ,@Penalty_old1
			   ,@SumNew1
			   ,@comment1)

	IF @isNestedTransaction = 0
		COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    DECLARE @isCommitable BIT = CASE
                                    WHEN XACT_STATE() = 1 THEN 1
                                    ELSE 0
        END
    
    IF @isCommitable = 1 AND @isNestedTransaction = 1
        ROLLBACK TRANSACTION SavepointName;
    ELSE
        ROLLBACK;
    THROW;
END CATCH;
go

