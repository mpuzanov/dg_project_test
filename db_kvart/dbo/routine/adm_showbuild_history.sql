-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_showbuild_history]
(
	@bldn_id INT
)
AS
BEGIN
/*
adm_showbuild_history 6804
*/
SET NOCOUNT ON;

SELECT cp.StrFinPeriod AS fin_name
	 , bh.*
	 , t.name AS tip_name
	 , sec.name AS sector_name
FROM dbo.Buildings_history AS bh 
	JOIN dbo.Occupation_Types AS t 
		ON bh.tip_id = t.id
	LEFT JOIN dbo.Sector AS sec 
		ON bh.sector_id = sec.id
	JOIN dbo.Calendar_period cp ON bh.fin_id = cp.fin_id
WHERE bldn_id = @bldn_id
ORDER BY fin_id DESC

END
go

