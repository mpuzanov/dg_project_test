CREATE   TRIGGER [dbo].[update_builds]
ON [dbo].[Buildings]
FOR UPDATE
AS
	SET NOCOUNT ON

	IF EXISTS (	
			SELECT
				i.id
			   ,i.street_id
			   ,i.nom_dom
			   ,i.town_id
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id
			   ,d.street_id
			   ,d.nom_dom
			   ,d.town_id
			FROM DELETED d
			)
	BEGIN
		-- надо сменить адреса всех лицевых в этом доме
		UPDATE o
		SET address = [dbo].[Fun_GetAdres](f.bldn_id, o.flat_id, o.Occ)
		--OUTPUT INSERTED.id, $action, DELETED.street_id, DELETED.nom_dom,DELETED.town_id, 
	    --     INSERTED.street_id, INSERTED.nom_dom, INSERTED.town_id  
		--  INTO Building_debug(build_id,change_type,street_id,nom_dom,town_id)  
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN INSERTED AS i
			ON f.bldn_id = i.id
		JOIN dbo.Streets AS s 
			ON i.street_id=s.id
		JOIN dbo.Towns AS t 
			ON s.town_id = t.id
		WHERE o.status_id <> 'закр'


	END --if update
go

