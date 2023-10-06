-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trStreetsInsert]
   ON [Streets]
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET full_name = CONCAT(rtrim(i.[Name]), 
						CASE WHEN coalesce(i.[prefix],'')<>'' THEN CONCAT(' ',i.[prefix],'.') ELSE '' END)
		, full_name2 = CONCAT(
					   CASE 
						WHEN coalesce(i.[prefix],'')<>'' THEN CONCAT(i.[prefix],'. ')
						ELSE '' 
					   END, rtrim(i.[Name]) )
	FROM INSERTED i
		JOIN Streets AS t ON 
			t.id = i.id

END
go

