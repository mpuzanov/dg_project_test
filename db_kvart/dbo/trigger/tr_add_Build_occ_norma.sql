-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_add_Build_occ_norma]
   ON [dbo].[Build_occ_norma]
	FOR INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT
				1
			FROM INSERTED AS I
			JOIN dbo.Flats as f ON i.build_id=f.bldn_id
			JOIN dbo.Occupations as o ON f.id=o.flat_id and i.occ=o.occ
			)
	BEGIN
		RAISERROR ('Таких лицевых нет в доме', 16, 10)
		ROLLBACK TRANSACTION
		RETURN
	END

END
go

