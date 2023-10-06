CREATE   PROCEDURE [dbo].[k_showmodes]
( 
	@service_id1 VARCHAR(10)
	,@is_mode_show BIT = 0
)
 AS
SET NOCOUNT ON

SET @is_mode_show=COALESCE(@is_mode_show,0)

IF @is_mode_show=0
	SELECT id, name, comments, unit_id, 0 AS count_build
	FROM dbo.cons_modes cm
	WHERE service_id=@service_id1
ELSE
	SELECT id, name, comments, unit_id, 
	coalesce(t.kol,0) AS count_build
	FROM dbo.cons_modes cm
	LEFT JOIN (SELECT CL.mode_id, COUNT(DISTINCT f.bldn_id) AS kol
		FROM dbo.Consmodes_list AS CL 
		JOIN dbo.Occupations AS O ON CL.Occ = O.Occ 
		JOIN dbo.Flats AS F ON O.flat_id = F.id 
		WHERE CL.service_id = @service_id1		
		GROUP BY CL.mode_id) AS t 
		ON cm.id=t.mode_id AND (cm.id % 1000 <> 0)
	WHERE service_id=@service_id1

go

