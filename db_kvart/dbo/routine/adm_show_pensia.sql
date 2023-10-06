CREATE   PROCEDURE [dbo].[adm_show_pensia]
(
	@fin_id1   SMALLINT = NULL
   ,@organ_id1 SMALLINT = NULL
)
AS
	--
	--  Показываем список пенсионеров по текущему фин. периоду
	--
	SET NOCOUNT ON

	IF @fin_id1 IS NULL
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	SELECT
		ID
	   ,FIN_ID
	   ,ORGAN_ID
	   ,FAMILY
	   ,NAME
	   ,FATHER
	   ,D_ROGD
	   ,NAI_PEN
	   ,OSNOVAN
	   ,PUNKT
	   ,STREET
	   ,HOUSE
	   ,KORP
	   ,FLAT
	   ,RAION
	   ,RAB
	   ,SUM1
	   ,SUM2
	   ,SUM3
	   ,SUM4
	   ,SUM5
	   ,SUM6
	   ,ITOGO
	FROM dbo.PENSIA 
	WHERE FIN_ID = @fin_id1
	AND ORGAN_ID = @organ_id1
go

