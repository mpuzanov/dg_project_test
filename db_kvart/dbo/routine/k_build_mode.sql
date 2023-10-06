CREATE   PROCEDURE [dbo].[k_build_mode]
(
	@build_id1 INT
)
AS
	--
	--  Вывести все режимы потребления по дому
	--
	SET NOCOUNT ON

	SELECT
		b.service_id
	   ,b.mode_id AS id
	   ,cm.Name
	FROM dbo.BUILD_MODE AS b
	JOIN dbo.CONS_MODES AS cm 
		ON cm.id = b.mode_id
		AND cm.service_id = b.service_id
	WHERE b.build_id = @build_id1
go

