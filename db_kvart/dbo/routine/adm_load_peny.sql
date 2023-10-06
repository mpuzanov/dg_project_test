-- =============================================
-- Author:		Пузанов
-- Create date: 20.06.2012
-- Description:	Загрузка данных сальдо и(или) пени
-- =============================================
CREATE           PROCEDURE [dbo].[adm_load_peny]
	@occ		INT
   ,@saldo		DECIMAL(9, 2) = NULL
   ,@peni		DECIMAL(9, 2) = NULL
   ,@Rec_update SMALLINT	  = 0 OUTPUT
   ,@Rec_add	BIT			  = 1 -- суммировать новое пени с текщим предыдущего периода
   ,@debug		BIT			  = 0
AS
BEGIN
/*
declare @Rec_update1 SMALLINT
	,@Rec_add1	BIT			  = 1
exec adm_load_peny @occ=888001, @saldo=100, @peni=10, @Rec_update=@Rec_update1 OUTPUT, @Rec_add=@Rec_add1, @PeniMinusToSaldo=@PeniMinusToSaldo1
select @Rec_update1
*/
SET NOCOUNT ON;

DECLARE @comments VARCHAR(50)
		,@Penalty_old1  DECIMAL(9, 2)
		,@SumNew1  DECIMAL(9, 2)

DECLARE @isNestedTransaction BIT = CASE WHEN @@trancount > 0 THEN 1 ELSE 0 END

BEGIN TRY
	IF @isNestedTransaction = 0 
		BEGIN TRANSACTION
	ELSE
		SAVE TRANSACTION SavepointName;

	IF EXISTS (SELECT
				1
			FROM OCCUPATIONS AS o
			WHERE Occ = @occ)
	BEGIN
		if @debug=1 
		BEGIN
			PRINT 'обновляем сальдо или пени по лицевому'
			PRINT CONCAT('@Rec_add: ', CASE WHEN @Rec_add = 1 THEN '1' ELSE '0' END)
			PRINT CONCAT(
						'@saldo: ', CASE  WHEN @saldo IS NOT NULL THEN dbo.nstr(@saldo) ELSE 'NULL' END,
						', @peni: ', CASE WHEN @peni IS NOT NULL THEN dbo.nstr(@peni) ELSE 'NULL' END
						)
		END

		UPDATE dbo.Occupations
		SET SALDO =
				CASE
					WHEN @Rec_add = 1 THEN SALDO + COALESCE(@saldo, 0)
					ELSE COALESCE(@saldo, SALDO)
				END
		   ,saldo_edit =
				CASE
					WHEN @saldo IS NULL THEN saldo_edit
					ELSE 1
				END
		   ,Penalty_old		 =
				CASE
					WHEN @Rec_add = 1 THEN  (Penalty_old + COALESCE(@peni, 0))
					ELSE COALESCE(@peni, Penalty_old)
				END
		   ,Penalty_old_edit =
				CASE
					WHEN @peni IS NULL THEN Penalty_old_edit
					ELSE 1
				END
		WHERE Occ = @occ
		AND STATUS_ID <> 'закр'
		SET @Rec_update = @@rowcount

		UPDATE [dbo].OCCUPATIONS
		SET Penalty_old_new=Penalty_old
		WHERE Occ = @occ
		AND STATUS_ID <> 'закр'

		if @debug=1 SELECT * FROM Occupations WHERE Occ = @occ
	END
	ELSE
	BEGIN
		if @debug=1 PRINT 'Сохранение по поставщику'
		DECLARE @fin_current1 SMALLINT
			   ,@sup_id		  INT
			   ,@occ_sup	  INT

		SET @occ_sup = @occ

		SELECT TOP 1
			@occ = Occ
		   ,@sup_id = os.sup_id
		   ,@fin_current1 = os.fin_id
		   ,@Penalty_old1 = Penalty_old
		FROM OCC_SUPPLIERS AS os 
		WHERE 
			os.occ_sup = @occ_sup
		ORDER BY os.fin_id DESC

		IF @sup_id IS NOT NULL
			AND @saldo IS NOT NULL
		BEGIN
			if @debug=1 PRINT CONCAT('сохраняем caльдо. occ: ', @occ,', sup_id: ', @sup_id,', fin_current: ',@fin_current1,', saldo: ', str(@saldo,9,2))

			UPDATE dbo.Occ_Suppliers 
			SET SALDO =
				CASE
					WHEN @Rec_add = 1 THEN SALDO + COALESCE(@saldo, 0)
					ELSE COALESCE(@saldo, SALDO)
				END
			WHERE 
				Occ = @occ
				AND fin_id = @fin_current1
				AND sup_id = @sup_id
			SET @Rec_update = @@rowcount

			if @debug=1 PRINT CONCAT('@Rec_update = ',@Rec_update)

			EXEC k_write_log @occ
							,'слдо'
							,'по поставщику'
		END

		IF @sup_id IS NOT NULL
			AND @peni IS NOT NULL -- сохраняем пени	
		BEGIN
			IF @Rec_add = 1
				SELECT
					@SumNew1 = @Penalty_old1 + @peni
				   ,@comments = 'изменение пени на ' + STR(@peni, 9, 2)
			ELSE
				SELECT
					@SumNew1 = @peni
				   ,@comments = 'новое пени ' + STR(@peni, 9, 2)

			--IF @SumNew1 < 0
			--	SET @SumNew1 = 0
			--IF @debug=1 SELECT @occ, @occ_sup, @Penalty_old1, @SumNew1, @comments, @sup_id
			if @debug=1 PRINT CONCAT('сохраняем пени. @occ: ',@occ,', sup_id: ',@sup_id,', Пени: ',str(@SumNew1,9,2))

			EXEC k_penalty_izm @occ1 = @occ
							  ,@SumNew1 = @SumNew1
							  ,@sup_id = @sup_id
							  ,@comment1 = @comments

			EXEC k_raschet_peny_sup_new @occ_sup = @occ_sup
									   ,@fin_id1 = @fin_current1
									   ,@debug = 0

			EXEC k_write_log @occ
							,'пеня'
							,'по поставщику'

			SET @Rec_update = 1
		END
	END

	IF @isNestedTransaction = 0
		COMMIT TRANSACTION;

END TRY
BEGIN CATCH
	DECLARE @isCommitable BIT = CASE
                                    WHEN XACT_STATE() = 1 THEN 1
                                    ELSE 0
        END
	PRINT @isCommitable

	IF @isCommitable = 1 AND @isNestedTransaction = 1
		ROLLBACK TRANSACTION SavepointName;
	ELSE
		ROLLBACK;
	THROW;
END CATCH;

END
go

