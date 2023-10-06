CREATE   PROCEDURE [dbo].[adm_dsc_groups] AS
/*
 Список льгот в базе
*/
SET NOCOUNT ON

SELECT * 
FROM dbo.dsc_groups
ORDER BY id
go

