CREATE   PROCEDURE [dbo].[adm_change_schtl_vibor]
(
	@jeu1   SMALLINT
   ,@schtl1 INT
   ,@schtl2 INT
)
AS
	SET NOCOUNT ON

	SELECT
		JEU
	   ,SCHTL
	FROM dbo.Occupations
		WHERE JEU = @jeu1
		AND SCHTL BETWEEN @schtl1 AND @schtl2
go

