CREATE   PROCEDURE [dbo].[k_source_all] AS
/*
  Список поставщиков
*/
SET NOCOUNT ON
 
SELECT * 
FROM View_SUPPLIERS
go

