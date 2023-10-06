CREATE   PROCEDURE [dbo].[k_build_source]
(
	@build_id1 INT
)
AS
	--
	-- Вывести всех поставщиков по дому
	--
	SET NOCOUNT ON

	SELECT
		b.service_id
	   ,b.source_id AS id
	   ,cm.Name
	FROM dbo.BUILD_SOURCE AS b 
	JOIN dbo.View_SUPPLIERS AS cm 
		ON cm.id = b.source_id
		AND cm.service_id = b.service_id
	WHERE b.build_id = @build_id1
go

