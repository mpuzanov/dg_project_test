CREATE   PROCEDURE [dbo].[k_show_typehistory] AS

SET NOCOUNT ON

SELECT id, name, is_param, sort_no, is_visible 
FROM dbo.TYPE_HISTORY 
WHERE is_visible=1
ORDER BY sort_no
go

