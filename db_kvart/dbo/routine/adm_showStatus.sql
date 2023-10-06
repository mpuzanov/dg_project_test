CREATE   PROCEDURE [dbo].[adm_showStatus]
AS
/*
  Статусы прописок
*/
SET NOCOUNT ON
SELECT
	*
FROM dbo.STATUS
go

