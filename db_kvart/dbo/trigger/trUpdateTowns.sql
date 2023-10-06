-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trUpdateTowns]
   ON  [dbo].[Towns]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET 
		full_name=concat(coalesce(i.[prefix],''), i.[NAME])
		,full_name_region = case 
			when i.[region_short] IS NOT NULL 
			then concat(i.[region_short],', ',coalesce(i.[prefix],''), i.[NAME]) 
			else concat(coalesce(i.[prefix],''), i.[NAME]) 
		end
	FROM Towns as t
	JOIN INSERTED as i ON
		t.id = i.id

END
go

