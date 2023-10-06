-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[rep_intPrint_akt]
(
	@fin_id			SMALLINT
   ,@tip_id			SMALLINT	  = NULL	-- жилой фонд
   ,@ops			INT			  = NULL -- ОПС
   ,@sum_dolg		DECIMAL(9, 2) = 0 -- если не равно 0 вывод только с долгом более этой суммы
   ,@group_id		INT			  = NULL
   ,@people0_block  BIT			  = 0
   ,@sup_id			INT			  = NULL
   ,@paidAll0_block BIT			  = 0 -- блокировать печать где нет начислений
   ,@PROPTYPE_STR   VARCHAR(10)	  = NULL -- строка с разрешёнными к печати типами собственности
   ,@debug BIT = 0
)
AS
/*
Используется в отчёте:
Акт приема-передачи квитанций по ОПС

exec rep_intPrint_akt @fin_id=195,@PROPTYPE_STR='',@paidAll0_block=1
*/
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #t;
	DROP TABLE IF EXISTS #t;

	IF @sup_id IS NULL
	BEGIN
		SELECT
			o.occ
		   ,o.flat_id
		   ,COALESCE(o.kol_people, 0) AS kol_people
		   ,o.PROPTYPE_ID
		   ,(o.paid+o.Paid_minus) AS paidAll
		INTO #t
		FROM dbo.View_occ_all_lite AS o 
		JOIN dbo.INTPRINT AS i 
			ON o.occ = i.occ AND i.fin_id = o.fin_id
		WHERE o.STATUS_ID <> 'закр'
		AND o.TOTAL_SQ > 0
		AND NOT EXISTS (SELECT
				*
			FROM dbo.OCC_NOT_print AS onp 
			WHERE onp.occ = o.occ)
		AND i.fin_id = @fin_id
		AND i.SumPaym > COALESCE(@sum_dolg, -99999)
		AND (@group_id IS NULL
		OR (@group_id IS NOT NULL
		AND EXISTS (SELECT
				*
			FROM dbo.PRINT_OCC AS po 
			WHERE po.occ = o.occ
			AND po.group_id = @group_id)
		))
		--******************************************************
		IF @debug=1
			SELECT * FROM #t

		IF @people0_block = 1
			DELETE FROM #t
			WHERE kol_people = 0

		-- Убираем печать где нет начислений
		IF @paidAll0_block = 1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll = 0

		-- Убираем печать где тип собственности не тот
		IF COALESCE(@PROPTYPE_STR, '') <> ''
			DELETE t
				FROM #t AS t
			WHERE NOT EXISTS (SELECT
						1
					FROM STRING_SPLIT(@PROPTYPE_STR, ',')
					WHERE RTRIM(value) <> ''
					AND value = t.PROPTYPE_ID)
		--******************************************************
		SELECT
			t.*
		   ,SUM(t.kolocc) OVER () AS kolocc_itogo
		FROM (SELECT
				s.name
			   ,b.nom_dom
			   ,b.index_id
			   ,b.sector_id
			   ,ops.name AS ops
			   ,d.name AS 'div_name'
			   ,COUNT(o.occ) AS kolocc
			   ,MAX(b.nom_dom_sort) as nom_dom_sort
			FROM dbo.ops 
			JOIN dbo.BUILDINGS AS b 
				ON ops.id = b.index_id
			JOIN dbo.VSTREETS AS s 
				ON b.street_id = s.id
			JOIN dbo.FLATS AS f
				ON b.id = f.bldn_id
			JOIN #t AS o
				ON f.id = o.flat_id
			JOIN dbo.DIVISIONS AS d 
				ON b.div_id = d.id
			WHERE b.index_id <> 1
			AND (b.index_id = @ops
			OR @ops IS NULL)
			AND (b.tip_id = @tip_id
			OR @tip_id IS NULL)
			GROUP BY s.name
					,b.nom_dom
					,b.index_id
					,b.sector_id
					,ops.name
					,d.name) AS t
		ORDER BY t.index_id, t.name, nom_dom_sort
	END
	ELSE
	BEGIN  -- по поставщику
		SELECT
			o.occ
		   ,o.flat_id
		   ,COALESCE(o.kol_people, 0) AS kol_people
		   ,o.PROPTYPE_ID
		   ,i.paid AS paidAll
		INTO #t2
		FROM dbo.Occupations AS o 
		JOIN dbo.VOcc_Suppliers AS i 
			ON o.occ = i.occ
		WHERE 
			o.STATUS_ID <> 'закр'
			AND o.TOTAL_SQ > 0
			AND NOT EXISTS (SELECT 1 FROM dbo.OCC_NOT_print AS onp  WHERE onp.occ=o.occ)
			AND i.fin_id = @fin_id
			AND i.Whole_payment > COALESCE(@sum_dolg, -99999)
			AND (@group_id IS NULL
			OR (@group_id IS NOT NULL
			AND EXISTS (SELECT
					*
				FROM dbo.PRINT_OCC AS po 
				WHERE po.occ = o.occ
				AND po.group_id = @group_id)
			))
			AND (i.sup_id = @sup_id OR @sup_id is null)

		--******************************************************
		IF @people0_block = 1
			DELETE FROM #t
			WHERE kol_people = 0

		-- Убираем печать где нет начислений
		IF @paidAll0_block = 1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll = 0

		-- Убираем печать где тип собственности не тот
		IF COALESCE(@PROPTYPE_STR, '') <> ''
			DELETE t
				FROM #t AS t
			WHERE NOT EXISTS (SELECT
						1
					FROM STRING_SPLIT(@PROPTYPE_STR, ',')
					WHERE RTRIM(value) <> ''
					AND value = t.PROPTYPE_ID)
		--******************************************************
		SELECT
			s.name
		   ,b.nom_dom
		   ,b.index_id
		   ,b.sector_id
		   ,ops.name AS ops
		   ,d.name AS 'div_name'
		   ,COUNT(o.occ) AS kolocc
		   ,MAX(b.nom_dom_sort) as nom_dom_sort
		FROM dbo.ops 
		JOIN dbo.BUILDINGS AS b 
			ON ops.id = b.index_id
		JOIN dbo.VSTREETS AS s
			ON b.street_id = s.id
		JOIN dbo.FLATS AS f 
			ON b.id = f.bldn_id
		JOIN #t2 AS o
			ON f.id = o.flat_id
		JOIN dbo.DIVISIONS AS d 
			ON b.div_id = d.id
		WHERE b.index_id <> 1
		AND (b.index_id = @ops  OR @ops IS NULL)
		AND (b.tip_id = @tip_id OR @tip_id IS NULL)
		GROUP BY s.name
				,b.nom_dom
				,b.index_id
				,b.sector_id
				,ops.name
				,d.name
		ORDER BY b.index_id
		, s.name
		, nom_dom_sort
	END

END
go

