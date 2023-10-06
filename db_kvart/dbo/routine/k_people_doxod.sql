CREATE   PROCEDURE [dbo].[k_people_doxod]
(
	@occ1 INT
)
AS
	--
	--  Общий доход по лицевому
	--
	SET NOCOUNT ON

	SELECT
		sumdoxod = SUM(doxod)
	FROM dbo.PEOPLE AS p
	WHERE occ = @occ1
	AND DateDel IS NULL
go

