-- =============================================
-- Author:		Пузанов
-- Create date: 02.08.2019
-- Description:	Расчёт квартплаты по лицевым счетам в пачке
-- =============================================
CREATE       PROCEDURE [dbo].[k_raschet_pack]
	@pack_id INT
   ,@debug	 BIT = 0
AS
/*
k_raschet_pack 48764, 1
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @occ1	 INT
		   ,@sup_id1 INT
		   ,@occ_sup INT
		   ,@fin_id1 SMALLINT

	BEGIN TRY

		DECLARE cur CURSOR LOCAL FOR
			SELECT
				p.fin_id
			   ,p.occ
			   ,p.sup_id
			FROM dbo.Payings p
			WHERE 
				p.pack_id = @pack_id
				AND p.forwarded = 1

		OPEN cur
		FETCH NEXT FROM cur INTO @fin_id1, @occ1, @sup_id1

		WHILE @@fetch_status = 0
		BEGIN
			IF @debug = 1
				RAISERROR ('%d %d %d', 10, 1, @fin_id1, @occ1, @sup_id1) WITH NOWAIT;

			-- Расчет пени
			if @sup_id1=0
			    -- Расчет пени по ед.лицевому
				EXEC dbo.k_raschet_peny @occ1 = @occ1, @fin_id1 = @fin_id1, @debug = 0
			ELSE
				BEGIN -- Расчет пени по поставщику
				
					SELECT @occ_sup=occ_sup	FROM dbo.OCC_SUPPLIERS AS OS WHERE Occ = @occ1 AND sup_id = @sup_id1
					        
					IF @occ_sup>0
						EXEC dbo.k_raschet_peny_sup_new @occ_sup = @occ_sup, @fin_id1 = @fin_id1, @debug = 0
				END
			
			-- Расчитываем квартплату
			EXEC dbo.k_raschet_2 @occ1
								,@fin_id1

			FETCH NEXT FROM cur INTO @fin_id1, @occ1, @sup_id1

		END

		CLOSE cur
		DEALLOCATE cur


	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH

END
go

