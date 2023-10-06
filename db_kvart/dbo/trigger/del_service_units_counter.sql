-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[del_service_units_counter]
   ON  [dbo].[Service_units_counter]
   FOR DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @unit_id VARCHAR(10)
	SELECT @unit_id=d.unit_id FROM deleted AS d

IF EXISTS (SELECT * FROM [dbo].[MEASUREMENT_UNITS] WHERE unit_id=@unit_id AND is_counter=1
AND (q_single<>0 OR two_single<>0 OR three_single<>0 OR four_single<>0 OR q_member<>0))
BEGIN
  ROLLBACK TRAN
  DECLARE @msg VARCHAR(200)
  SELECT @msg='Ед.измерения '+LTRIM(@unit_id)+' удалить нельзя! Т.к. по ней есть заполненные нормы потребления'
  RAISERROR(@msg,16,10)
END

END
go

