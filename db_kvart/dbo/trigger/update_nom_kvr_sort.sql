-- =============================================
-- Author:		Пузанов
-- Create date: 04.02.2011
-- Description:	
-- =============================================

CREATE         TRIGGER [dbo].[update_nom_kvr_sort] ON [dbo].[Flats]
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS
	(
		SELECT id, nom_kvr
		FROM INSERTED AS i
		EXCEPT
		SELECT id, nom_kvr
		FROM DELETED AS d
	)
	BEGIN
		UPDATE f
		SET nom_kvr_sort = dbo.sort_string(i.nom_kvr, 5)
		FROM INSERTED i
		JOIN dbo.Flats AS f ON 
			f.id = i.id;

		UPDATE o
		SET address = dbo.Fun_GetAdres( f.bldn_id, i.id, o.occ )
		FROM INSERTED AS i
			 JOIN dbo.Flats AS f ON 
				f.id = i.id
			 JOIN dbo.Occupations AS o ON 
				o.flat_id = f.id;
	END; 

END;
go

