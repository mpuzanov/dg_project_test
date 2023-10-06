CREATE   PROCEDURE [dbo].[rep_preview_add]
( @rep_id INT,
  @report_preview IMAGE
)
AS
/*  
	Добавляем или изменяем пример отчёта 
*/
SET NOCOUNT ON

UPDATE dbo.REPORTS 
SET report_preview=@report_preview
WHERE id=@rep_id
go

