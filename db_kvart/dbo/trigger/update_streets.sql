-- =============================================
-- Author:		Пузанов 
-- Create date: 27.12.2010
-- Description:	изменяем адрес на лицевых счетах
-- =============================================
CREATE     TRIGGER [dbo].[update_streets]
ON [dbo].[Streets]
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
			SELECT
				i.Id, i.[Name]
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id, d.[Name]
			FROM DELETED d
			)
	BEGIN

		UPDATE o
		SET address = dbo.Fun_GetAdres(f.bldn_id,f.id,o.occ)  --CONCAT(s.full_name, ' д.', b.nom_dom, ' кв.', f.nom_kvr)
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f ON 
			o.flat_id = f.Id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id = b.Id
		JOIN DELETED AS d ON 
			b.street_id = d.id

	END

END
go

