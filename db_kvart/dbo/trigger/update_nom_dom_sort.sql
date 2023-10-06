-- =============================================
-- Author:		Пузанов
-- Create date: 04.02.2011
-- Description:	
-- =============================================
CREATE         TRIGGER [dbo].[update_nom_dom_sort]
ON [dbo].[Buildings]
AFTER INSERT, UPDATE
AS
BEGIN

	SET NOCOUNT ON;

	IF EXISTS (SELECT			
				i.id, i.nom_dom
			FROM INSERTED i	
			EXCEPT
			SELECT
				d.id, d.nom_dom
			FROM DELETED d
			)
		BEGIN
			--RAISERROR('update nom_dom_sort',10,1) WITH NOWAIT
			UPDATE b
			SET nom_dom_sort = dbo.sort_string(i.nom_dom, 5)
			FROM dbo.Buildings AS b
			JOIN INSERTED i	ON 
				b.id = i.id
		END

	IF EXISTS (SELECT
				i.id, i.sector_id
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id, d.sector_id
			FROM DELETED d)
	BEGIN
		-- RAISERROR('надо сменить номер участка для  всех лицевых в этом доме',10,1) WITH NOWAIT 
		UPDATE dbo.Occupations
		SET jeu	  = b.sector_id
		   ,schtl = NULL
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f ON 
			o.flat_id = f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id = b.id
		JOIN INSERTED AS i ON 
			b.id = i.id
		WHERE 
			o.status_id <> 'закр'
			AND o.jeu <> b.sector_id
	END 

	IF EXISTS (SELECT
				i.id, i.tip_id
			FROM INSERTED i			
			EXCEPT
			SELECT
				d.id, d.tip_id
			FROM DELETED d)
	BEGIN
		--RAISERROR('смена типа жилого фонда  для  всех лицевых в этом доме',10,1) WITH NOWAIT
		UPDATE o
		SET tip_id = b.tip_id
		   ,jeu	   = b.sector_id
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f ON 
			o.flat_id = f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id = b.id
		JOIN DELETED AS i ON 
			b.id = i.id
		WHERE 
			o.status_id <> 'закр'
			AND o.tip_id <> b.tip_id

		UPDATE b
		SET fin_current = ot.fin_id
		FROM dbo.Buildings AS b
		JOIN DELETED AS i ON 
			b.id = i.id
		JOIN dbo.Occupation_Types AS ot	ON 
			i.tip_id = ot.id
		WHERE 
			b.fin_current <> ot.fin_id
			AND b.is_finperiod_owner=0

	END --if update(tip_id)

END
go

