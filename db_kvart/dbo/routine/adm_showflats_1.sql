CREATE   PROCEDURE [dbo].[adm_showflats_1]
(
	  @bldn_id1 INT
)
AS
/*
exec adm_showflats_1 1039
*/

	SET NOCOUNT ON

	SELECT F.*
		 , t_occ.Occ AS Count_occ
		 , t_occ.total_sq AS total_sq
		 , t_occ.kol_people AS kol_people
		 , CASE
               WHEN t_rooms.kol_rooms > 0 THEN t_rooms.kol_rooms
               ELSE NULL
        END AS kol_rooms
	FROM dbo.Flats AS F
		OUTER APPLY (
			SELECT 
				COUNT(O.OCC) AS OCC
				, SUM(O.TOTAL_SQ) AS TOTAL_SQ
				, SUM(O.kol_people) AS kol_people
			FROM dbo.Occupations AS O 
			WHERE flat_id = F.id
				AND O.STATUS_ID <> 'закр'
				--AND O.TOTAL_SQ > 0
		) AS t_occ
		OUTER APPLY (
			SELECT 
				COUNT(*) AS kol_rooms
			FROM dbo.Rooms r 
			WHERE r.flat_id = F.id
		) AS t_rooms
	WHERE 
		bldn_id = @bldn_id1
	ORDER BY F.nom_kvr_sort
go

