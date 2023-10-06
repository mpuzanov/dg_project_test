CREATE   PROCEDURE [dbo].[adm_update_streets]
(
	@id1	  INT
   , --код улицы у которой надо сменить название
	@name_new VARCHAR(30)
)
AS
	--
	--
	--
	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM dbo.STREETS
			WHERE id = @id1)
	BEGIN  -- есть улица с таким кодом
		IF EXISTS (SELECT
					*
				FROM STREETS
				WHERE name = @name_new)
		BEGIN
			RAISERROR ('Улица с таким названием уже есть!', 16, 1)
			RETURN
		END

		UPDATE dbo.STREETS
		SET name = @name_new
		WHERE id = @id1

		-- надо сменить адреса всех лицевых на этой улице
		UPDATE o
		SET address = dbo.Fun_GetAdres(b.id, f.id, o.occ)
		FROM dbo.OCCUPATIONS AS o
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS AS b 
			ON f.bldn_id = b.id
		WHERE b.street_id = @id1

	END
go

