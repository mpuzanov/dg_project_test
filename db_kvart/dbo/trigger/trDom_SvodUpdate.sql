-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trDom_SvodUpdate]
   ON [Dom_svod]
   AFTER INSERT,DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET 
		CountFlatsNoIPU = case when (i.[CountFlats]-i.[CountFlatsIPU]<0) then 0 else i.[CountFlats]-i.[CountFlatsIPU] end
		,CountPeopleNoIPU = case when (i.[CountPeople]-i.[CountPeopleIPU]<0) then 0 else i.[CountPeople]-i.[CountPeopleIPU] end
	FROM INSERTED AS i
	JOIN Dom_svod AS t ON 
		t.fin_id = i.fin_id
		AND t.build_id = i.build_id

END
go

