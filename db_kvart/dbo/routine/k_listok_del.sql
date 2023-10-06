CREATE   PROCEDURE [dbo].[k_listok_del]
( @id1 int
)
AS
/*

Удаляем листок прибытия или убытия

*/
SET NOCOUNT ON

--
DELETE FROM dbo.People_listok
where id=@id1
go

