CREATE   PROCEDURE [dbo].[rep_preview_show]
( @rep_id INT
)
AS
--
--  Просмотр примера отчёта
--
SET NOCOUNT ON

SELECT
	ID,
	report_preview
FROM dbo.REPORTS 
WHERE id=@rep_id
go

