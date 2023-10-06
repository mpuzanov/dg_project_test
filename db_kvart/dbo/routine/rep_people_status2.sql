-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_people_status2]
(
	@fin_id1 SMALLINT
   ,@tip_id1 SMALLINT
   ,@build1	 INT = NULL
)
AS
/*
rep_people_status2 @fin_id1=195, @tip_id1=null
*/
BEGIN
	SET NOCOUNT ON;


	IF @tip_id1 IS NULL
		AND @build1 IS NOT NULL
		SELECT
			@tip_id1 = tip_id
		FROM View_BUILD_ALL_LITE vbal
		WHERE vbal.fin_id = @fin_id1
		AND vbal.bldn_id = @build1

	SELECT
		ps.name
	   ,COUNT(p.owner_id) AS kol
	FROM dbo.View_OCC_ALL AS o
	JOIN dbo.View_PEOPLE_ALL AS p
		ON o.Occ = p.Occ
		AND o.fin_id = p.fin_id
	JOIN dbo.PERSON_STATUSES AS ps
		ON p.status2_id = ps.id
	WHERE o.fin_id = @fin_id1
	AND (o.tip_id = @tip_id1
	OR @tip_id1 IS NULL)
	AND (o.bldn_id = @build1
	OR @build1 IS NULL)
	GROUP BY ps.name
	ORDER BY kol DESC
END
go

