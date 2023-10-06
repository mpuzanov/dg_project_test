CREATE   PROCEDURE [dbo].[adm_del_pensia]
(
	@organ_id SMALLINT
)
AS

	--
	--  Удаляем информацию по пенсионерам в текущем фин.периоде
	--
	SET NOCOUNT ON

	DECLARE @fin_id1 SMALLINT

	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DELETE FROM dbo.PENSIA
	WHERE fin_id = @fin_id1
		AND organ_id = @organ_id

	SET @fin_id1 = @fin_id1 - 2
	DELETE FROM dbo.PENSIA
	WHERE fin_id < @fin_id1
		AND organ_id = @organ_id
go

