-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_add_occ_sup]
	ON [dbo].[Occ_Suppliers]
	FOR INSERT, UPDATE
AS
BEGIN

	SET NOCOUNT ON;

	IF NOT EXISTS (
			SELECT 1
			FROM INSERTED
			WHERE occ_sup = 0
		)
		RETURN

	UPDATE t1
	SET occ_sup = dbo.Fun_GetOccSUP(t2.occ, t2.sup_id, t2.dog_int)
	FROM dbo.Occ_Suppliers AS t1
		JOIN INSERTED AS t2 ON t1.fin_id = t2.fin_id
			AND t1.occ = t2.occ
			AND t1.sup_id = t2.sup_id
	WHERE t2.occ_sup IS NULL
	
	IF @@rowcount > 0
	BEGIN
		DECLARE @occ_sup INT = NULL
			  , @occ INT = NULL
		SELECT TOP 1 @occ_sup = occ_sup
		FROM INSERTED AS I
			JOIN dbo.Occupations AS O 
			ON I.occ_sup = O.occ

		IF @occ_sup IS NOT NULL
		BEGIN
			RAISERROR ('Лицевой счёт поставщика %i совпадает с единым л/сч!', 16, 1, @occ_sup) WITH NOWAIT;
			ROLLBACK TRAN
		END

		IF UPDATE(occ_sup)
		BEGIN
			SELECT TOP (1) @occ = OS.occ
					   , @occ_sup = OS.occ_sup
			FROM INSERTED AS I
				JOIN dbo.Occ_Suppliers AS OS 
					ON I.occ_sup = OS.occ_sup
					AND I.occ <> OS.occ
				JOIN dbo.Occupations O 
					ON OS.occ = O.occ
					AND O.status_id <> 'закр'

			IF @occ IS NOT NULL
				AND @occ_sup <> 0
			BEGIN
				RAISERROR ('Лицевой счёт поставщика %i уже есть на ед. лиц.счёте: %i!', 16, 1, @occ_sup, @occ) WITH NOWAIT;
				ROLLBACK TRAN
			END
		END
	END


END
go

