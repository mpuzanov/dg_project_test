CREATE   PROCEDURE [dbo].[adm_build_source_serv2]
(
	@build_id1	 INT
   ,@service_id1 VARCHAR(10)
)
AS
/*
	Вывести всех  поставщиков которых нет заданному по дому и по заданной услуге
*/
SET NOCOUNT ON

SELECT
	id
	,name
FROM dbo.View_suppliers
WHERE service_id = @service_id1
ORDER BY id;
go

