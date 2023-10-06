-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Расчёт коэффициента при изменении параметров дома
-- =============================================
CREATE   TRIGGER [dbo].[KOEF_BUILD_RASCHET] 
   ON  [dbo].[Koef_build]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @id1 INT
	SELECT @id1=build_id FROM INSERTED

    EXEC adm_koef_build @id1, 0
	
END
go

