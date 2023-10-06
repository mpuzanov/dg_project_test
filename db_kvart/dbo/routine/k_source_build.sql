CREATE   PROCEDURE [dbo].[k_source_build]
(
	@bldn_id1		INT
	,@service_id1	VARCHAR(10)
	,@source_new	INT
)
AS
/*
  Установка поставщика по дому по заданной услуге
*/
SET NOCOUNT ON

UPDATE c1
SET source_id = @source_new
FROM dbo.CONSMODES_LIST AS c1
	JOIN dbo.OCCUPATIONS AS o
		ON c1.Occ = o.Occ
	JOIN dbo.FLATS AS f
		ON o.flat_id = f.id
WHERE f.bldn_id = @bldn_id1
	AND c1.service_id = @service_id1
go

