-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       TRIGGER [dbo].[tr_add_added_payments]
	ON [dbo].[Added_Payments]
	AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap
	SET fin_id = b.fin_current
	FROM INSERTED AS i
		JOIN dbo.Added_Payments AS ap ON 
			ap.id = i.id
		JOIN dbo.Occupations AS o ON 
			i.occ = o.occ
		JOIN dbo.Flats AS f ON 
			o.flat_id=f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id=b.id
	WHERE ap.fin_id IS NULL

	UPDATE ap
	SET date_edit=CURRENT_TIMESTAMP
	FROM INSERTED AS i
		JOIN dbo.Added_Payments AS ap ON 
			ap.id = i.id

	--UPDATE ap
	--SET sup_id = cl.sup_id
	--FROM INSERTED AS i 
	--	JOIN dbo.Added_Payments AS ap ON 
	--		ap.id = i.id
	--	JOIN dbo.Consmodes_list cl ON 
	--		ap.occ = cl.occ
	--		AND ap.service_id = cl.service_id
	--WHERE ap.sup_id = 0
	--	AND ap.sup_id <> cl.sup_id

END
go

