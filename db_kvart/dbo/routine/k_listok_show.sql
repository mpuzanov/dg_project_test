CREATE   PROCEDURE [dbo].[k_listok_show]
( @id1 int
)
AS
/*

Показываем информацию для формирования листка прибытия

*/
SET NOCOUNT ON

SELECT pl.* 
FROM dbo.People_listok as pl 
WHERE id=@id1
go

