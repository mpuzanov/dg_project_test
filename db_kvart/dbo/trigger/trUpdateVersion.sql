-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trUpdateVersion]
   ON [dbo].[Version]
   AFTER INSERT, UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;

    UPDATE V
	SET 
		versiastr = concat(i.[Major],'.',i.[Minor],'.',i.[Release],'.',i.[Build])
		,versiaint = ((i.[Major]*(100000000)+i.[Minor]*(1000000))+i.[Release]*(1000))+i.[Build]
		,versiastr_min = concat(i.[Major_min],'.',i.[Minor_min],'.',i.[Release_min],'.',i.[Build_min])
		,versiaint_min = ((i.[Major_min]*(100000000)+i.[Minor_min]*(1000000))+i.[Release_min]*(1000))+i.[Build_min]
	FROM dbo.[Version] as v
	JOIN INSERTED as i ON
		i.program_name=v.program_name

END
go

