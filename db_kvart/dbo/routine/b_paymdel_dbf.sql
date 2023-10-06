CREATE   PROCEDURE [dbo].[b_paymdel_dbf]
(
	@filedbf_id	 INT
   ,@is_pack_del BIT = 0  -- можно удалять сформированные пачку в текущем периоде
)
AS
	/*
		удаляем файл с платежами
	
		exec b_paymdel_dbf @filedbf_id=0,@is_pack_del=null
		exec b_paymdel_dbf @filedbf_id=0,@is_pack_del=0
		exec b_paymdel_dbf @filedbf_id=0,@is_pack_del=1
	*/

	SET NOCOUNT ON


	IF @is_pack_del IS NULL
		SET @is_pack_del = 0

	IF @is_pack_del = 0
		IF EXISTS (SELECT
					1
				FROM dbo.BANK_DBF
				WHERE (filedbf_id = @filedbf_id)
				AND (pack_id IS NOT NULL))
		BEGIN
			RAISERROR ('Удалить нельзя! сформированы пачки из этих платежей!', 16, 1)
			RETURN 1
		END

	IF @is_pack_del = 1
	BEGIN
		IF EXISTS (SELECT
					1
				FROM dbo.BANK_DBF bd
				LEFT JOIN dbo.PAYDOC_PACKS pp
					ON bd.pack_id = pp.id
				LEFT JOIN OCCUPATION_TYPES ot
					ON pp.tip_id = ot.id
				WHERE (filedbf_id = @filedbf_id)
				AND (bd.pack_id IS NOT NULL)
				AND pp.fin_id < ot.fin_id)
		BEGIN
			RAISERROR ('Удалить нельзя! Есть сформированные пачки в истории!', 16, 1)
			RETURN 1
		END

		-- удаляем пачки если есть 
		DECLARE @pack_id1   INT
			   ,@forwarded1 BIT

		DECLARE cur CURSOR LOCAL FOR
			SELECT DISTINCT
				bd.pack_id
			   ,pp.forwarded
			FROM dbo.BANK_DBF bd
				JOIN dbo.PAYDOC_PACKS pp
					ON bd.pack_id = pp.id
			WHERE 
				(filedbf_id = @filedbf_id)
				AND (bd.pack_id IS NOT NULL)

		OPEN cur

		FETCH NEXT FROM cur INTO @pack_id1, @forwarded1

		WHILE @@fetch_status = 0
		BEGIN

			IF EXISTS (SELECT
						1
					FROM dbo.Paydoc_packs AS pd
					WHERE pd.id = @pack_id1)
			BEGIN
				IF @forwarded1 = 1
					-- сначала возвращаем пачку
					EXEC adm_packs_out @pack_id1 = @pack_id1
									  ,@debug = 0
									  ,@ras1 = 0

				EXEC k_paydoc_delete @id1 = @pack_id1
			END

			FETCH NEXT FROM cur INTO @pack_id1, @forwarded1

		END

		CLOSE cur
		DEALLOCATE cur

	END

	BEGIN TRAN

		DELETE FROM dbo.Bank_Dbf
		WHERE (filedbf_id = @filedbf_id)
			AND (pack_id IS NULL);

		DELETE FROM dbo.Bank_tbl_spisok
		WHERE filedbf_id = @filedbf_id;

	COMMIT TRAN
go

