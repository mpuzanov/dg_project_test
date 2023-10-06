-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAreaBuild]
(
	  @build_id INT
	, @fin_id SMALLINT
)
/* 
select * from Fun_GetAreaBuild(6795, 235)

Общ.площадь помещений МКД,м2: 12906.00,в т.ч.жилая площадь,м2: 11762.20,офисов,м2: 622.70,кладовых,м2: 50.40,машиномест,м2: 334.60,гаражных боксов,м2: 135.40,Общ.площадь нежилых пом.,м2: 1143.10,Площадь МОП для ГВ и ХВ,м2: 2910.10,Площадь МОП по эл.эн.,м2: 3767.70

*/

RETURNS TABLE
AS
	RETURN
	(
	SELECT t.*
		 , CONCAT(CASE
			   WHEN ot.soi_isTotalSq_Pasport = 1 AND
				   t.build_total_area > 0 THEN CONCAT('Общ.площадь помещений МКД,м2: ' , t.build_total_area)
			   WHEN t.build_total_sq > 0 THEN CONCAT('Общ.площадь помещений МКД,м2: ' , t.build_total_sq)
			   ELSE ''
		   END
		 , CASE
                WHEN t.[Жилая] > 0 AND t.[Жилая] <> t.Total_sq
                    THEN CONCAT(',в т.ч.жилая площадь,м2: ' , t.[Жилая])
                ELSE ''
                END
		 , CASE
                WHEN t.[Офис] > 0 THEN CONCAT(',офисов,м2: ' , t.[Офис])
                ELSE ''
                END
		 , CASE
                WHEN t.[Кладовая] > 0 THEN CONCAT(',кладовых,м2: ' , t.[Кладовая])
                ELSE ''
                END
		 , CASE
                WHEN t.[Колясочная] > 0 THEN CONCAT(',колясочных,м2: ' , t.[Колясочная])
                ELSE ''
                END
		  , CASE
                WHEN t.[Паркинг] > 0 THEN CONCAT(',машиномест,м2: ' , t.[Паркинг])
                ELSE ''
                END
		  , CASE
                WHEN t.[Гаражный бокс] > 0 THEN CONCAT(',гаражных боксов,м2: ' , t.[Гаражный бокс])
                ELSE ''
                END
		  , CASE
                WHEN t.arenda_sq > 6 THEN CONCAT(',Общ.площадь нежилых пом.,м2: ' , t.arenda_sq)
                ELSE ''
                END
		  , CASE
                WHEN t.opu_sq > 0 THEN CONCAT(',Площадь МОП для ГВ и ХВ,м2: ' , t.opu_sq)
                ELSE ''
                END
		  , CASE
                WHEN t.opu_sq_elek > 0 THEN CONCAT(',Площадь МОП по эл.эн.,м2: ' , t.opu_sq_elek)
                ELSE ''
                END
		   ) AS SquareBuild_str
	FROM (
		SELECT b.build_id                                           AS build_id
			 , MAX(b.tip_id)                                        AS tip_id
			 , MAX(b.build_total_sq)                                AS build_total_sq
			 , MAX(b.build_total_area)                              AS build_total_area
			 , MAX(b.arenda_sq)                                     AS arenda_sq
			 , MAX(b.opu_sq)                                        AS opu_sq
			 , MAX(b.opu_sq_elek)                                   AS opu_sq_elek
			 , MAX(b.opu_sq_otop)                                   AS opu_sq_otop
			 , SUM(o.Total_sq)                                      AS Total_sq
			 , COALESCE(SUM(CASE WHEN rt.id IN ('комм', 'об06', 'об10', 'отдк') THEN o.Total_sq ELSE 0 END), 0) AS [Жилая]
			 , COALESCE(SUM(CASE WHEN rt.id = 'офис' THEN o.Total_sq ELSE 0 END), 0) AS [Офис]			 
			 , COALESCE(SUM(CASE WHEN rt.id = 'парк' THEN o.Total_sq ELSE 0 END), 0) AS [Паркинг]
			 , COALESCE(SUM(CASE WHEN rt.id = 'бокс' THEN o.Total_sq ELSE 0 END), 0) AS [Гаражный бокс]
			 , COALESCE(SUM(CASE WHEN rt.id = 'клад' THEN o.Total_sq ELSE 0 END), 0) AS [Кладовая]
			 , COALESCE(SUM(CASE WHEN rt.id = 'коля' THEN o.Total_sq ELSE 0 END), 0) AS [Колясочная]
		FROM dbo.View_build_all_lite AS b 
			LEFT JOIN dbo.View_occ_all_lite AS o ON 
				b.build_id = o.build_id
				AND b.fin_id = o.fin_id
				AND o.status_id <> 'закр'
				AND o.total_sq > 0
			LEFT JOIN dbo.Room_types rt ON 
				o.roomtype_id = rt.id
		WHERE (b.build_id = @build_id)
			AND b.fin_id = @fin_id
		GROUP BY b.build_id
	) AS t
		JOIN dbo.Occupation_Types AS ot ON 
			t.tip_id = ot.id
	)
go

